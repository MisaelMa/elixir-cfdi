defmodule Cfdi.Descarga.Soap.Descargar do
  @moduledoc false

  @spec build_descargar_request(String.t(), String.t(), String.t(), String.t(), String.t()) :: String.t()
  def build_descargar_request(id_paquete, rfc, token, cert, signature_value) do
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
    <des:PeticionDescargaMasivaTercerosEntrada>
      <des:peticionDescarga IdPaquete="#{id_paquete}"
                            RfcSolicitante="#{rfc}">
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
      </des:peticionDescarga>
    </des:PeticionDescargaMasivaTercerosEntrada>
  </s:Body>
</s:Envelope>)
  end

  @spec parse_descargar_response(String.t()) :: {:ok, binary()} | {:error, String.t()}
  def parse_descargar_response(xml) when is_binary(xml) do
    cond do
      String.contains?(xml, "<faultcode>") or String.contains?(xml, ":Fault>") ->
        {:error, "SOAP Fault: #{extract_tag(xml, "faultstring")}"}

      true ->
        paquete =
          extract_tag(xml, "Paquete") ||
            extract_tag(xml, "RespuestaDescargaMasivaTercerosSalida")

        if paquete == "" do
          {:error, "response missing Paquete element"}
        else
          clean = String.replace(paquete, ~r/\s+/, "")

          case Base.decode64(clean) do
            {:ok, bin} -> {:ok, bin}
            :error -> {:error, "invalid Base64 in Paquete"}
          end
        end
    end
  end

  defp extract_tag(xml, local) do
    re = ~r/<(?:[a-zA-Z0-9_]+:)?#{local}[^>]*>([\s\S]*?)<\/(?:[a-zA-Z0-9_]+:)?#{local}>/i

    case Regex.run(re, xml) do
      [_, inner] -> String.trim(inner)
      _ -> ""
    end
  end
end
