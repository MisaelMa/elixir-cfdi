defmodule Sat.PortalCfdi.Internal.Saml do
  @moduledoc false
  # Construye el `wresult` (SAML 1.1 RequestSecurityTokenResponse) firmado
  # con FIEL para autenticarse contra el IDP NetIQ del SAT
  # (`cfdiau.sat.gob.mx`).
  #
  # El flujo del portal con FIEL es:
  #   1. GET a `cfdiau.sat.gob.mx/nidp/app/login?id=SATx509Custom&...`
  #      -> obtiene un `tokenUuid` y un `tokenForm` con un nonce.
  #   2. Genera un assertion SAML/WS-Federation firmando con FIEL,
  #      incluyendo el nonce del paso 1.
  #   3. POST a la URL del callback con el assertion en `wresult`.
  #
  # Esta implementacion es un esqueleto: el formato exacto del XML y el
  # manejo del nonce dependen de la version del IDP que el SAT tenga
  # desplegada (cambia ~1-2 veces por anio).

  alias Sat.Certificados.Credential

  @ns_dsig "http://www.w3.org/2000/09/xmldsig#"
  @ns_excc14n "http://www.w3.org/2001/10/xml-exc-c14n#"

  @doc """
  Construye un `wresult` SAML 1.1 firmado con FIEL.

  Opciones:
    * `:issuer` (requerido) — URI del issuer (e.g. del IDP)
    * `:audience` (requerido) — URI del relying party
    * `:nonce` — nonce o token UUID extraido del paso 1 (opcional)
    * `:now` — DateTime fijo (testing)
  """
  @spec build_wresult(Credential.t(), keyword()) :: String.t()
  def build_wresult(%Credential{} = cred, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    issuer = Keyword.fetch!(opts, :issuer)
    audience = Keyword.fetch!(opts, :audience)
    nonce = Keyword.get(opts, :nonce, generate_uuid())
    rfc = Credential.rfc(cred)

    not_before = format_datetime(now)
    not_on_or_after = format_datetime(DateTime.add(now, 300, :second))
    assertion_id = "_" <> nonce

    assertion =
      build_assertion(assertion_id, rfc, issuer, audience, not_before, not_on_or_after)

    # Hash y firma del assertion (usando enveloped signature pattern)
    digest = sha1_base64(assertion)
    signed_info = build_signed_info(assertion_id, digest)
    signature_value = sign(signed_info, cred)
    key_info = build_key_info(cred)
    signature = build_signature(signed_info, signature_value, key_info)

    # El assertion firmado se inserta dentro del envelope wresult
    signed_assertion = inject_signature(assertion, signature)

    wresult_xml(signed_assertion, audience, now)
  end

  defp build_assertion(id, rfc, issuer, audience, not_before, not_on_or_after) do
    ~s|<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" | <>
      ~s|MajorVersion="1" MinorVersion="1" | <>
      ~s|AssertionID="#{id}" | <>
      ~s|Issuer="#{issuer}" | <>
      ~s|IssueInstant="#{not_before}">| <>
      ~s|<saml:Conditions NotBefore="#{not_before}" NotOnOrAfter="#{not_on_or_after}">| <>
      ~s|<saml:AudienceRestrictionCondition><saml:Audience>#{audience}</saml:Audience></saml:AudienceRestrictionCondition>| <>
      ~s|</saml:Conditions>| <>
      ~s|<saml:AuthenticationStatement AuthenticationMethod="urn:oasis:names:tc:SAML:1.0:am:X509-PKI" AuthenticationInstant="#{not_before}">| <>
      ~s|<saml:Subject>| <>
      ~s|<saml:NameIdentifier Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">#{rfc}</saml:NameIdentifier>| <>
      ~s|<saml:SubjectConfirmation><saml:ConfirmationMethod>urn:oasis:names:tc:SAML:1.0:cm:holder-of-key</saml:ConfirmationMethod></saml:SubjectConfirmation>| <>
      ~s|</saml:Subject>| <>
      ~s|</saml:AuthenticationStatement>| <>
      ~s|</saml:Assertion>|
  end

  defp build_signed_info(reference_id, digest_b64) do
    ~s|<SignedInfo xmlns="#{@ns_dsig}">| <>
      ~s|<CanonicalizationMethod Algorithm="#{@ns_excc14n}"></CanonicalizationMethod>| <>
      ~s|<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"></SignatureMethod>| <>
      ~s|<Reference URI="##{reference_id}">| <>
      ~s|<Transforms>| <>
      ~s|<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></Transform>| <>
      ~s|<Transform Algorithm="#{@ns_excc14n}"></Transform>| <>
      ~s|</Transforms>| <>
      ~s|<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"></DigestMethod>| <>
      ~s|<DigestValue>#{digest_b64}</DigestValue>| <>
      ~s|</Reference></SignedInfo>|
  end

  defp build_signature(signed_info, value, key_info) do
    ~s|<Signature xmlns="#{@ns_dsig}">| <>
      signed_info <>
      ~s|<SignatureValue>#{value}</SignatureValue>| <>
      key_info <>
      ~s|</Signature>|
  end

  defp build_key_info(%Credential{certificate: cert}) do
    cer_b64 = cert |> Sat.Certificados.Certificate.to_der() |> Base.encode64()

    ~s|<KeyInfo xmlns="#{@ns_dsig}">| <>
      ~s|<X509Data><X509Certificate>#{cer_b64}</X509Certificate></X509Data>| <>
      ~s|</KeyInfo>|
  end

  defp inject_signature(assertion, signature) do
    # Inyectar la firma justo despues del primer hijo del root
    # (el SAT espera enveloped-signature inmediatamente despues de Conditions).
    String.replace(assertion, "</saml:Subject>", "</saml:Subject>" <> signature, global: false)
  end

  defp wresult_xml(signed_assertion, audience, now) do
    issued = format_datetime(now)
    expires = format_datetime(DateTime.add(now, 300, :second))

    ~s|<t:RequestSecurityTokenResponse | <>
      ~s|xmlns:t="http://schemas.xmlsoap.org/ws/2005/02/trust">| <>
      ~s|<t:Lifetime>| <>
      ~s|<wsu:Created xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">#{issued}</wsu:Created>| <>
      ~s|<wsu:Expires xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">#{expires}</wsu:Expires>| <>
      ~s|</t:Lifetime>| <>
      ~s|<wsp:AppliesTo xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy">| <>
      ~s|<wsa:EndpointReference xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing">| <>
      ~s|<wsa:Address>#{audience}</wsa:Address>| <>
      ~s|</wsa:EndpointReference>| <>
      ~s|</wsp:AppliesTo>| <>
      ~s|<t:RequestedSecurityToken>| <>
      signed_assertion <>
      ~s|</t:RequestedSecurityToken>| <>
      ~s|<t:TokenType>urn:oasis:names:tc:SAML:1.0:assertion</t:TokenType>| <>
      ~s|<t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType>| <>
      ~s|<t:KeyType>http://schemas.xmlsoap.org/ws/2005/05/identity/NoProofKey</t:KeyType>| <>
      ~s|</t:RequestSecurityTokenResponse>|
  end

  defp sign(signed_info, %Credential{} = cred), do: Credential.sign(cred, signed_info, :sha)

  defp sha1_base64(iodata), do: :crypto.hash(:sha, iodata) |> Base.encode64()

  defp format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp generate_uuid do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end
end
