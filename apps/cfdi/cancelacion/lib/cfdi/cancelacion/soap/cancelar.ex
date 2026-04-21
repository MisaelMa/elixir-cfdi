defmodule Cfdi.Cancelacion.Soap.Cancelar do
  @moduledoc false

  alias Cfdi.Cancelacion.Types.{CancelacionParams, CancelacionResult}

  @spec build_cancelacion_xml(
          CancelacionParams.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: String.t()
  def build_cancelacion_xml(
        %CancelacionParams{} = params,
        rfc_emisor,
        fecha,
        cert,
        signature_value,
        serial_number
      ) do
    folio_attr =
      if params.motivo == "01" && params.folio_sustitucion do
        ~s( FolioSustitucion="#{params.folio_sustitucion}")
      else
        ""
      end

    ~s(<?xml version="1.0" encoding="utf-8"?>
<Cancelacion xmlns="http://cancelacfd.sat.gob.mx"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             RfcEmisor="#{rfc_emisor}"
             Fecha="#{fecha}">
  <Folios>
    <Folio UUID="#{params.uuid}"
           Motivo="#{params.motivo}"#{folio_attr}/>
  </Folios>
  <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <SignedInfo>
      <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
      <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
      <Reference URI="">
        <Transforms>
          <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
        </Transforms>
        <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
        <DigestValue></DigestValue>
      </Reference>
    </SignedInfo>
    <SignatureValue>#{signature_value}</SignatureValue>
    <KeyInfo>
      <X509Data>
        <X509IssuerSerial>
          <X509SerialNumber>#{serial_number}</X509SerialNumber>
        </X509IssuerSerial>
        <X509Certificate>#{cert}</X509Certificate>
      </X509Data>
    </KeyInfo>
  </Signature>
</Cancelacion>)
  end

  @spec build_cancelar_request(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def build_cancelar_request(cancelacion_xml, token, cert, signature_value) do
    escaped = escape_xml_content(cancelacion_xml)

    ~s(<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
            xmlns:u="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  <s:Header>
    <o:Security xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                s:mustUnderstand="1">
      <u:Timestamp>
        <u:Created>#{token}</u:Created>
      </u:Timestamp>
      <o:BinarySecurityToken
        ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"
        EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">
        #{cert}
      </o:BinarySecurityToken>
    </o:Security>
  </s:Header>
  <s:Body>
    <CancelaCFD xmlns="http://tempuri.org/">
      <Cancelacion>#{escaped}</Cancelacion>
    </CancelaCFD>
  </s:Body>
</s:Envelope>)
  end

  defp escape_xml_content(xml) do
    xml
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  @spec parse_cancelar_response(String.t()) :: {:ok, CancelacionResult.t()} | {:error, String.t()}
  def parse_cancelar_response(xml) when is_binary(xml) do
    cond do
      String.contains?(xml, "<faultcode>") or String.contains?(xml, ":Fault>") ->
        {:error, "SOAP Fault: #{extract_tag(xml, "faultstring")}"}

      true ->
        folio_tag = extract_tag(xml, "Folio") || extract_tag(xml, "CancelaCFDResult")
        ctx = folio_tag || xml
        uuid = extract_attr(ctx, "UUID") || extract_attr(xml, "UUID")
        estatus_raw = extract_attr(ctx, "EstatusUUID") || extract_attr(xml, "EstatusUUID")
        cod = extract_attr(xml, "CodEstatus") || extract_tag(xml, "CodEstatus")
        mensaje = extract_attr(xml, "Mensaje") || extract_tag(xml, "Mensaje")

        estatus = map_estatus(estatus_raw)

        {:ok,
         %CancelacionResult{
           uuid: uuid,
           estatus: estatus,
           cod_estatus: cod,
           mensaje: mensaje
         }}
    end
  end

  defp map_estatus(raw) do
    case raw do
      "201" -> :cancelado
      "202" -> :en_proceso
      "Cancelado" -> :cancelado
      "EnProceso" -> :en_proceso
      _ -> :en_proceso
    end
  end

  defp extract_tag(xml, local) do
    re = ~r/<(?:[a-zA-Z0-9_]+:)?#{local}[^>]*>([\s\S]*?)<\/(?:[a-zA-Z0-9_]+:)?#{local}>/i

    case Regex.run(re, xml) do
      [_, inner] -> String.trim(inner)
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
