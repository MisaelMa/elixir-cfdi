defmodule Sat.Contabilidad.Xml.Polizas do
  @moduledoc """
  Generates Pólizas del Periodo XML per Anexo 24.
  """

  alias Sat.Contabilidad.Types
  alias Sat.Contabilidad.Types.{ContribuyenteInfo, Poliza}

  @ns_plz_13 "http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/PolizasPeriodo"

  @spec build(ContribuyenteInfo.t(), [Poliza.t()], String.t(), String.t()) :: String.t()
  def build(info, polizas, tipo_solicitud, version \\ "1.3") do
    ns = if version == "1.3", do: @ns_plz_13, else: String.replace(@ns_plz_13, "1_3", "1_1")
    tipo_envio = Types.tipo_envio_value(info.tipo_envio)

    polizas_xml =
      polizas
      |> Enum.map(fn p ->
        detalle_xml =
          p.detalle
          |> Enum.map(fn d ->
            ~s(      <PLZ:Transaccion NumCta="#{d.num_cta}" Concepto="#{d.concepto}" Debe="#{fmt(d.debe)}" Haber="#{fmt(d.haber)}"/>)
          end)
          |> Enum.join("\n")

        ~s(    <PLZ:Poliza NumUnIdenPol="#{p.num_poliza}" Fecha="#{p.fecha}" Concepto="#{p.concepto}">\n#{detalle_xml}\n    </PLZ:Poliza>)
      end)
      |> Enum.join("\n")

    """
    <?xml version="1.0" encoding="utf-8"?>
    <PLZ:Polizas xmlns:PLZ="#{ns}"
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                 Version="#{version}"
                 RFC="#{info.rfc}"
                 Mes="#{info.mes}"
                 Anio="#{info.anio}"
                 TipoEnvio="#{tipo_envio}"
                 TipoSolicitud="#{tipo_solicitud}">
    #{polizas_xml}
    </PLZ:Polizas>\
    """
    |> String.trim_leading()
  end

  defp fmt(n), do: :erlang.float_to_binary(n / 1, decimals: 2)
end
