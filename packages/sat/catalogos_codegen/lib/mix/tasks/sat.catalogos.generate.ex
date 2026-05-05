defmodule Mix.Tasks.Sat.Catalogos.Generate do
  use Mix.Task

  @shortdoc "Genera los módulos de catálogos del SAT desde catCFDI.xsd + catCFDI.xlsx"

  @moduledoc """
  Genera los módulos Elixir para los 15 catálogos del SAT a partir de
  `catCFDI.xsd` y `catCFDI.xlsx`.

  ## Uso

      mix sat.catalogos.generate
      mix sat.catalogos.generate --xsd path/to/catCFDI.xsd --xlsx path/to/catCFDI.xlsx
      mix sat.catalogos.generate --xlsx-url https://...catCFDI_V_4_DDMMYYYY.xls
      mix sat.catalogos.generate --force-download
      mix sat.catalogos.generate --only forma_pago,metodo_pago

  ## Opciones

    * `--xsd PATH` — ruta al XSD (default: `packages/files/4.0/catCFDI.xsd`)
    * `--xlsx PATH` — ruta al XLSX (default: `packages/files/4.0/catCFDI.xlsx`)
    * `--xlsx-url URL` — URL para descargar el XLSX si no existe (sobreescribe `SAT_XLSX_URL`)
    * `--output PATH` — directorio de salida (default: `packages/sat/catalogos/lib/sat/catalogos`)
    * `--overrides-dir PATH` — directorio de overrides (default: priv/overrides del paquete)
    * `--force-download` — descarga el XLSX incluso si ya existe localmente
    * `--only LIST` — coma-separado de file names a generar (ej. `forma_pago,metodo_pago`)
  """

  @impl Mix.Task
  def run(args) do
    # Start HTTP stack for --force-download downloads
    Application.ensure_all_started(:req)

    {opts, _rest, _invalid} =
      OptionParser.parse(args,
        strict: [
          xsd: :string,
          xlsx: :string,
          xlsx_url: :string,
          output: :string,
          overrides_dir: :string,
          force_download: :boolean,
          only: :string
        ]
      )

    xsd_path = Keyword.get(opts, :xsd, "packages/files/4.0/catCFDI.xsd")
    xlsx_path = Keyword.get(opts, :xlsx, "packages/files/4.0/catCFDI.xlsx")
    output_dir = Keyword.get(opts, :output, "packages/sat/catalogos/lib/sat/catalogos")
    overrides_dir = Keyword.get(opts, :overrides_dir, nil)
    force_download = Keyword.get(opts, :force_download, false)
    xlsx_url = Keyword.get(opts, :xlsx_url, nil)
    only_filter = Keyword.get(opts, :only, nil)

    # Build spec list (optionally filtered by --only)
    specs = filter_specs(only_filter)

    # Determine skip_download: skip if file exists AND not forcing
    skip_download = File.exists?(xlsx_path) and not force_download

    # Build codegen opts
    codegen_opts =
      [
        xsd_path: xsd_path,
        xlsx_path: xlsx_path,
        output_dir: output_dir,
        skip_download: skip_download,
        specs: specs
      ]
      |> maybe_add_overrides_dir(overrides_dir)
      |> maybe_add_sat_resources(xlsx_path, xlsx_url, force_download)

    case Sat.Catalogos.Codegen.generate(codegen_opts) do
      {:ok, written_paths} ->
        for path <- written_paths do
          Mix.shell().info("==> Escribió #{path}")
        end

        Mix.shell().info("#{length(written_paths)} catálogos generados")

      {:error, {:missing_xsd, path}} ->
        Mix.shell().error("Error: XSD no encontrado: #{path}")
        Mix.raise("Codegen falló: XSD no encontrado")

      {:error, {:missing_xlsx, path}} ->
        Mix.shell().error("Error: XLSX no encontrado: #{path}")
        Mix.raise("Codegen falló: XLSX no encontrado")

      {:error, reason} ->
        Mix.shell().error("Error en codegen: #{inspect(reason)}")
        Mix.raise("Codegen falló: #{inspect(reason)}")
    end
  end

  # ─── Private helpers ─────────────────────────────────────────────────────────

  defp filter_specs(nil) do
    Sat.Catalogos.Codegen.Catalogs.specs()
  end

  defp filter_specs(only_str) do
    only_list = only_str |> String.split(",") |> Enum.map(&String.trim/1)

    Sat.Catalogos.Codegen.Catalogs.specs()
    |> Enum.filter(fn spec ->
      # Match by file_name without .ex, e.g. "forma_pago"
      base = Path.basename(spec.file_name, ".ex")
      base in only_list
    end)
  end

  defp maybe_add_overrides_dir(opts, nil), do: opts

  defp maybe_add_overrides_dir(opts, overrides_dir) do
    Keyword.put(opts, :overrides_dir, overrides_dir)
  end

  defp maybe_add_sat_resources(opts, _xlsx_path, _xlsx_url, false = _force), do: opts

  defp maybe_add_sat_resources(opts, xlsx_path, xlsx_url, _force) do
    # force_download is true: always build sat_resources so Codegen can (re-)download.
    # We must NOT gate on File.exists? here — if the file exists but --force-download
    # was passed, skip_download is still false (see: File.exists? and not force_download),
    # so Codegen will reach download_xlsx/2. Without sat_resources it would fail with
    # {:missing_xlsx_no_resources, ...}.
    xlsx_dir = Path.dirname(xlsx_path)

    sat_resources =
      Sat.Recursos.SatResources.new(
        version: "4.0",
        output_dir: xlsx_dir,
        xlsx_url: xlsx_url
      )

    Keyword.put(opts, :sat_resources, sat_resources)
  end
end
