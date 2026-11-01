# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.TipoOtroPago do
  @moduledoc "Catálogo c_TipoOtroPago del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{
      value: "001",
      label: "Reintegro de ISR pagado en exceso (siempre que no haya sido enterado al SAT).",
      deprecated: false
    },
    %{
      value: "002",
      label: "Subsidio para el empleo (efectivamente entregado al trabajador).",
      deprecated: false
    },
    %{value: "003", label: "Viáticos (entregados al trabajador).", deprecated: false},
    %{
      value: "004",
      label: "Aplicación de saldo a favor por compensación anual.",
      deprecated: false
    },
    %{
      value: "005",
      label:
        "Reintegro de ISR retenido en exceso de ejercicio anterior (siempre que no haya sido enterado al SAT).",
      deprecated: false
    },
    %{
      value: "006",
      label: "Alimentos en bienes (Servicios de comedor y comida) Art 94 último párrafo LISR.",
      deprecated: false
    },
    %{value: "007", label: "ISR ajustado por subsidio.", deprecated: false},
    %{
      value: "008",
      label:
        "Subsidio efectivamente entregado que no correspondía (Aplica sólo cuando haya ajuste al cierre de mes en relación con el Apéndice 7 de la guía de llenado de nómina).",
      deprecated: false
    },
    %{
      value: "009",
      label: "Reembolso de descuentos efectuados para el crédito de vivienda.",
      deprecated: false
    },
    %{
      value: "999",
      label:
        "Pagos distintos a los listados y que no deben considerarse como ingreso por sueldos, salarios o ingresos asimilados.",
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
