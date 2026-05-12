defmodule Sat.PortalCfdi.Internal.SamlTest do
  use ExUnit.Case, async: true

  alias Sat.Certificados.Credential
  alias Sat.PortalCfdi.Internal.Saml

  @moduletag :requires_fixtures

  setup do
    cer_path = fixture_path("EKU9003173C9.cer")
    key_path = fixture_path("EKU9003173C9.key")

    if File.exists?(cer_path) and File.exists?(key_path) do
      {:ok, cred} = Credential.create(cer_path, key_path, "12345678a")
      {:ok, %{cred: cred}}
    else
      {:ok, %{cred: nil}}
    end
  end

  describe "build_wresult/2" do
    test "produce un wresult con Assertion firmado", %{cred: cred} do
      if cred do
        wresult =
          Saml.build_wresult(cred,
            issuer: "test-issuer",
            audience: "https://portal.example",
            now: ~U[2025-01-01 00:00:00Z]
          )

        assert wresult =~ "<t:RequestSecurityTokenResponse"
        assert wresult =~ "<saml:Assertion"
        assert wresult =~ "<Signature"
        assert wresult =~ "<SignatureValue>"
        assert wresult =~ "<X509Certificate>"
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
end
