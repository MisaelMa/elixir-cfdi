defmodule Cfdi.Descarga.Soap.Solicitar do
  @moduledoc false

  alias Cfdi.Descarga.Types.SolicitudParams

  @spec build_solicitar_request(SolicitudParams.t(), String.t(), String.t(), String.t()) :: String.t()
  def build_solicitar_request(%SolicitudParams{} = params, token, cert, signature_value) do
    filtro_attr =
      if params.tipo_descarga == "RfcEmisor" do
        ~s(RfcEmisor="#{params.rfc_emisor || params.rfc_solicitante}")
      else
        ~s(RfcReceptor="#{params.rfc_receptor || params.rfc_solicitante}")
      end

    estado_attr =
      if params.estado_comprobante do
        ~s( EstadoComprobante="#{params.estado_comprobante}")
      else
        ""
      end

    ~s(<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            xmlns:des="http://DescargaMasivaTerceros.sat.gob.mx/"
            xmlns:xd="http://www.w3.org/2000/09/xmldsig#">
  <s:Header>
    <h:Security xmlns:h="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
      <u:Timestamp>
        <u:Created>#{token}</u:Created>
      </u:Timestamp>
      <xd:Signature>
        <xd:SignedInfo>
          <xd:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
          <xd:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
          <xd:Reference URI="#_0">
            <xd:Transforms>
              <xd:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
            </xd:Transforms>
            <xd:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
            <xd:DigestValue></xd:DigestValue>
          </xd:Reference>
        </xd:SignedInfo>
        <xd:SignatureValue>#{signature_value}</xd:SignatureValue>
        <xd:KeyInfo>
          <xd:X509Data>
            <xd:X509Certificate>#{cert}</xd:X509Certificate>
          </xd:X509Data>
        </xd:KeyInfo>
      </xd:Signature>
    </h:Security>
  </s:Header>
  <s:Body>
    <des:SolicitaDescarga>
      <des:solicitud #{filtro_attr}
                     FechaInicial="#{params.fecha_inicio}T00:00:00"
                     FechaFinal="#{params.fecha_fin}T23:59:59"
                     RfcSolicitante="#{params.rfc_solicitante}"
                     TipoSolicitud="#{params.tipo_solicitud}"#{estado_attr}>
        <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
                      Id="SelloDigital">
          <ds:SignedInfo>
            <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
            <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
            <ds:Reference URI="">
              <ds:Transforms>
                <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
              </ds:Transforms>
              <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
              <ds:DigestValue></ds:DigestValue>
            </ds:Reference>
          </ds:SignedInfo>
          <ds:SignatureValue>#{signature_value}</ds:SignatureValue>
          <ds:KeyInfo>
            <ds:X509Data>
              <ds:X509Certificate>#{cert}</ds:X509Certificate>
            </ds:X509Data>
          </ds:KeyInfo>
        </ds:Signature>
      </des:solicitud>
    </des:SolicitaDescarga>
  </s:Body>
</s:Envelope>)
  end

  @spec parse_solicitar_response(String.t()) :: {:ok, Cfdi.Descarga.Types.SolicitudResult.t()} | {:error, String.t()}
  def parse_solicitar_response(xml) when is_binary(xml) do
    cond do
      String.contains?(xml, "<faultcode>") or String.contains?(xml, ":Fault>") ->
        {:error, "SOAP Fault: #{extract_tag(xml, "faultstring")}"}

      true ->
        opening =
          extract_opening_tag(xml, "SolicitaDescargaResult") ||
            extract_opening_tag(xml, "RespuestaSolicitudDescMasivaTercerosSolicitud")

        ctx = opening || xml

        {:ok,
         %Cfdi.Descarga.Types.SolicitudResult{
           id_solicitud: extract_attr(ctx, "IdSolicitud"),
           cod_estatus: extract_attr(ctx, "CodEstatus"),
           mensaje: extract_attr(ctx, "Mensaje")
         }}
    end
  end

  defp extract_tag(xml, local) do
    re = ~r/<(?:[a-zA-Z0-9_]+:)?#{local}[^>]*>([\s\S]*?)<\/(?:[a-zA-Z0-9_]+:)?#{local}>/i

    case Regex.run(re, xml) do
      [_, inner] -> String.trim(inner)
      _ -> ""
    end
  end

  defp extract_opening_tag(xml, local) do
    re = ~r/<(?:[a-zA-Z0-9_]+:)?#{local}((?:\s+[^>]*)?)(?:\/>|>)/i

    case Regex.run(re, xml) do
      [full | _] -> full
      _ -> ""
    end
  end

  defp extract_attr(xml, name) do
    re = ~r/#{name}="([^"]*)"/i

    case Regex.run(re, xml) do
      [_, v] -> v
      _ -> ""
    end
  end
end
