# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.PeriodicidadPago do
  @moduledoc "Catálogo c_PeriodicidadPago del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "01", label: "Diario", deprecated: false},
    %{value: "02", label: "Semanal", deprecated: false},
    %{value: "03", label: "Catorcenal", deprecated: false},
    %{value: "04", label: "Quincenal", deprecated: false},
    %{value: "05", label: "Mensual", deprecated: false},
    %{value: "06", label: "Bimestral", deprecated: false},
    %{value: "07", label: "Unidad obra", deprecated: false},
    %{value: "08", label: "Comisión", deprecated: false},
    %{value: "09", label: "Precio alzado", deprecated: false},
    %{value: "10", label: "Decenal", deprecated: false},
    %{value: "99", label: "Otra Periodicidad", deprecated: false}
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
