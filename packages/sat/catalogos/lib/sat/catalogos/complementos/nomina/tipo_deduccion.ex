# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.TipoDeduccion do
  @moduledoc "Catálogo c_TipoDeduccion del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "001", label: "Seguridad social", deprecated: false},
    %{value: "002", label: "ISR", deprecated: false},
    %{
      value: "003",
      label: "Aportaciones a retiro, cesantía en edad avanzada y vejez.",
      deprecated: false
    },
    %{value: "004", label: "Otros", deprecated: false},
    %{value: "005", label: "Aportaciones a Fondo de vivienda", deprecated: false},
    %{value: "006", label: "Descuento por incapacidad", deprecated: false},
    %{value: "007", label: "Pensión alimenticia", deprecated: false},
    %{value: "008", label: "Renta", deprecated: false},
    %{
      value: "009",
      label: "Préstamos provenientes del Fondo Nacional de la Vivienda para los Trabajadores",
      deprecated: false
    },
    %{value: "010", label: "Pago por crédito de vivienda", deprecated: false},
    %{value: "011", label: "Pago de abonos INFONACOT", deprecated: false},
    %{value: "012", label: "Anticipo de salarios", deprecated: false},
    %{value: "013", label: "Pagos hechos con exceso al trabajador", deprecated: false},
    %{value: "014", label: "Errores", deprecated: false},
    %{value: "015", label: "Pérdidas", deprecated: false},
    %{value: "016", label: "Averías", deprecated: false},
    %{
      value: "017",
      label: "Adquisición de artículos producidos por la empresa o establecimiento",
      deprecated: false
    },
    %{
      value: "018",
      label:
        "Cuotas para la constitución y fomento de sociedades cooperativas y de cajas de ahorro",
      deprecated: false
    },
    %{value: "019", label: "Cuotas sindicales", deprecated: false},
    %{value: "020", label: "Ausencia (Ausentismo)", deprecated: false},
    %{value: "021", label: "Cuotas obrero patronales", deprecated: false},
    %{value: "022", label: "Impuestos Locales", deprecated: false},
    %{value: "023", label: "Aportaciones voluntarias", deprecated: false},
    %{value: "024", label: "Ajuste en Gratificación Anual (Aguinaldo) Exento", deprecated: false},
    %{
      value: "025",
      label: "Ajuste en Gratificación Anual (Aguinaldo) Gravado",
      deprecated: false
    },
    %{
      value: "026",
      label: "Ajuste en Participación de los Trabajadores en las Utilidades PTU Exento",
      deprecated: false
    },
    %{
      value: "027",
      label: "Ajuste en Participación de los Trabajadores en las Utilidades PTU Gravado",
      deprecated: false
    },
    %{
      value: "028",
      label: "Ajuste en Reembolso de Gastos Médicos Dentales y Hospitalarios Exento",
      deprecated: false
    },
    %{value: "029", label: "Ajuste en Fondo de ahorro Exento", deprecated: false},
    %{value: "030", label: "Ajuste en Caja de ahorro Exento", deprecated: false},
    %{
      value: "031",
      label: "Ajuste en Contribuciones a Cargo del Trabajador Pagadas por el Patrón Exento",
      deprecated: false
    },
    %{value: "032", label: "Ajuste en Premios por puntualidad Gravado", deprecated: false},
    %{value: "033", label: "Ajuste en Prima de Seguro de vida Exento", deprecated: false},
    %{
      value: "034",
      label: "Ajuste en Seguro de Gastos Médicos Mayores Exento",
      deprecated: false
    },
    %{
      value: "035",
      label: "Ajuste en Cuotas Sindicales Pagadas por el Patrón Exento",
      deprecated: false
    },
    %{value: "036", label: "Ajuste en Subsidios por incapacidad Exento", deprecated: false},
    %{
      value: "037",
      label: "Ajuste en Becas para trabajadores y/o hijos Exento",
      deprecated: false
    },
    %{value: "038", label: "Ajuste en Horas extra Exento", deprecated: false},
    %{value: "039", label: "Ajuste en Horas extra Gravado", deprecated: false},
    %{value: "040", label: "Ajuste en Prima dominical Exento", deprecated: false},
    %{value: "041", label: "Ajuste en Prima dominical Gravado", deprecated: false},
    %{value: "042", label: "Ajuste en Prima vacacional Exento", deprecated: false},
    %{value: "043", label: "Ajuste en Prima vacacional Gravado", deprecated: false},
    %{value: "044", label: "Ajuste en Prima por antigüedad Exento", deprecated: false},
    %{value: "045", label: "Ajuste en Prima por antigüedad Gravado", deprecated: false},
    %{value: "046", label: "Ajuste en Pagos por separación Exento", deprecated: false},
    %{value: "047", label: "Ajuste en Pagos por separación Gravado", deprecated: false},
    %{value: "048", label: "Ajuste en Seguro de retiro Exento", deprecated: false},
    %{value: "049", label: "Ajuste en Indemnizaciones Exento", deprecated: false},
    %{value: "050", label: "Ajuste en Indemnizaciones Gravado", deprecated: false},
    %{value: "051", label: "Ajuste en Reembolso por funeral Exento", deprecated: false},
    %{
      value: "052",
      label: "Ajuste en Cuotas de seguridad social pagadas por el patrón Exento",
      deprecated: false
    },
    %{value: "053", label: "Ajuste en Comisiones Gravado", deprecated: false},
    %{value: "054", label: "Ajuste en Vales de despensa Exento", deprecated: false},
    %{value: "055", label: "Ajuste en Vales de restaurante Exento", deprecated: false},
    %{value: "056", label: "Ajuste en Vales de gasolina Exento", deprecated: false},
    %{value: "057", label: "Ajuste en Vales de ropa Exento", deprecated: false},
    %{value: "058", label: "Ajuste en Ayuda para renta Exento", deprecated: false},
    %{value: "059", label: "Ajuste en Ayuda para artículos escolares Exento", deprecated: false},
    %{value: "060", label: "Ajuste en Ayuda para anteojos Exento", deprecated: false},
    %{value: "061", label: "Ajuste en Ayuda para transporte Exento", deprecated: false},
    %{value: "062", label: "Ajuste en Ayuda para gastos de funeral Exento", deprecated: false},
    %{value: "063", label: "Ajuste en Otros ingresos por salarios Exento", deprecated: false},
    %{value: "064", label: "Ajuste en Otros ingresos por salarios Gravado", deprecated: false},
    %{
      value: "065",
      label:
        "Ajuste en Jubilaciones, pensiones o haberes de retiro en una sola exhibición Exento",
      deprecated: false
    },
    %{
      value: "066",
      label:
        "Ajuste en Jubilaciones, pensiones o haberes de retiro en una sola exhibición Gravado",
      deprecated: false
    },
    %{value: "067", label: "Ajuste en Pagos por separación Acumulable", deprecated: false},
    %{value: "068", label: "Ajuste en Pagos por separación No acumulable", deprecated: false},
    %{
      value: "069",
      label: "Ajuste en Jubilaciones, pensiones o haberes de retiro en parcialidades Exento",
      deprecated: false
    },
    %{
      value: "070",
      label: "Ajuste en Jubilaciones, pensiones o haberes de retiro en parcialidades Gravado",
      deprecated: false
    },
    %{
      value: "071",
      label: "Ajuste en Subsidio para el empleo (efectivamente entregado al trabajador)",
      deprecated: false
    },
    %{
      value: "072",
      label: "Ajuste en Ingresos en acciones o títulos valor que representan bienes Exento",
      deprecated: false
    },
    %{
      value: "073",
      label: "Ajuste en Ingresos en acciones o títulos valor que representan bienes Gravado",
      deprecated: false
    },
    %{value: "074", label: "Ajuste en Alimentación Exento", deprecated: false},
    %{value: "075", label: "Ajuste en Alimentación Gravado", deprecated: false},
    %{value: "076", label: "Ajuste en Habitación Exento", deprecated: false},
    %{value: "077", label: "Ajuste en Habitación Gravado", deprecated: false},
    %{value: "078", label: "Ajuste en Premios por asistencia", deprecated: false},
    %{
      value: "079",
      label:
        "Ajuste en Pagos distintos a los listados y que no deben considerarse como ingreso por sueldos, salarios o ingresos asimilados.",
      deprecated: false
    },
    %{value: "080", label: "Ajuste en Viáticos gravados", deprecated: false},
    %{value: "081", label: "Ajuste en Viáticos (entregados al trabajador)", deprecated: false},
    %{value: "082", label: "Ajuste en Fondo de ahorro Gravado", deprecated: false},
    %{value: "083", label: "Ajuste en Caja de ahorro Gravado", deprecated: false},
    %{value: "084", label: "Ajuste en Prima de Seguro de vida Gravado", deprecated: false},
    %{
      value: "085",
      label: "Ajuste en Seguro de Gastos Médicos Mayores Gravado",
      deprecated: false
    },
    %{value: "086", label: "Ajuste en Subsidios por incapacidad Gravado", deprecated: false},
    %{
      value: "087",
      label: "Ajuste en Becas para trabajadores y/o hijos Gravado",
      deprecated: false
    },
    %{value: "088", label: "Ajuste en Seguro de retiro Gravado", deprecated: false},
    %{value: "089", label: "Ajuste en Vales de despensa Gravado", deprecated: false},
    %{value: "090", label: "Ajuste en Vales de restaurante Gravado", deprecated: false},
    %{value: "091", label: "Ajuste en Vales de gasolina Gravado", deprecated: false},
    %{value: "092", label: "Ajuste en Vales de ropa Gravado", deprecated: false},
    %{value: "093", label: "Ajuste en Ayuda para renta Gravado", deprecated: false},
    %{value: "094", label: "Ajuste en Ayuda para artículos escolares Gravado", deprecated: false},
    %{value: "095", label: "Ajuste en Ayuda para anteojos Gravado", deprecated: false},
    %{value: "096", label: "Ajuste en Ayuda para transporte Gravado", deprecated: false},
    %{value: "097", label: "Ajuste en Ayuda para gastos de funeral Gravado", deprecated: false},
    %{value: "098", label: "Ajuste a ingresos asimilados a salarios gravados", deprecated: false},
    %{
      value: "099",
      label: "Ajuste a ingresos por sueldos y salarios gravados",
      deprecated: false
    },
    %{value: "100", label: "Ajuste en Viáticos exentos", deprecated: false},
    %{value: "101", label: "ISR Retenido de ejercicio anterior", deprecated: false},
    %{
      value: "102",
      label:
        "Ajuste a pagos por gratificaciones, primas, compensaciones, recompensas u otros a extrabajadores derivados de jubilación en parcialidades, gravados",
      deprecated: false
    },
    %{
      value: "103",
      label:
        "Ajuste a pagos que se realicen a extrabajadores que obtengan una jubilación en parcialidades derivados de la ejecución de una resolución judicial o de un laudo gravados",
      deprecated: false
    },
    %{
      value: "104",
      label:
        "Ajuste a pagos que se realicen a extrabajadores que obtengan una jubilación en parcialidades derivados de la ejecución de una resolución judicial o de un laudo exentos",
      deprecated: false
    },
    %{
      value: "105",
      label:
        "Ajuste a pagos que se realicen a extrabajadores que obtengan una jubilación en una sola exhibición derivados de la ejecución de una resolución judicial o de un laudo gravados",
      deprecated: false
    },
    %{
      value: "106",
      label:
        "Ajuste a pagos que se realicen a extrabajadores que obtengan una jubilación en una sola exhibición derivados de la ejecución de una resolución judicial o de un laudo exentos",
      deprecated: false
    },
    %{value: "107", label: "Ajuste al Subsidio Causado", deprecated: false},
    %{value: "108", label: "", deprecated: true},
    %{value: "109", label: "", deprecated: true},
    %{value: "110", label: "", deprecated: true},
    %{value: "111", label: "", deprecated: true},
    %{value: "112", label: "", deprecated: true},
    %{value: "113", label: "", deprecated: true},
    %{value: "114", label: "", deprecated: true},
    %{value: "115", label: "", deprecated: true}
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
