defmodule Cfdi.Cancelacion.Soap.AceptacionRechazo do
  @moduledoc false

  alias Cfdi.Cancelacion.Types.{
    AceptacionRechazoParams,
    AceptacionRechazoResult,
    PendientesResult
  }

  @spec build_aceptacion_rechazo_request(
          AceptacionRechazoParams.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: String.t()
  def build_aceptacion_rechazo_request(params, token, cert, signature_value, fecha) do
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
    <ProcesarRespuesta xmlns="http://cancelacfd.sat.gob.mx/">
      <RfcReceptor>#{params.rfc_receptor}</RfcReceptor>
      <UUID>#{params.uuid}</UUID>
      <Respuesta>#{params.respuesta}</Respuesta>
      <Fecha>#{fecha}</Fecha>
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
            <X509Certificate>#{cert}</X509Certificate>
          </X509Data>
        </KeyInfo>
      </Signature>
    </ProcesarRespuesta>
  </s:Body>
</s:Envelope>)
  end

  @spec build_consulta_pendientes_request(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def build_consulta_pendientes_request(rfc_receptor, token, cert, signature_value) do
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
    <ConsultaPendientes xmlns="http://cancelacfd.sat.gob.mx/">
      <RfcReceptor>#{rfc_receptor}</RfcReceptor>
    </ConsultaPendientes>
  </s:Body>
</s:Envelope>)
  end

  @spec parse_aceptacion_rechazo_response(String.t()) ::
          {:ok, AceptacionRechazoResult.t()} | {:error, String.t()}
  def parse_aceptacion_rechazo_response(xml) when is_binary(xml) do
    cond do
      String.contains?(xml, "<faultcode>") or String.contains?(xml, ":Fault>") ->
        {:error, "SOAP Fault: #{extract_tag(xml, "faultstring")}"}

      true ->
        uuid = extract_attr(xml, "UUID") || extract_tag(xml, "UUID")
        cod = extract_attr(xml, "CodEstatus") || extract_tag(xml, "CodEstatus")
        mensaje = extract_attr(xml, "Mensaje") || extract_tag(xml, "Mensaje")

        {:ok, %AceptacionRechazoResult{uuid: uuid, cod_estatus: cod, mensaje: mensaje}}
    end
  end

  @spec parse_consulta_pendientes_response(String.t()) ::
          {:ok, [PendientesResult.t()]} | {:error, String.t()}
  def parse_consulta_pendientes_response(xml) when is_binary(xml) do
    cond do
      String.contains?(xml, "<faultcode>") or String.contains?(xml, ":Fault>") ->
        {:error, "SOAP Fault: #{extract_tag(xml, "faultstring")}"}

      true ->
        {:ok, collect_uuids(xml)}
    end
  end

  defp collect_uuids(xml) do
    re = ~r/<(?:[a-zA-Z0-9_]+:)?UUID[^>]*>([^<]+)<\/(?:[a-zA-Z0-9_]+:)?UUID>/i

    {_, acc} =
      Regex.scan(re, xml)
      |> Enum.reduce({0, []}, fn [whole, uuid_val], {start_pos, acc} ->
        rest = binary_part(xml, start_pos, byte_size(xml) - start_pos)

        case :binary.match(rest, whole) do
          {local_idx, len} ->
            idx = start_pos + local_idx
            block_start = max(0, idx - 500)
            block = String.slice(xml, block_start, 1000)

            item = %PendientesResult{
              uuid: String.trim(uuid_val),
              rfc_emisor: extract_tag(block, "RfcEmisor") || extract_attr(block, "RfcEmisor"),
              fecha_solicitud:
                extract_tag(block, "FechaSolicitud") || extract_attr(block, "FechaSolicitud")
            }

            {idx + len, [item | acc]}

          :nomatch ->
            {start_pos, acc}
        end
      end)

    Enum.reverse(acc)
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
