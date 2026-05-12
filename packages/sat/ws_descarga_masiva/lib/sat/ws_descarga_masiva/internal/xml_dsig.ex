defmodule Sat.WsDescargaMasiva.Internal.XmlDsig do
  @moduledoc false
  # Construccion de elementos XMLDSig (`SignedInfo`, `Signature`, `KeyInfo`)
  # en forma pre-canonica.
  #
  # El WS de Descarga Masiva del SAT usa:
  #   * CanonicalizationMethod: http://www.w3.org/2001/10/xml-exc-c14n#
  #   * SignatureMethod:        http://www.w3.org/2000/09/xmldsig#rsa-sha1
  #   * DigestMethod:           http://www.w3.org/2000/09/xmldsig#sha1
  #
  # Construimos los XMLs ya en forma canonica (sin espacios, atributos
  # ordenados, namespaces declarados localmente) para evitar tener que
  # canonicalizar despues con un parser externo.

  alias Sat.Certificados.{Credential, PrivateKey}
  alias Sat.WsDescargaMasiva.Internal.X509Info

  @ns_dsig "http://www.w3.org/2000/09/xmldsig#"
  @ns_excc14n "http://www.w3.org/2001/10/xml-exc-c14n#"
  @sig_rsa_sha1 "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
  @digest_sha1 "http://www.w3.org/2000/09/xmldsig#sha1"
  @value_type_x509v3 "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"
  @encoding_base64binary "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"

  @doc """
  Hash SHA-1 + Base64 (DigestValue para XMLDSig).
  """
  @spec sha1_base64(iodata()) :: String.t()
  def sha1_base64(iodata) do
    :crypto.hash(:sha, iodata) |> Base.encode64()
  end

  @doc """
  Construye `<SignedInfo>` ya canonicalizado sobre un fragmento referenciado
  por URI (`#id`).
  """
  @spec build_signed_info(String.t(), String.t()) :: String.t()
  def build_signed_info(reference_id, digest_value_b64)
      when is_binary(reference_id) and is_binary(digest_value_b64) do
    ~s|<SignedInfo xmlns="#{@ns_dsig}">| <>
      ~s|<CanonicalizationMethod Algorithm="#{@ns_excc14n}"></CanonicalizationMethod>| <>
      ~s|<SignatureMethod Algorithm="#{@sig_rsa_sha1}"></SignatureMethod>| <>
      ~s|<Reference URI="##{reference_id}">| <>
      ~s|<Transforms><Transform Algorithm="#{@ns_excc14n}"></Transform></Transforms>| <>
      ~s|<DigestMethod Algorithm="#{@digest_sha1}"></DigestMethod>| <>
      ~s|<DigestValue>#{digest_value_b64}</DigestValue>| <>
      ~s|</Reference></SignedInfo>|
  end

  @doc """
  Firma `SignedInfo` con la llave privada (RSA-SHA1, base64).
  """
  @spec sign_signed_info(String.t(), Credential.t()) :: String.t()
  def sign_signed_info(signed_info, %Credential{private_key: pk}) when is_binary(signed_info) do
    PrivateKey.sign(pk, signed_info, :sha)
  end

  @doc """
  Construye `<KeyInfo>` con `X509IssuerSerial` + `X509Certificate` (DER b64).
  """
  @spec build_key_info_x509(Credential.t()) :: String.t()
  def build_key_info_x509(%Credential{certificate: cert}) do
    issuer = X509Info.issuer_name(cert)
    serial = X509Info.serial_number_decimal(cert)
    cer_b64 = X509Info.der_base64(cert)

    ~s|<KeyInfo>| <>
      ~s|<X509Data>| <>
      ~s|<X509IssuerSerial>| <>
      ~s|<X509IssuerName>#{issuer}</X509IssuerName>| <>
      ~s|<X509SerialNumber>#{serial}</X509SerialNumber>| <>
      ~s|</X509IssuerSerial>| <>
      ~s|<X509Certificate>#{cer_b64}</X509Certificate>| <>
      ~s|</X509Data>| <>
      ~s|</KeyInfo>|
  end

  @doc """
  Construye `<KeyInfo>` que apunta a un `BinarySecurityToken` ya incluido
  en el `Security` header del SOAP (modo wss:SecurityTokenReference).
  """
  @spec build_key_info_str(String.t()) :: String.t()
  def build_key_info_str(token_id) when is_binary(token_id) do
    ~s|<KeyInfo xmlns:o="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">| <>
      ~s|<o:SecurityTokenReference>| <>
      ~s|<o:Reference URI="##{token_id}" ValueType="#{@value_type_x509v3}"/>| <>
      ~s|</o:SecurityTokenReference>| <>
      ~s|</KeyInfo>|
  end

  @doc """
  Construye `<Signature>` completo combinando SignedInfo + SignatureValue + KeyInfo.
  """
  @spec build_signature(String.t(), String.t(), String.t()) :: String.t()
  def build_signature(signed_info, signature_value_b64, key_info)
      when is_binary(signed_info) and is_binary(signature_value_b64) and is_binary(key_info) do
    ~s|<Signature xmlns="#{@ns_dsig}">| <>
      signed_info <>
      ~s|<SignatureValue>#{signature_value_b64}</SignatureValue>| <>
      key_info <>
      ~s|</Signature>|
  end

  @doc """
  Construye `<o:BinarySecurityToken>` con el certificado DER en base64.
  """
  @spec build_binary_security_token(Credential.t(), String.t()) :: String.t()
  def build_binary_security_token(%Credential{certificate: cert}, token_id)
      when is_binary(token_id) do
    cer_b64 = X509Info.der_base64(cert)

    ~s|<o:BinarySecurityToken | <>
      ~s|u:Id="#{token_id}" | <>
      ~s|ValueType="#{@value_type_x509v3}" | <>
      ~s|EncodingType="#{@encoding_base64binary}">| <>
      cer_b64 <>
      ~s|</o:BinarySecurityToken>|
  end

  @doc "Algoritmos publicos (para introspeccion / tests)."
  def algorithms,
    do: %{
      canonicalization: @ns_excc14n,
      signature: @sig_rsa_sha1,
      digest: @digest_sha1,
      value_type_x509v3: @value_type_x509v3,
      encoding_base64binary: @encoding_base64binary,
      ns_dsig: @ns_dsig
    }
end
