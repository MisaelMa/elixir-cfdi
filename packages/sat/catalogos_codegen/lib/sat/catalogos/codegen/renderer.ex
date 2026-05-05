defmodule Sat.Catalogos.Codegen.Renderer do
  @moduledoc """
  Renders Elixir source code for a single catalog module.

  Accepts a `%{spec: Catalogs.Spec.t(), entries: [entry()]}` map and returns
  `{:ok, String.t()}` containing valid, `mix format`-compliant Elixir source.

  ## Entry shapes

  - Variant `:with_atoms`: `%{value: atom(), code: String.t(), label: String.t(), deprecated: boolean()}`
  - Variant `:strings_only`: `%{value: String.t(), label: String.t(), deprecated: boolean()}`
  - Variant `:regimen_fiscal`: adds `persona_fisica`, `persona_moral`, `inicio_vigencia`, `fin_vigencia`

  ## Design decisions

  - Entries for `:with_atoms` carry both `:value` (atom) and `:code` (string).
    This avoids a separate `code_for_atom` map and keeps all data co-located.
  - `value/1` for unknown atoms returns `nil`.
  - Output is deterministic — no timestamps; same input → byte-equal output.
  - The 4-line header is hardcoded per project decision (Q3).
  - Source is run through `Code.format_string!/1` after generation to guarantee
    byte-equal output with `mix format`.
  """

  alias Sat.Catalogos.Codegen.Catalogs.Spec

  @header "# ─────────────────────────────────────────────────────────────\n" <>
            "#  Generado por Sat.Catalogos.Codegen — NO EDITAR.\n" <>
            "#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx\n" <>
            "# ─────────────────────────────────────────────────────────────\n"

  @doc """
  Renders the Elixir source for a catalog module.

  ## Input shape

      %{
        spec: %Catalogs.Spec{},
        entries: [entry_map, ...]
      }

  Returns `{:ok, source_string}` or `{:error, reason}`.
  """
  @spec render(%{spec: Spec.t(), entries: [map()]}) :: {:ok, String.t()} | {:error, term()}
  def render(%{spec: %Spec{} = spec, entries: entries}) do
    source =
      case spec.variant do
        :with_atoms -> render_with_atoms(spec, entries)
        :strings_only -> render_strings_only(spec, entries)
        :regimen_fiscal -> render_regimen_fiscal(spec, entries)
      end

    {:ok, source}
  rescue
    error -> {:error, error}
  end

  # ─── Variant A: with_atoms ─────────────────────────────────────────────────

  defp render_with_atoms(spec, entries) do
    mod = inspect(spec.module_name)
    type_union = entries |> Enum.map(&":#{&1.value}") |> Enum.join(" | ")

    body =
      "defmodule #{mod} do\n" <>
        "  @moduledoc \"Catálogo #{spec.simpletype} del SAT (CFDI 4.0).\"\n\n" <>
        "  @type t :: #{type_union}\n\n" <>
        "  @entries #{render_entries_with_atoms(entries)}\n\n" <>
        "  @doc \"Lista completa del catálogo.\"\n" <>
        "  def list, do: @entries\n\n" <>
        "  @doc \"Devuelve true si el código existe en el catálogo.\"\n" <>
        "  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))\n" <>
        "  def valid?(_), do: false\n\n" <>
        "  @doc \"Convierte un átomo del enum al código string del SAT.\"\n" <>
        render_value_clauses(entries) <>
        "\n" <>
        "  @doc \"Busca una entrada por su código.\"\n" <>
        render_from_code_clauses_atoms(entries) <>
        "\nend\n"

    @header <> format_body(body)
  end

  defp render_entries_with_atoms(entries) do
    inner =
      entries
      |> Enum.map(fn e ->
        "%{value: #{inspect(e.value)}, code: #{inspect(e.code)}, label: #{inspect(e.label)}, deprecated: #{e.deprecated}}"
      end)
      |> Enum.join(",\n    ")

    "[\n    #{inner}\n  ]"
  end

  defp render_value_clauses(entries) do
    clauses =
      entries
      |> Enum.map(fn e -> "  def value(#{inspect(e.value)}), do: #{inspect(e.code)}\n" end)

    Enum.join(clauses) <> "  def value(_), do: nil\n"
  end

  defp render_from_code_clauses_atoms(entries) do
    clauses =
      Enum.map(entries, fn e ->
        entry_literal =
          "%{value: #{inspect(e.value)}, code: #{inspect(e.code)}, label: #{inspect(e.label)}, deprecated: #{e.deprecated}}"

        "  def from_code(#{inspect(e.code)}), do: {:ok, #{entry_literal}}\n"
      end)

    Enum.join(clauses) <> "  def from_code(_), do: :error\n"
  end

  # ─── Variant B: strings_only ───────────────────────────────────────────────

  defp render_strings_only(spec, entries) do
    mod = inspect(spec.module_name)

    body =
      "defmodule #{mod} do\n" <>
        "  @moduledoc \"Catálogo #{spec.simpletype} del SAT (CFDI 4.0).\"\n\n" <>
        "  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}\n\n" <>
        "  @entries #{render_entries_strings_only(entries)}\n\n" <>
        "  @doc \"Lista completa del catálogo.\"\n" <>
        "  def list, do: @entries\n\n" <>
        "  @doc \"Devuelve true si el código existe en el catálogo.\"\n" <>
        "  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.value == code))\n" <>
        "  def valid?(_), do: false\n\n" <>
        "  @doc \"Busca una entrada por su código.\"\n" <>
        "  def from_code(code) when is_binary(code) do\n" <>
        "    case Enum.find(@entries, &(&1.value == code)) do\n" <>
        "      nil -> :error\n" <>
        "      entry -> {:ok, entry}\n" <>
        "    end\n" <>
        "  end\n" <>
        "end\n"

    @header <> format_body(body)
  end

  defp render_entries_strings_only(entries) do
    inner =
      entries
      |> Enum.map(fn e ->
        "%{value: #{inspect(e.value)}, label: #{inspect(e.label)}, deprecated: #{e.deprecated}}"
      end)
      |> Enum.join(",\n    ")

    "[\n    #{inner}\n  ]"
  end

  # ─── Variant C: regimen_fiscal ─────────────────────────────────────────────

  defp render_regimen_fiscal(spec, entries) do
    mod = inspect(spec.module_name)

    type_t =
      "  @type t :: %{\n" <>
        "          value: String.t(),\n" <>
        "          label: String.t(),\n" <>
        "          persona_fisica: boolean(),\n" <>
        "          persona_moral: boolean(),\n" <>
        "          inicio_vigencia: Date.t() | nil,\n" <>
        "          fin_vigencia: Date.t() | nil,\n" <>
        "          deprecated: boolean()\n" <>
        "        }\n"

    body =
      "defmodule #{mod} do\n" <>
        "  @moduledoc \"Catálogo #{spec.simpletype} del SAT (CFDI 4.0).\"\n\n" <>
        type_t <>
        "\n" <>
        "  @entries #{render_entries_regimen_fiscal(entries)}\n\n" <>
        "  @doc \"Lista completa del catálogo.\"\n" <>
        "  def list, do: @entries\n\n" <>
        "  @doc \"Devuelve true si el código existe en el catálogo.\"\n" <>
        "  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.value == code))\n" <>
        "  def valid?(_), do: false\n\n" <>
        "  @doc \"Busca una entrada por su código.\"\n" <>
        "  def from_code(code) when is_binary(code) do\n" <>
        "    case Enum.find(@entries, &(&1.value == code)) do\n" <>
        "      nil -> :error\n" <>
        "      entry -> {:ok, entry}\n" <>
        "    end\n" <>
        "  end\n" <>
        "end\n"

    @header <> format_body(body)
  end

  defp render_entries_regimen_fiscal(entries) do
    inner =
      entries
      |> Enum.map(fn e ->
        # Deprecated entries (in XSD but not in XLSX) may lack extra columns.
        # Default to false / nil for missing fields.
        pf = inspect(Map.get(e, :persona_fisica, false))
        pm = inspect(Map.get(e, :persona_moral, false))
        iv = render_date(Map.get(e, :inicio_vigencia, nil))
        fv = render_date(Map.get(e, :fin_vigencia, nil))

        "%{\n" <>
          "      value: #{inspect(e.value)},\n" <>
          "      label: #{inspect(e.label)},\n" <>
          "      persona_fisica: #{pf},\n" <>
          "      persona_moral: #{pm},\n" <>
          "      inicio_vigencia: #{iv},\n" <>
          "      fin_vigencia: #{fv},\n" <>
          "      deprecated: #{e.deprecated}\n" <>
          "    }"
      end)
      |> Enum.join(",\n    ")

    "[\n    #{inner}\n  ]"
  end

  defp render_date(nil), do: "nil"
  defp render_date(%Date{} = d), do: "~D[#{Date.to_iso8601(d)}]"

  # ─── Formatting ────────────────────────────────────────────────────────────

  # Run the Elixir body (without the header) through Code.format_string!/1
  # to guarantee byte-equal output with `mix format`.
  defp format_body(body) when is_binary(body) do
    body
    |> Code.format_string!()
    |> IO.iodata_to_binary()
    |> then(&(&1 <> "\n"))
  end
end
