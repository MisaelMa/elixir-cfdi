# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.TipoContrato do
  @moduledoc "Catálogo c_TipoContrato del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "01", label: "Contrato de trabajo por tiempo indeterminado", deprecated: false},
    %{value: "02", label: "Contrato de trabajo para obra determinada", deprecated: false},
    %{value: "03", label: "Contrato de trabajo por tiempo determinado", deprecated: false},
    %{value: "04", label: "Contrato de trabajo por temporada", deprecated: false},
    %{value: "05", label: "Contrato de trabajo sujeto a prueba", deprecated: false},
    %{value: "06", label: "Contrato de trabajo con capacitación inicial", deprecated: false},
    %{
      value: "07",
      label: "Modalidad de contratación por pago de hora laborada",
      deprecated: false
    },
    %{value: "08", label: "Modalidad de trabajo por comisión laboral", deprecated: false},
    %{
      value: "09",
      label: "Modalidades de contratación donde no existe relación de trabajo",
      deprecated: false
    },
    %{value: "10", label: "Jubilación, pensión, retiro.", deprecated: false},
    %{value: "99", label: "Otro contrato", deprecated: false}
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
