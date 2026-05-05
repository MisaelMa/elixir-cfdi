defmodule Sat.Catalogos.Codegen do
  @moduledoc """
  Orquestador del pipeline de codegen para sat_catalogos.

  Genera los módulos de catálogos del SAT a partir de catCFDI.xsd y catCFDI.xlsx.

  ## Opciones

    * `:xsd_path` — ruta al XSD (default: `packages/files/4.0/catCFDI.xsd`)
    * `:xlsx_path` — ruta al XLSX (default: `packages/files/4.0/catCFDI.xlsx`)
    * `:output_dir` — directorio de salida (default: `packages/sat/catalogos/lib/sat/catalogos`)
    * `:overrides_dir` — directorio de overrides (default: `priv/overrides` del paquete)
    * `:skip_download` — si `true`, falla si el XLSX no existe en lugar de descargarlo (default: `true`)
    * `:specs` — lista de `Catalogs.Spec.t()` a generar; si es `nil` usa `Catalogs.specs/0`
    * `:sat_resources` — `Sat.Recursos.SatResources.t()` para descargar el XLSX si `skip_download: false`

  """

  alias Sat.Catalogos.Codegen.Catalogs
  alias Sat.Catalogos.Codegen.CrossValidator
  alias Sat.Catalogos.Codegen.Overrides
  alias Sat.Catalogos.Codegen.Parsers.Xlsx
  alias Sat.Catalogos.Codegen.Parsers.Xsd

  @type opts :: [
          xsd_path: Path.t(),
          xlsx_path: Path.t(),
          output_dir: Path.t(),
          overrides_dir: Path.t(),
          skip_download: boolean(),
          specs: [Catalogs.Spec.t()] | nil,
          sat_resources: term() | nil
        ]

  @default_xsd_path "packages/files/4.0/catCFDI.xsd"
  @default_xlsx_path "packages/files/4.0/catCFDI.xlsx"
  @default_output_dir "packages/sat/catalogos/lib/sat/catalogos"

  @spec generate(opts()) :: {:ok, [Path.t()]} | {:error, term()}
  def generate(opts \\ []) do
    xsd_path = Keyword.get(opts, :xsd_path, @default_xsd_path)
    xlsx_path = Keyword.get(opts, :xlsx_path, @default_xlsx_path)
    output_dir = Keyword.get(opts, :output_dir, @default_output_dir)
    overrides_dir = Keyword.get(opts, :overrides_dir, default_overrides_dir())
    skip_download = Keyword.get(opts, :skip_download, true)
    specs = Keyword.get(opts, :specs, nil) || Catalogs.specs()
    sat_resources = Keyword.get(opts, :sat_resources, nil)

    with :ok <- verify_xsd(xsd_path),
         :ok <- verify_xlsx(xlsx_path, skip_download, sat_resources),
         {:ok, xsd_map} <- Xsd.parse(xsd_path),
         :ok <- File.mkdir_p(output_dir),
         {:ok, paths} <- generate_specs(specs, xsd_map, xlsx_path, output_dir, overrides_dir) do
      {:ok, paths}
    end
  end

  # ─── Private helpers ─────────────────────────────────────────────────────────

  defp default_overrides_dir do
    :code.priv_dir(:sat_catalogos_codegen)
    |> List.to_string()
    |> Path.join("overrides")
  end

  defp verify_xsd(path) do
    if File.exists?(path) do
      :ok
    else
      {:error, {:missing_xsd, path}}
    end
  end

  defp verify_xlsx(path, skip_download, sat_resources) do
    if File.exists?(path) do
      :ok
    else
      if skip_download do
        {:error, {:missing_xlsx, path}}
      else
        download_xlsx(path, sat_resources)
      end
    end
  end

  defp download_xlsx(_path, nil) do
    {:error, {:missing_xlsx_no_resources, "skip_download: false but no sat_resources provided"}}
  end

  defp download_xlsx(_path, sat_resources) do
    case Sat.Recursos.SatResources.download_xlsx(sat_resources) do
      {:ok, _dest} -> :ok
      {:error, _} = err -> err
    end
  end

  defp generate_specs(specs, xsd_map, xlsx_path, output_dir, overrides_dir) do
    results =
      Enum.reduce_while(specs, {:ok, []}, fn spec, {:ok, acc} ->
        case generate_one(spec, xsd_map, xlsx_path, output_dir, overrides_dir) do
          {:ok, path} -> {:cont, {:ok, [path | acc]}}
          :skip -> {:cont, {:ok, acc}}
          {:error, _} = err -> {:halt, err}
        end
      end)

    case results do
      {:ok, paths} -> {:ok, Enum.reverse(paths)}
      {:error, _} = err -> err
    end
  end

  defp generate_one(spec, xsd_map, xlsx_path, output_dir, overrides_dir) do
    # Skip specs whose simpletype is not in the XSD at all
    if not Map.has_key?(xsd_map, spec.simpletype) do
      :skip
    else
      do_generate_one(spec, xsd_map, xlsx_path, output_dir, overrides_dir)
    end
  end

  defp do_generate_one(spec, xsd_map, xlsx_path, output_dir, overrides_dir) do
    xsd_codes = Map.fetch!(xsd_map, spec.simpletype)
    sheet_name = spec.sheet_name || spec.simpletype

    with {:ok, raw_rows} <- Xlsx.read_sheet(xlsx_path, sheet_name),
         xlsx_rows = parse_xlsx_rows(raw_rows, spec),
         {:ok, overrides} <- load_overrides(spec, overrides_dir),
         {:ok, entries} <-
           CrossValidator.reconcile(xsd_codes, xlsx_rows, overrides,
             emit_atoms: spec.variant == :with_atoms
           ),
         entries_with_atoms = maybe_inject_atoms(entries, overrides, spec),
         {:ok, source} <-
           Sat.Catalogos.Codegen.Renderer.render(%{spec: spec, entries: entries_with_atoms}) do
      dest = Path.join(output_dir, spec.file_name)

      case File.write(dest, source) do
        :ok -> {:ok, dest}
        {:error, reason} -> {:error, {:write_error, dest, reason}}
      end
    end
  end

  # Convert raw XLSX rows (list of lists) into structured maps for CrossValidator.
  #
  # Auto-detect approach: find the row where column A equals spec.simpletype,
  # then treat all rows AFTER it as data. This handles:
  #   - tiny.xlsx fixture (simpletype at row 0, data at row 2+)
  #   - Real SAT XLSX (4 header rows: title, metadata cols, metadata values, simpletype row)
  #   - RegimenFiscal (5 header rows — extra merged header before simpletype row)
  #
  # After finding data rows, filter out rows where col A is nil or empty (sub-headers
  # that lack a code). For rows like c_UsoCFDI's ["Física","Moral"] sub-header, the
  # CrossValidator will reject them via {:xlsx_code_not_in_xsd, _} if col A is non-nil.
  # To avoid that, we additionally filter out rows whose (normalized) first cell is not
  # purely alphanumeric (SAT codes are always alphanumeric only).
  defp parse_xlsx_rows(raw_rows, spec) do
    simpletype = spec.simpletype
    pad = spec.code_pad_start

    # Find the index of the row where col A equals the simpletype name
    header_index =
      Enum.find_index(raw_rows, fn row ->
        Enum.at(row, 0) == simpletype
      end)

    if is_nil(header_index) do
      # No simpletype header found — return empty list (CrossValidator handles it)
      []
    else
      # Take all rows AFTER the simpletype header row
      data_rows = Enum.drop(raw_rows, header_index + 1)

      extra_keys = Keyword.keys(spec.extra_columns)

      data_rows
      |> Enum.reject(fn row ->
        # Reject rows where col A is nil, empty, or non-alphanumeric (sub-headers)
        first_cell = Enum.at(row, 0)

        is_nil(first_cell) or first_cell == "" or
          not Regex.match?(~r/\A[A-Za-z0-9]+\z/, first_cell)
      end)
      |> Enum.map(fn row ->
        raw_code = Enum.at(row, 0) || ""
        code = normalize_code(raw_code, pad)

        raw_label = Enum.at(row, spec.label_column)

        # Only accept binary values as labels. Non-binaries (e.g. date serials,
        # integers) that happen to sit in the label column are treated as absent.
        label =
          if is_binary(raw_label) do
            raw_label
          else
            ""
          end

        base = %{code: code, label: label}

        # Inject extra columns by index (1-based per spec, but row is 0-based)
        extras =
          Enum.reduce(extra_keys, %{}, fn key, acc ->
            col_index = Keyword.get(spec.extra_columns, key)
            raw_val = Enum.at(row, col_index - 1)
            Map.put(acc, key, parse_extra_value(key, raw_val))
          end)

        Map.merge(base, extras)
      end)
    end
  end

  @doc false
  # Normalize a code value by zero-padding if it's a numeric-looking string and pad > 0.
  # String codes that are already padded (e.g., "01") pass through unchanged.
  # Purely alphabetic or mixed codes (e.g., "PUE", "G01") also pass through.
  @spec normalize_code(String.t() | integer() | nil, non_neg_integer()) :: String.t()
  def normalize_code(value, pad) when is_integer(value) and pad > 0 do
    value |> Integer.to_string() |> String.pad_leading(pad, "0")
  end

  def normalize_code(value, _pad) when is_integer(value) do
    Integer.to_string(value)
  end

  def normalize_code(value, pad) when is_binary(value) and pad > 0 do
    # Only pad if the string is purely numeric (all-digit)
    if Regex.match?(~r/\A\d+\z/, value) do
      String.pad_leading(value, pad, "0")
    else
      value
    end
  end

  def normalize_code(value, _pad) when is_binary(value), do: value

  def normalize_code(nil, _pad), do: ""

  def normalize_code(value, _pad), do: to_string(value)

  # Parse extra column values based on key semantics
  defp parse_extra_value(key, nil) when key in [:inicio_vigencia, :fin_vigencia], do: nil
  defp parse_extra_value(_key, nil), do: nil

  defp parse_extra_value(key, value) when key in [:inicio_vigencia, :fin_vigencia] do
    parse_date(value)
  end

  defp parse_extra_value(key, value) when key in [:persona_fisica, :persona_moral] do
    str = to_string(value) |> String.downcase() |> String.trim()

    case str do
      v when v in ["sí", "si", "s", "yes", "true", "1", "x"] -> true
      _ -> false
    end
  end

  defp parse_extra_value(_key, value), do: value

  # Parse dates from:
  #   - DD/MM/YYYY binary strings (Spanish locale)
  #   - YYYY-MM-DD binary strings (ISO 8601)
  #   - Excel serial integer (days since 1899-12-30 base, accounting for Excel's leap-year bug)
  #   - Excel serial as all-digit string (e.g., "44562")
  @doc false
  @spec parse_date(String.t() | integer() | nil) :: Date.t() | nil
  def parse_date(nil), do: nil
  def parse_date(""), do: nil

  def parse_date(serial) when is_integer(serial) do
    parse_excel_serial(serial)
  end

  def parse_date(value) when is_binary(value) do
    # Try DD/MM/YYYY first
    case Regex.run(~r/^(\d{2})\/(\d{2})\/(\d{4})$/, value) do
      [_, day, month, year] ->
        case Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day)) do
          {:ok, date} -> date
          _ -> nil
        end

      nil ->
        # Try ISO 8601 (YYYY-MM-DD)
        case Date.from_iso8601(value) do
          {:ok, date} ->
            date

          _ ->
            # Try all-digit serial number (e.g., "44562")
            case Integer.parse(value) do
              {serial, ""} -> parse_excel_serial(serial)
              _ -> nil
            end
        end
    end
  end

  def parse_date(_), do: nil

  # Excel epoch base: 1899-12-30 (accounts for Excel's "1900 is a leap year" bug
  # and the fact that serial 1 = 1900-01-01, serial 0 = 1899-12-30).
  @excel_epoch ~D[1899-12-30]
  @excel_max_serial 73050

  defp parse_excel_serial(serial) when serial > 0 and serial <= @excel_max_serial do
    Date.add(@excel_epoch, serial)
  end

  defp parse_excel_serial(_serial), do: nil

  defp load_overrides(spec, overrides_dir) do
    if spec.overrides_file do
      Overrides.load(Path.join(overrides_dir, spec.overrides_file))
    else
      {:ok, %{enum_names: %{}, descriptions: %{}}}
    end
  end

  # For :with_atoms variant, inject atom `:value` from overrides into each entry.
  # The entry currently has `value: code_string`; we replace with `value: atom`
  # and add `code: code_string`.
  defp maybe_inject_atoms(entries, overrides, %{variant: :with_atoms}) do
    Enum.map(entries, fn entry ->
      code = entry.value
      atom = Map.get(overrides.enum_names, code, String.to_atom(code))

      entry
      |> Map.put(:value, atom)
      |> Map.put(:code, code)
    end)
  end

  defp maybe_inject_atoms(entries, _overrides, _spec), do: entries
end
