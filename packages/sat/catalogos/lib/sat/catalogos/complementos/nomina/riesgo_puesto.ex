# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.RiesgoPuesto do
  @moduledoc "Catálogo c_RiesgoPuesto del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "1", label: "Clase I", deprecated: false},
    %{value: "2", label: "Clase II", deprecated: false},
    %{value: "3", label: "Clase III", deprecated: false},
    %{value: "4", label: "Clase IV", deprecated: false},
    %{value: "5", label: "Clase V", deprecated: false},
    %{value: "99", label: "No aplica", deprecated: false}
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
