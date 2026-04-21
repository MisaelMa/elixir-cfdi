defmodule Cfdi.Catalogos.UsoCFDI do
  @moduledoc """
  Catálogo de uso de CFDI del SAT (c_UsoCFDI).
  """

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

  @values %{
    adquisicion_mercancias: "G01",
    devoluciones_descuentos_bonificaciones: "G02",
    gastos_en_general: "G03",
    construcciones: "I01",
    mobiliario_y_equipo_de_oficina: "I02",
    equipo_de_transporte: "I03",
    equipo_de_computo: "I04",
    dados_troqueles_herramental: "I05",
    comunicaciones_telefonicas: "I06",
    comunicaciones_satelitales: "I07",
    otra_maquinaria: "I08",
    honorarios_medicos: "D01",
    gastos_medicos_por_incapacidad: "D02",
    gastos_funerales: "D03",
    donativos: "D04",
    intereses_por_creditos_hipotecarios: "D05",
    aportaciones_voluntarias_sar: "D06",
    prima_seguros_gastos_medicos: "D07",
    gastos_transportacion_escolar: "D08",
    cuentas_ahorro_pensiones: "D09",
    servicios_educativos: "D10",
    por_definir: "P01",
    sin_efectos_fiscales: "S01",
    pagos: "CP01",
    nomina: "CN01"
  }

  @spec value(t()) :: String.t()
  def value(key), do: Map.fetch!(@values, key)

  @spec list() :: [%{label: String.t(), value: String.t()}]
  def list do
    [
      %{value: "G01", label: "Adquisición de mercancias"},
      %{value: "G02", label: "Devoluciones, descuentos o bonificaciones"},
      %{value: "G03", label: "Gastos en general"},
      %{value: "I01", label: "Construcciones"},
      %{value: "I02", label: "Mobilario y equipo de oficina por inversiones"},
      %{value: "I03", label: "Equipo de transporte"},
      %{value: "I04", label: "Equipo de computo y accesorios"},
      %{value: "I05", label: "Dados, troqueles, moldes, matrices y herramental"},
      %{value: "I06", label: "Comunicaciones telefónicas"},
      %{value: "I07", label: "Comunicaciones satelitales"},
      %{value: "I08", label: "Otra maquinaria y equipo"},
      %{value: "D01", label: "Honorarios médicos, dentales y gastos hospitalarios."},
      %{value: "D02", label: "Gastos médicos por incapacidad o discapacidad"},
      %{value: "D03", label: "Gastos funerales."},
      %{value: "D04", label: "Donativos."},
      %{value: "D05", label: "Intereses reales efectivamente pagados por créditos hipotecarios (casa habitación)."},
      %{value: "D06", label: "Aportaciones voluntarias al SAR."},
      %{value: "D07", label: "Primas por seguros de gastos médicos."},
      %{value: "D08", label: "Gastos de transportación escolar obligatoria."},
      %{value: "D09", label: "Depósitos en cuentas para el ahorro, primas que tengan como base planes de pensiones."},
      %{value: "D10", label: "Pagos por servicios educativos (colegiaturas)"},
      %{value: "P01", label: "Por definir"}
    ]
  end

  @spec valid?(String.t()) :: boolean()
  def valid?(code), do: code in Map.values(@values)

  @spec from_code(String.t()) :: {:ok, t()} | :error
  def from_code(code) do
    case Enum.find(@values, fn {_k, v} -> v == code end) do
      {key, _} -> {:ok, key}
      nil -> :error
    end
  end
end
