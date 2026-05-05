defmodule Cfdi.Descarga.Soap.Signer do
  @moduledoc false

  defmodule SoapSignatureComponents do
    @moduledoc false
    defstruct [:body_digest, :signature_value, :x509_certificate, :body_id]

    @type t :: %__MODULE__{
            body_digest: String.t(),
            signature_value: String.t(),
            x509_certificate: String.t(),
            body_id: String.t()
          }
  end

  @doc """
  Strips an optional XML declaration and trims (SAT descarga masiva signing).
  """
  @spec canonicalize(String.t()) :: String.t()
  def canonicalize(xml) when is_binary(xml) do
    xml
    |> String.replace(~r/<\?xml[^?]*\?>\s*/, "")
    |> String.trim()
  end

  @spec digest_sha256(String.t()) :: String.t()
  def digest_sha256(content) do
    content
    |> :crypto.hash(:sha256)
    |> Base.encode64()
  end

  @doc """
  Signs the WS-Security `SignedInfo` for the SOAP body (digest of canonical `body_xml`).
  """
  @spec sign_soap_body(String.t(), Sat.Certificados.Credential.t()) :: SoapSignatureComponents.t()
  def sign_soap_body(body_xml, %Sat.Certificados.Credential{} = credential) do
    sign_soap_body(body_xml, credential, "_0")
  end

  @spec sign_soap_body(String.t(), Sat.Certificados.Credential.t(), String.t()) :: SoapSignatureComponents.t()
  def sign_soap_body(body_xml, %Sat.Certificados.Credential{} = credential, body_id) do
    canon = canonicalize(body_xml)
    body_digest = digest_sha256(canon)
    signed_info = build_signed_info(body_digest, body_id)
    canon_signed = canonicalize(signed_info)
    signature_value = Sat.Certificados.Credential.sign(credential, canon_signed)

    pem = Sat.Certificados.Certificate.to_pem(credential.certificate)

    x509 =
      pem
      |> String.replace("-----BEGIN CERTIFICATE-----", "")
      |> String.replace("-----END CERTIFICATE-----", "")
      |> String.replace(~r/\s+/, "")

    %SoapSignatureComponents{
      body_digest: body_digest,
      signature_value: signature_value,
      x509_certificate: x509,
      body_id: body_id
    }
  end

  defp build_signed_info(body_digest, body_id) do
    "<ds:SignedInfo xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">" <>
      "<ds:CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
      "<ds:SignatureMethod Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256\"/>" <>
      "<ds:Reference URI=\"##{body_id}\">" <>
      "<ds:Transforms>" <>
      "<ds:Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
      "</ds:Transforms>" <>
      "<ds:DigestMethod Algorithm=\"http://www.w3.org/2001/04/xmlenc#sha256\"/>" <>
      "<ds:DigestValue>#{body_digest}</ds:DigestValue>" <>
      "</ds:Reference>" <>
      "</ds:SignedInfo>"
  end

  @spec build_security_header(SoapSignatureComponents.t(), String.t()) :: String.t()
  def build_security_header(%SoapSignatureComponents{} = c, token_value) do
    signed_info = build_signed_info(c.body_digest, c.body_id)

    "<s:Header>\n" <>
      "  <h:Security xmlns:h=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"\n" <>
      "              xmlns:u=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">\n" <>
      "    <u:Timestamp>\n" <>
      "      <u:Created>#{token_value}</u:Created>\n" <>
      "    </u:Timestamp>\n" <>
      "    <ds:Signature xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">\n" <>
      "      #{signed_info}\n" <>
      "      <ds:SignatureValue>#{c.signature_value}</ds:SignatureValue>\n" <>
      "      <ds:KeyInfo>\n" <>
      "        <o:SecurityTokenReference xmlns:o=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\">\n" <>
      "          <o:KeyIdentifier ValueType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3SubjectKeyIdentifier\"\n" <>
      "                           EncodingType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary\">\n" <>
      "            #{String.slice(c.x509_certificate, 0, 40)}\n" <>
      "          </o:KeyIdentifier>\n" <>
      "        </o:SecurityTokenReference>\n" <>
      "      </ds:KeyInfo>\n" <>
      "    </ds:Signature>\n" <>
      "  </h:Security>\n" <>
      "</s:Header>"
  end
end
