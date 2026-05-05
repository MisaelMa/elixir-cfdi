defmodule CFDI.CertificarSellarTest do
  use ExUnit.Case, async: true

  alias Cfdi.{Comprobante, Emisor, Receptor}
  alias Sat.Certificados.{Certificate, Credential}

  @certs_dir Path.expand("../../../files/certificados", __DIR__)
  @csd_cer Path.join(@certs_dir, "LAN7008173R5.cer")
  @csd_key Path.join(@certs_dir, "LAN7008173R5.key")
  @csd_password "12345678a"

  defp build_comprobante do
    %Comprobante{}
    |> Comprobante.add_emisor(%Emisor{
      Rfc: "LAN7008173R5",
      Nombre: "CINDEMEX SA DE CV",
      RegimenFiscal: "601"
    })
    |> Comprobante.add_receptor(%Receptor{
      Rfc: "CACX7605101P8",
      Nombre: "XOCHILT CASAS CHAVEZ",
      UsoCFDI: "G03",
      DomicilioFiscalReceptor: "36257",
      RegimenFiscalReceptor: "612"
    })
  end

  defp load_credential! do
    {:ok, cred} = Credential.create(@csd_cer, @csd_key, @csd_password)
    cred
  end

  describe "certificar/2" do
    test "asocia Certificado y NoCertificado tomados de la %Credential{}" do
      cred = load_credential!()

      {:ok, c} =
        build_comprobante()
        |> CFDI.new()
        |> CFDI.certificar(cred)

      assert Map.fetch!(c.comprobante, :Certificado) == Certificate.to_base64(cred.certificate)
      assert Map.fetch!(c.comprobante, :NoCertificado) == Credential.no_certificado(cred)
      assert c.config[:credential] == cred
    end

    test "rechaza un map plano (forma legacy)" do
      c = CFDI.new(build_comprobante())

      assert {:error, :credential_must_be_credential_struct} =
               CFDI.certificar(c, %{certificado: "x", no_certificado: "y"})
    end

    test "rechaza nil y otros tipos no-Credential" do
      c = CFDI.new(build_comprobante())

      assert {:error, :credential_must_be_credential_struct} = CFDI.certificar(c, nil)
      assert {:error, :credential_must_be_credential_struct} = CFDI.certificar(c, "string")
      assert {:error, :credential_must_be_credential_struct} = CFDI.certificar(c, 42)
    end
  end

  describe "sellar/1" do
    test "produce un Sello base64 verificable contra la cadena original" do
      cred = load_credential!()

      cadena =
        "||4.0|A|123|2024-01-01T00:00:00|01|G03|MXN|100|2024|" <>
          "LAN7008173R5|CINDEMEX SA DE CV|601|" <>
          "CACX7605101P8|XOCHILT CASAS CHAVEZ|612|G03|36257||"

      {:ok, c} =
        build_comprobante()
        |> CFDI.new()
        |> CFDI.certificar(cred)

      c = %{c | config: Map.put(c.config, :cadena, cadena)}

      assert {:ok, sealed} = CFDI.sellar(c)
      sello = Map.fetch!(sealed.comprobante, :Sello)

      assert is_binary(sello)
      assert {:ok, _decoded} = Base.decode64(sello)
      assert Credential.verify(cred, cadena, sello)
    end

    test "retorna :missing_cadena cuando config no contiene la cadena" do
      cred = load_credential!()

      {:ok, c} =
        build_comprobante()
        |> CFDI.new()
        |> CFDI.certificar(cred)

      assert {:error, :missing_cadena} = CFDI.sellar(c)
    end

    test "retorna :missing_credential cuando no se llamó certificar antes" do
      c =
        build_comprobante()
        |> CFDI.new()

      c = %{c | config: Map.put(c.config, :cadena, "cadena_de_prueba")}

      assert {:error, :missing_credential} = CFDI.sellar(c)
    end
  end
end
