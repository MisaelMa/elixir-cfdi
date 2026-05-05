# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.RegimenFiscal do
  @moduledoc "Catálogo c_RegimenFiscal del SAT (CFDI 4.0)."

  @type t :: %{
          value: String.t(),
          label: String.t(),
          persona_fisica: boolean(),
          persona_moral: boolean(),
          inicio_vigencia: Date.t() | nil,
          fin_vigencia: Date.t() | nil,
          deprecated: boolean()
        }

  @entries [
    %{
      value: "601",
      label: "General de Ley Personas Morales",
      persona_fisica: false,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    }
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.value == code))
  def valid?(_), do: false

  @doc "Busca una entrada por su código."
  def from_code(code) when is_binary(code) do
    case Enum.find(@entries, &(&1.value == code)) do
      nil -> :error
      entry -> {:ok, entry}
    end
  end
end
