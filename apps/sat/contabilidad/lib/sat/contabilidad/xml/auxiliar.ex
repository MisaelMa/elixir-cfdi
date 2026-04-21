defmodule Sat.Contabilidad.Xml.Auxiliar do
  @moduledoc """
  Generates Auxiliar de Cuentas XML per Anexo 24.
  """

  alias Sat.Contabilidad.Types
  alias Sat.Contabilidad.Types.{ContribuyenteInfo, CuentaAuxiliar}

  @ns_aux_13 "http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/AuxiliarCtas"

  @spec build(ContribuyenteInfo.t(), [CuentaAuxiliar.t()], String.t(), String.t()) :: String.t()
  def build(info, cuentas, tipo_solicitud, version \\ "1.3") do
    ns = if version == "1.3", do: @ns_aux_13, else: String.replace(@ns_aux_13, "1_3", "1_1")
    tipo_envio = Types.tipo_envio_value(info.tipo_envio)

    cuentas_xml =
      cuentas
      |> Enum.map(fn c ->
        tx_xml =
          c.transacciones
          |> Enum.map(fn t ->
            ~s(      <AuxiliarCtas:DetalleAux Fecha="#{t.fecha}" NumUnIdenPol="#{t.num_poliza}" Concepto="#{t.concepto}" Debe="#{fmt(t.debe)}" Haber="#{fmt(t.haber)}"/>)
          end)
          |> Enum.join("\n")

        ~s(    <AuxiliarCtas:Cuenta NumCta="#{c.num_cta}" DesCta="#{c.des_cta}" SaldoIni="#{fmt(c.saldo_ini)}" SaldoFin="#{fmt(c.saldo_fin)}">\n#{tx_xml}\n    </AuxiliarCtas:Cuenta>)
      end)
      |> Enum.join("\n")

    """
    <?xml version="1.0" encoding="utf-8"?>
    <AuxiliarCtas:AuxiliarCtas xmlns:AuxiliarCtas="#{ns}"
                               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                               Version="#{version}"
                               RFC="#{info.rfc}"
                               Mes="#{info.mes}"
                               Anio="#{info.anio}"
                               TipoEnvio="#{tipo_envio}"
                               TipoSolicitud="#{tipo_solicitud}">
    #{cuentas_xml}
    </AuxiliarCtas:AuxiliarCtas>\
    """
    |> String.trim_leading()
  end

  defp fmt(n), do: :erlang.float_to_binary(n / 1, decimals: 2)
end
