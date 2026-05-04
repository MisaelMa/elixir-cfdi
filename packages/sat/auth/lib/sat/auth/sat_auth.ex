defmodule Sat.Auth.SatAuth do
  @moduledoc """
  Posts a WS-Security signed `Autentica` envelope to the SAT *Descarga Masiva* auth endpoint.
  """

  alias Sat.Auth.TokenBuilder
  alias Sat.Auth.Types.SatToken
  alias Sat.Auth.XmlSigner

  @auth_url "https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/Autenticacion/Autenticacion.svc"
  @soap_action "http://DescargaMasivaTerceros.gob.mx/IAutenticacion/Autentica"

  @spec authenticate(Sat.Auth.Types.credential_like()) :: {:ok, SatToken.t()} | {:error, String.t()}
  def authenticate(%Cfdi.Csd.Credential{} = credential) do
    %{fragment: ts_frag, created: created_s, expires: expires_s} = TokenBuilder.build_timestamp_fragment()

    digest =
      ts_frag
      |> XmlSigner.canonicalize()
      |> XmlSigner.sha256_digest()

    signed_info =
      digest
      |> TokenBuilder.build_signed_info_fragment()
      |> XmlSigner.canonicalize()

    signature =
      XmlSigner.sign_rsa_sha256(
        signed_info,
        credential.private_key
      )

    cert_b64 = Cfdi.Csd.Certificate.to_base64(credential.certificate)
    token_id = "uuid-" <> random_uuid()

    envelope =
      TokenBuilder.build_auth_token(%{
        certificate_base64: cert_b64,
        created: created_s,
        expires: expires_s,
        digest: digest,
        signature: signature,
        token_id: token_id
      })

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    expires_dt = DateTime.add(now, 300, :second)

    case Req.post(@auth_url,
           headers: [
             {"content-type", "text/xml; charset=utf-8"},
             {"SOAPAction", @soap_action}
           ],
           body: envelope,
           receive_timeout: 60_000
         ) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        parse_token_response(body, now, expires_dt)

      {:ok, %{status: status, body: body}} ->
        {:error, "SAT auth HTTP #{status}: #{truncate(body)}"}

      {:error, reason} ->
        {:error, "SAT auth request failed: #{inspect(reason)}"}
    end
  end

  def authenticate(_), do: {:error, "credential must be a Cfdi.Csd.Credential struct"}

  defp parse_token_response(soap, %DateTime{} = created, %DateTime{} = expires) do
    cond do
      String.contains?(soap, "<AutenticaResult>") ->
        case Regex.run(~r/<AutenticaResult>([^<]+)<\/AutenticaResult>/i, soap) do
          [_, value] ->
            v = String.trim(value)
            if v != "", do: {:ok, %SatToken{value: v, created: created, expires: expires}}, else: {:error, "empty token"}

          _ ->
            alt(soap, created, expires)
        end

      true ->
        alt(soap, created, expires)
    end
  end

  defp alt(soap, created, expires) do
    case Regex.run(
           ~r/<[^:]*:?AutenticaResult[^>]*>([^<]+)<\/[^:]*:?AutenticaResult>/i,
           soap
         ) do
      [_, value] ->
        v = String.trim(value)
        if v != "", do: {:ok, %SatToken{value: v, created: created, expires: expires}}, else: {:error, "empty token"}

      _ ->
        {:error, "could not parse AutenticaResult: #{truncate(soap)}"}
    end
  end

  defp truncate(bin) when is_binary(bin), do: String.slice(bin, 0, 500)
  defp truncate(_), do: ""

  defp random_uuid do
    <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)
    c = Bitwise.bor(Bitwise.band(c, 0x0FFF), 0x4000)
    d = Bitwise.bor(Bitwise.band(d, 0x3FFF), 0x8000)

    :io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b", [a, b, c, d, e])
    |> IO.iodata_to_binary()
  end
end
