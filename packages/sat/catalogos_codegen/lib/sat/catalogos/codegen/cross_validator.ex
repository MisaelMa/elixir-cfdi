defmodule Sat.Catalogos.Codegen.CrossValidator do
  @moduledoc """
  Reconciles XSD enumeration codes against XLSX rows.

  Validates that XLSX does not introduce codes unknown to the XSD,
  marks deprecated entries when codes are absent from the XLSX or have
  a past `ending_date`, and enforces atom override completeness when
  `emit_atoms: true`.
  """

  @type entry :: %{
          required(:value) => String.t(),
          required(:label) => String.t(),
          required(:deprecated) => boolean(),
          optional(atom()) => any()
        }

  @doc """
  Reconciles `xsd_codes` against `xlsx_rows` using the provided `overrides` map.

  ## Options

    * `:emit_atoms` — when `true`, every code in `xsd_codes` must have an entry
      in `overrides.enum_names`; otherwise returns `{:error, {:missing_atom_override, code}}`.

  ## Return

    * `{:ok, [entry()]}` — entries in the same order as `xsd_codes`
    * `{:error, {:xlsx_code_not_in_xsd, code}}` — XLSX has a code absent from XSD
    * `{:error, {:missing_atom_override, code}}` — `emit_atoms: true` but override missing
  """
  @spec reconcile(
          xsd_codes :: [String.t()],
          xlsx_rows :: [map()],
          overrides :: %{
            enum_names: %{String.t() => atom()},
            descriptions: %{String.t() => String.t()}
          },
          opts :: keyword()
        ) :: {:ok, [entry()]} | {:error, term()}
  def reconcile(xsd_codes, xlsx_rows, overrides, opts \\ []) do
    xsd_set = MapSet.new(xsd_codes)

    with :ok <- validate_xlsx_codes(xlsx_rows, xsd_set),
         :ok <- maybe_validate_atom_overrides(xsd_codes, overrides, opts) do
      xlsx_by_code = Map.new(xlsx_rows, &{&1.code, &1})
      today = Date.utc_today()

      entries =
        Enum.map(xsd_codes, fn code ->
          build_entry(code, xlsx_by_code, overrides, today)
        end)

      {:ok, entries}
    end
  end

  # Ensure every XLSX code exists in the XSD
  defp validate_xlsx_codes(xlsx_rows, xsd_set) do
    case Enum.find(xlsx_rows, fn row -> not MapSet.member?(xsd_set, row.code) end) do
      nil -> :ok
      row -> {:error, {:xlsx_code_not_in_xsd, row.code}}
    end
  end

  # When emit_atoms: true, every XSD code must have an atom override
  defp maybe_validate_atom_overrides(xsd_codes, overrides, opts) do
    if Keyword.get(opts, :emit_atoms, false) do
      case Enum.find(xsd_codes, fn code -> not Map.has_key?(overrides.enum_names, code) end) do
        nil -> :ok
        code -> {:error, {:missing_atom_override, code}}
      end
    else
      :ok
    end
  end

  # Build a single entry map for the given code
  defp build_entry(code, xlsx_by_code, overrides, today) do
    case Map.get(xlsx_by_code, code) do
      nil ->
        # Code absent from XLSX — deprecated
        label = Map.get(overrides.descriptions, code, "")
        %{value: code, label: label, deprecated: true}

      row ->
        deprecated = date_past?(row[:ending_date], today)
        base = %{value: code, label: row.label, deprecated: deprecated}
        # Flow through any extra columns (anything other than :code, :label, :ending_date)
        extras =
          Map.drop(row, [:code, :label, :ending_date])

        Map.merge(base, extras)
    end
  end

  # Returns true when a date is not nil and is before today
  defp date_past?(nil, _today), do: false

  defp date_past?(date, today) do
    Date.compare(date, today) == :lt
  end
end
