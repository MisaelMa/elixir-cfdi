defmodule Sat.Contabilidad.Xml.Balanza do
  @moduledoc """
  Generates Balanza de Comprobación XML per Anexo 24.
  """

  alias Sat.Contabilidad.Types
  alias Sat.Contabilidad.Types.{ContribuyenteInfo, CuentaBalanza}

  @ns_bce_13 "http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/BalanzaComprobacion"

  @spec build(ContribuyenteInfo.t(), [CuentaBalanza.t()], String.t()) :: String.t()
  def build(info, cuentas, version \\ "1.3") do
    ns = if version == "1.3", do: @ns_bce_13, else: String.replace(@ns_bce_13, "1_3", "1_1")
    tipo_envio = Types.tipo_envio_value(info.tipo_envio)

    cuentas_xml =
      cuentas
      |> Enum.map(fn c ->
        ~s(  <BCE:Ctas NumCta="#{c.num_cta}" SaldoIni="#{fmt(c.saldo_ini)}" Debe="#{fmt(c.debe)}" Haber="#{fmt(c.haber)}" SaldoFin="#{fmt(c.saldo_fin)}"/>)
      end)
      |> Enum.join("\n")

    """
    <?xml version="1.0" encoding="utf-8"?>
    <BCE:Balanza xmlns:BCE="#{ns}"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 Version="#{version}"
                 RFC="#{info.rfc}"
                 Mes="#{info.mes}"
                 Anio="#{info.anio}"
                 TipoEnvio="#{tipo_envio}">
    #{cuentas_xml}
    </BCE:Balanza>\
    """
    |> String.trim_leading()
  end

  defp fmt(n), do: :erlang.float_to_binary(n / 1, decimals: 2)
end
