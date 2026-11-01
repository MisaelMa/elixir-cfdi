# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.TipoJornada do
  @moduledoc "Catálogo c_TipoJornada del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "01", label: "Diurna", deprecated: false},
    %{value: "02", label: "Nocturna", deprecated: false},
    %{value: "03", label: "Mixta", deprecated: false},
    %{value: "04", label: "Por hora", deprecated: false},
    %{value: "05", label: "Reducida", deprecated: false},
    %{value: "06", label: "Continuada", deprecated: false},
    %{value: "07", label: "Partida", deprecated: false},
    %{value: "08", label: "Por turnos", deprecated: false},
    %{value: "99", label: "Otra Jornada", deprecated: false}
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
