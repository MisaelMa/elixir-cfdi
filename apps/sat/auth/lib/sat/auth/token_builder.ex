defmodule Sat.Auth.TokenBuilder do
  @moduledoc false

  @doc """
  Builds the `u:Timestamp` fragment and ISO8601 `created` / `expires` (UTC, +5 minutes).
  """
  @spec build_timestamp_fragment() :: %{
          fragment: String.t(),
          created: String.t(),
          expires: String.t()
        }
  def build_timestamp_fragment do
    now = DateTime.utc_now() |> DateTime.truncate(:millisecond)
    expires = DateTime.add(now, 300, :second)
    created = to_iso_ms(now)
    expires_s = to_iso_ms(expires)

    fragment =
      "<u:Timestamp xmlns:u=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\" u:Id=\"_0\">" <>
        "<u:Created>#{created}</u:Created>" <>
        "<u:Expires>#{expires_s}</u:Expires>" <>
        "</u:Timestamp>"

    %{fragment: fragment, created: created, expires: expires_s}
  end

  @doc """
  `digest` is Base64 SHA-256 of the canonicalized timestamp fragment.
  """
  @spec build_signed_info_fragment(String.t()) :: String.t()
  def build_signed_info_fragment(digest) when is_binary(digest) do
    "<SignedInfo xmlns=\"http://www.w3.org/2000/09/xmldsig#\">" <>
      "<CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
      "<SignatureMethod Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256\"/>" <>
      "<Reference URI=\"#_0\">" <>
      "<Transforms>" <>
      "<Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
      "</Transforms>" <>
      "<DigestMethod Algorithm=\"http://www.w3.org/2001/04/xmlenc#sha256\"/>" <>
      "<DigestValue>#{digest}</DigestValue>" <>
      "</Reference>" <>
      "</SignedInfo>"
  end

  @doc """
  Params: `:certificate_base64`, `:created`, `:expires`, `:digest`, `:signature`, `:token_id`.
  """
  @spec build_auth_token(map()) :: String.t()
  def build_auth_token(%{} = p) do
    cert = Map.fetch!(p, :certificate_base64)
    created = Map.fetch!(p, :created)
    expires = Map.fetch!(p, :expires)
    digest = Map.fetch!(p, :digest)
    signature = Map.fetch!(p, :signature)
    token_id = Map.fetch!(p, :token_id)

    "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:u=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\">" <>
      "<s:Header>" <>
      "<o:Security xmlns:o=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\" s:mustUnderstand=\"1\">" <>
      "<u:Timestamp u:Id=\"_0\">" <>
      "<u:Created>#{created}</u:Created>" <>
      "<u:Expires>#{expires}</u:Expires>" <>
      "</u:Timestamp>" <>
      "<o:BinarySecurityToken u:Id=\"#{token_id}\" ValueType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3\" EncodingType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary\">#{cert}</o:BinarySecurityToken>" <>
      "<Signature xmlns=\"http://www.w3.org/2000/09/xmldsig#\">" <>
      "<SignedInfo>" <>
      "<CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
      "<SignatureMethod Algorithm=\"http://www.w3.org/2001/04/xmldsig-more#rsa-sha256\"/>" <>
      "<Reference URI=\"#_0\">" <>
      "<Transforms>" <>
      "<Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
      "</Transforms>" <>
      "<DigestMethod Algorithm=\"http://www.w3.org/2001/04/xmlenc#sha256\"/>" <>
      "<DigestValue>#{digest}</DigestValue>" <>
      "</Reference>" <>
      "</SignedInfo>" <>
      "<SignatureValue>#{signature}</SignatureValue>" <>
      "<KeyInfo>" <>
      "<o:SecurityTokenReference>" <>
      "<o:Reference ValueType=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3\" URI=\"##{token_id}\"/>" <>
      "</o:SecurityTokenReference>" <>
      "</KeyInfo>" <>
      "</Signature>" <>
      "</o:Security>" <>
      "</s:Header>" <>
      "<s:Body>" <>
      "<Autentica xmlns=\"http://DescargaMasivaTerceros.gob.mx\"/>" <>
      "</s:Body>" <>
      "</s:Envelope>"
  end

  defp to_iso_ms(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%dT%H:%M:%S.%L") <> "Z"
  end
end
