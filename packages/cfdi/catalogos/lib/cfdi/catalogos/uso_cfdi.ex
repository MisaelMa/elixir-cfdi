# ─────────────────────────────────────────────────────────────
#  Generado por Cfdi.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Cfdi.Catalogos.UsoCFDI do
  @moduledoc "Catálogo c_UsoCFDI del SAT (CFDI 4.0)."

  @type t ::
          :adquisicion_mercancias
          | :devoluciones_descuentos_bonificaciones
          | :gastos_en_general
          | :construcciones
          | :mobiliario_y_equipo_de_oficina
          | :equipo_de_transporte
          | :equipo_de_computo
          | :dados_troqueles_herramental
          | :comunicaciones_telefonicas
          | :comunicaciones_satelitales
          | :otra_maquinaria
          | :honorarios_medicos
          | :gastos_medicos_por_incapacidad
          | :gastos_funerales
          | :donativos
          | :intereses_por_creditos_hipotecarios
          | :aportaciones_voluntarias_sar
          | :prima_seguros_gastos_medicos
          | :gastos_transportacion_escolar
          | :cuentas_ahorro_pensiones
          | :servicios_educativos
          | :por_definir
          | :sin_efectos_fiscales
          | :pagos
          | :nomina

  @entries [
    %{
      value: :adquisicion_mercancias,
      code: "G01",
      label: "Adquisición de mercancías.",
      deprecated: false
    },
    %{
      value: :devoluciones_descuentos_bonificaciones,
      code: "G02",
      label: "Devoluciones, descuentos o bonificaciones.",
      deprecated: false
    },
    %{value: :gastos_en_general, code: "G03", label: "Gastos en general.", deprecated: false},
    %{value: :construcciones, code: "I01", label: "Construcciones.", deprecated: false},
    %{
      value: :mobiliario_y_equipo_de_oficina,
      code: "I02",
      label: "Mobiliario y equipo de oficina por inversiones.",
      deprecated: false
    },
    %{
      value: :equipo_de_transporte,
      code: "I03",
      label: "Equipo de transporte.",
      deprecated: false
    },
    %{
      value: :equipo_de_computo,
      code: "I04",
      label: "Equipo de computo y accesorios.",
      deprecated: false
    },
    %{
      value: :dados_troqueles_herramental,
      code: "I05",
      label: "Dados, troqueles, moldes, matrices y herramental.",
      deprecated: false
    },
    %{
      value: :comunicaciones_telefonicas,
      code: "I06",
      label: "Comunicaciones telefónicas.",
      deprecated: false
    },
    %{
      value: :comunicaciones_satelitales,
      code: "I07",
      label: "Comunicaciones satelitales.",
      deprecated: false
    },
    %{
      value: :otra_maquinaria,
      code: "I08",
      label: "Otra maquinaria y equipo.",
      deprecated: false
    },
    %{
      value: :honorarios_medicos,
      code: "D01",
      label: "Honorarios médicos, dentales y gastos hospitalarios.",
      deprecated: false
    },
    %{
      value: :gastos_medicos_por_incapacidad,
      code: "D02",
      label: "Gastos médicos por incapacidad o discapacidad.",
      deprecated: false
    },
    %{value: :gastos_funerales, code: "D03", label: "Gastos funerales.", deprecated: false},
    %{value: :donativos, code: "D04", label: "Donativos.", deprecated: false},
    %{
      value: :intereses_por_creditos_hipotecarios,
      code: "D05",
      label:
        "Intereses reales efectivamente pagados por créditos hipotecarios (casa habitación).",
      deprecated: false
    },
    %{
      value: :aportaciones_voluntarias_sar,
      code: "D06",
      label: "Aportaciones voluntarias al SAR.",
      deprecated: false
    },
    %{
      value: :prima_seguros_gastos_medicos,
      code: "D07",
      label: "Primas por seguros de gastos médicos.",
      deprecated: false
    },
    %{
      value: :gastos_transportacion_escolar,
      code: "D08",
      label: "Gastos de transportación escolar obligatoria.",
      deprecated: false
    },
    %{
      value: :cuentas_ahorro_pensiones,
      code: "D09",
      label:
        "Depósitos en cuentas para el ahorro, primas que tengan como base planes de pensiones.",
      deprecated: false
    },
    %{
      value: :servicios_educativos,
      code: "D10",
      label: "Pagos por servicios educativos (colegiaturas).",
      deprecated: false
    },
    %{value: :por_definir, code: "P01", label: "Por definir", deprecated: true},
    %{
      value: :sin_efectos_fiscales,
      code: "S01",
      label: "Sin efectos fiscales.  ",
      deprecated: false
    },
    %{value: :pagos, code: "CP01", label: "Pagos", deprecated: false},
    %{value: :nomina, code: "CN01", label: "Nómina", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:adquisicion_mercancias), do: "G01"
  def value(:devoluciones_descuentos_bonificaciones), do: "G02"
  def value(:gastos_en_general), do: "G03"
  def value(:construcciones), do: "I01"
  def value(:mobiliario_y_equipo_de_oficina), do: "I02"
  def value(:equipo_de_transporte), do: "I03"
  def value(:equipo_de_computo), do: "I04"
  def value(:dados_troqueles_herramental), do: "I05"
  def value(:comunicaciones_telefonicas), do: "I06"
  def value(:comunicaciones_satelitales), do: "I07"
  def value(:otra_maquinaria), do: "I08"
  def value(:honorarios_medicos), do: "D01"
  def value(:gastos_medicos_por_incapacidad), do: "D02"
  def value(:gastos_funerales), do: "D03"
  def value(:donativos), do: "D04"
  def value(:intereses_por_creditos_hipotecarios), do: "D05"
  def value(:aportaciones_voluntarias_sar), do: "D06"
  def value(:prima_seguros_gastos_medicos), do: "D07"
  def value(:gastos_transportacion_escolar), do: "D08"
  def value(:cuentas_ahorro_pensiones), do: "D09"
  def value(:servicios_educativos), do: "D10"
  def value(:por_definir), do: "P01"
  def value(:sin_efectos_fiscales), do: "S01"
  def value(:pagos), do: "CP01"
  def value(:nomina), do: "CN01"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("G01"),
    do:
      {:ok,
       %{
         value: :adquisicion_mercancias,
         code: "G01",
         label: "Adquisición de mercancías.",
         deprecated: false
       }}

  def from_code("G02"),
    do:
      {:ok,
       %{
         value: :devoluciones_descuentos_bonificaciones,
         code: "G02",
         label: "Devoluciones, descuentos o bonificaciones.",
         deprecated: false
       }}

  def from_code("G03"),
    do:
      {:ok,
       %{value: :gastos_en_general, code: "G03", label: "Gastos en general.", deprecated: false}}

  def from_code("I01"),
    do: {:ok, %{value: :construcciones, code: "I01", label: "Construcciones.", deprecated: false}}

  def from_code("I02"),
    do:
      {:ok,
       %{
         value: :mobiliario_y_equipo_de_oficina,
         code: "I02",
         label: "Mobiliario y equipo de oficina por inversiones.",
         deprecated: false
       }}

  def from_code("I03"),
    do:
      {:ok,
       %{
         value: :equipo_de_transporte,
         code: "I03",
         label: "Equipo de transporte.",
         deprecated: false
       }}

  def from_code("I04"),
    do:
      {:ok,
       %{
         value: :equipo_de_computo,
         code: "I04",
         label: "Equipo de computo y accesorios.",
         deprecated: false
       }}

  def from_code("I05"),
    do:
      {:ok,
       %{
         value: :dados_troqueles_herramental,
         code: "I05",
         label: "Dados, troqueles, moldes, matrices y herramental.",
         deprecated: false
       }}

  def from_code("I06"),
    do:
      {:ok,
       %{
         value: :comunicaciones_telefonicas,
         code: "I06",
         label: "Comunicaciones telefónicas.",
         deprecated: false
       }}

  def from_code("I07"),
    do:
      {:ok,
       %{
         value: :comunicaciones_satelitales,
         code: "I07",
         label: "Comunicaciones satelitales.",
         deprecated: false
       }}

  def from_code("I08"),
    do:
      {:ok,
       %{
         value: :otra_maquinaria,
         code: "I08",
         label: "Otra maquinaria y equipo.",
         deprecated: false
       }}

  def from_code("D01"),
    do:
      {:ok,
       %{
         value: :honorarios_medicos,
         code: "D01",
         label: "Honorarios médicos, dentales y gastos hospitalarios.",
         deprecated: false
       }}

  def from_code("D02"),
    do:
      {:ok,
       %{
         value: :gastos_medicos_por_incapacidad,
         code: "D02",
         label: "Gastos médicos por incapacidad o discapacidad.",
         deprecated: false
       }}

  def from_code("D03"),
    do:
      {:ok,
       %{value: :gastos_funerales, code: "D03", label: "Gastos funerales.", deprecated: false}}

  def from_code("D04"),
    do: {:ok, %{value: :donativos, code: "D04", label: "Donativos.", deprecated: false}}

  def from_code("D05"),
    do:
      {:ok,
       %{
         value: :intereses_por_creditos_hipotecarios,
         code: "D05",
         label:
           "Intereses reales efectivamente pagados por créditos hipotecarios (casa habitación).",
         deprecated: false
       }}

  def from_code("D06"),
    do:
      {:ok,
       %{
         value: :aportaciones_voluntarias_sar,
         code: "D06",
         label: "Aportaciones voluntarias al SAR.",
         deprecated: false
       }}

  def from_code("D07"),
    do:
      {:ok,
       %{
         value: :prima_seguros_gastos_medicos,
         code: "D07",
         label: "Primas por seguros de gastos médicos.",
         deprecated: false
       }}

  def from_code("D08"),
    do:
      {:ok,
       %{
         value: :gastos_transportacion_escolar,
         code: "D08",
         label: "Gastos de transportación escolar obligatoria.",
         deprecated: false
       }}

  def from_code("D09"),
    do:
      {:ok,
       %{
         value: :cuentas_ahorro_pensiones,
         code: "D09",
         label:
           "Depósitos en cuentas para el ahorro, primas que tengan como base planes de pensiones.",
         deprecated: false
       }}

  def from_code("D10"),
    do:
      {:ok,
       %{
         value: :servicios_educativos,
         code: "D10",
         label: "Pagos por servicios educativos (colegiaturas).",
         deprecated: false
       }}

  def from_code("P01"),
    do: {:ok, %{value: :por_definir, code: "P01", label: "Por definir", deprecated: true}}

  def from_code("S01"),
    do:
      {:ok,
       %{
         value: :sin_efectos_fiscales,
         code: "S01",
         label: "Sin efectos fiscales.  ",
         deprecated: false
       }}

  def from_code("CP01"),
    do: {:ok, %{value: :pagos, code: "CP01", label: "Pagos", deprecated: false}}

  def from_code("CN01"),
    do: {:ok, %{value: :nomina, code: "CN01", label: "Nómina", deprecated: false}}

  def from_code(_), do: :error
end
