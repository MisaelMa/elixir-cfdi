# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.TipoIncapacidad do
  @moduledoc "Catálogo c_TipoIncapacidad del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "01", label: "Riesgo de trabajo.", deprecated: false},
    %{value: "02", label: "Enfermedad en general.", deprecated: false},
    %{value: "03", label: "Maternidad.", deprecated: false},
    %{
      value: "04",
      label: "Licencia por cuidados médicos de hijos diagnosticados con cáncer.",
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
