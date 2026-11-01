# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.TipoPercepcion do
  @moduledoc "Catálogo c_TipoPercepcion del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "001", label: "Sueldos, Salarios  Rayas y Jornales", deprecated: false},
    %{value: "002", label: "Gratificación Anual (Aguinaldo)", deprecated: false},
    %{
      value: "003",
      label: "Participación de los Trabajadores en las Utilidades PTU",
      deprecated: false
    },
    %{
      value: "004",
      label: "Reembolso de Gastos Médicos Dentales y Hospitalarios",
      deprecated: false
    },
    %{value: "005", label: "Fondo de Ahorro", deprecated: false},
    %{value: "006", label: "Caja de ahorro", deprecated: false},
    %{
      value: "009",
      label: "Contribuciones a Cargo del Trabajador Pagadas por el Patrón",
      deprecated: false
    },
    %{value: "010", label: "Premios por puntualidad", deprecated: false},
    %{value: "011", label: "Prima de Seguro de vida", deprecated: false},
    %{value: "012", label: "Seguro de Gastos Médicos Mayores", deprecated: false},
    %{value: "013", label: "Cuotas Sindicales Pagadas por el Patrón", deprecated: false},
    %{value: "014", label: "Subsidios por incapacidad", deprecated: false},
    %{value: "015", label: "Becas para trabajadores y/o hijos", deprecated: false},
    %{value: "019", label: "Horas extra", deprecated: false},
    %{value: "020", label: "Prima dominical", deprecated: false},
    %{value: "021", label: "Prima vacacional", deprecated: false},
    %{value: "022", label: "Prima por antigüedad", deprecated: false},
    %{value: "023", label: "Pagos por separación", deprecated: false},
    %{value: "024", label: "Seguro de retiro", deprecated: false},
    %{value: "025", label: "Indemnizaciones", deprecated: false},
    %{value: "026", label: "Reembolso por funeral", deprecated: false},
    %{value: "027", label: "Cuotas de seguridad social pagadas por el patrón", deprecated: false},
    %{value: "028", label: "Comisiones", deprecated: false},
    %{value: "029", label: "Vales de despensa", deprecated: false},
    %{value: "030", label: "Vales de restaurante", deprecated: false},
    %{value: "031", label: "Vales de gasolina", deprecated: false},
    %{value: "032", label: "Vales de ropa", deprecated: false},
    %{value: "033", label: "Ayuda para renta", deprecated: false},
    %{value: "034", label: "Ayuda para artículos escolares", deprecated: false},
    %{value: "035", label: "Ayuda para anteojos", deprecated: false},
    %{value: "036", label: "Ayuda para transporte", deprecated: false},
    %{value: "037", label: "Ayuda para gastos de funeral", deprecated: false},
    %{value: "038", label: "Otros ingresos por salarios", deprecated: false},
    %{value: "039", label: "Jubilaciones, pensiones o haberes de retiro", deprecated: false},
    %{
      value: "044",
      label: "Jubilaciones, pensiones o haberes de retiro en parcialidades",
      deprecated: false
    },
    %{
      value: "045",
      label: "Ingresos en acciones o títulos valor que representan bienes",
      deprecated: false
    },
    %{value: "046", label: "", deprecated: true},
    %{value: "047", label: "", deprecated: true},
    %{value: "048", label: "Habitación", deprecated: false},
    %{value: "049", label: "Premios por asistencia", deprecated: false},
    %{value: "050", label: "Viáticos", deprecated: false},
    %{
      value: "051",
      label:
        "Pagos por gratificaciones, primas, compensaciones, recompensas u otros a extrabajadores derivados de jubilación en parcialidades",
      deprecated: false
    },
    %{
      value: "052",
      label:
        "Pagos que se realicen a extrabajadores que obtengan una jubilación en parcialidades derivados de la ejecución de resoluciones judicial o de un laudo",
      deprecated: false
    },
    %{
      value: "053",
      label:
        "Pagos que se realicen a extrabajadores que obtengan una jubilación en una sola exhibición derivados de la ejecución de resoluciones judicial o de un laudo",
      deprecated: false
    },
    %{value: "054", label: "", deprecated: true},
    %{value: "055", label: "", deprecated: true},
    %{value: "056", label: "", deprecated: true},
    %{value: "057", label: "", deprecated: true}
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
