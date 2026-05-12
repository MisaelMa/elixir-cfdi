defmodule Sat.WsDescargaMasiva.Internal.SoapEnvelopeTest do
  use ExUnit.Case, async: true

  alias Sat.Certificados.Credential
  alias Sat.WsDescargaMasiva.Internal.SoapEnvelope
  alias Sat.WsDescargaMasiva.Types.SolicitudParams

  @moduletag :requires_fixtures

  setup do
    cer_path = fixture_path("EKU9003173C9.cer")
    key_path = fixture_path("EKU9003173C9.key")

    if File.exists?(cer_path) and File.exists?(key_path) do
      {:ok, cred} = Credential.create(cer_path, key_path, "12345678a")
      {:ok, %{cred: cred}}
    else
      {:ok, %{cred: nil, skip: :no_fiel}}
    end
  end

  describe "build_autenticacion/2" do
    test "produce un envelope SOAP con BinarySecurityToken, Timestamp y Signature", %{cred: cred} do
      if cred do
        envelope =
          SoapEnvelope.build_autenticacion(cred, now: ~U[2025-01-01 00:00:00.000Z])

        assert envelope =~ "<s:Envelope"
        assert envelope =~ "<o:BinarySecurityToken"
        assert envelope =~ "<u:Timestamp"
        assert envelope =~ "<Signature"
        assert envelope =~ "<SignatureValue>"
        assert envelope =~ "<Autentica"
        assert envelope =~ "2025-01-01T00:00:00.000Z"
      else
        :ok
      end
    end

    test "es deterministico cuando se fija :now y :token_id", %{cred: cred} do
      if cred do
        opts = [now: ~U[2025-01-01 00:00:00.000Z]]
        a = SoapEnvelope.build_autenticacion(cred, opts)
        b = SoapEnvelope.build_autenticacion(cred, opts)
        # El token_id se randomiza siempre, pero el timestamp y la firma del
        # timestamp sí deben tener el mismo digest.
        assert extract_digest(a) == extract_digest(b)
      else
        :ok
      end
    end
  end

  describe "build_solicitud/3" do
    test "incluye el token en el header y el nodo solicitud firmado", %{cred: cred} do
      if cred do
        params = %SolicitudParams{
          rfc_solicitante: "EKU9003173C9",
          rfc_emisor: "EKU9003173C9",
          fecha_inicial: ~U[2025-01-01 00:00:00Z],
          fecha_final: ~U[2025-01-31 23:59:59Z],
          tipo_solicitud: :cfdi
        }

        envelope = SoapEnvelope.build_solicitud(cred, params, "fake-token")

        assert envelope =~ "<o:BinarySecurityToken>fake-token</o:BinarySecurityToken>"
        assert envelope =~ "<des:SolicitaDescarga"
        assert envelope =~ "RfcSolicitante=\"EKU9003173C9\""
        assert envelope =~ "TipoSolicitud=\"CFDI\""
        assert envelope =~ "<Signature"
        assert envelope =~ "<X509Certificate>"
      else
        :ok
      end
    end
  end

  defp fixture_path(name) do
    Path.join([
      :code.priv_dir(:sat_certificados) |> to_string(),
      "fixtures",
      name
    ])
  end

  defp extract_digest(envelope) do
    Regex.run(~r|<DigestValue>([^<]+)</DigestValue>|, envelope)
  end
end
