defmodule Cfdi.InfoCertificadosTest do
  @moduledoc """
  Test "informativo": carga un CSD y un FIEL y los imprime en pantalla con
  toda la información extraíble. No es para validar lógica — es para que el
  desarrollador vea qué datos expone cada certificado.

  Ejecutar:

      mix test test/info_certificados_test.exs --trace
  """

  use ExUnit.Case, async: false

  alias Cfdi.Csd.{Certificate, Credential, PrivateKey}

  @files_dir Path.expand("../../../files/certificados", __DIR__)

  @csd %{
    label: "CSD (Certificado de Sello Digital)",
    cer: Path.join(@files_dir, "LAN7008173R5.cer"),
    key: Path.join(@files_dir, "LAN7008173R5.key"),
    password: "12345678a"
  }

  @fiel %{
    label: "FIEL / e.firma",
    cer: Path.join([@files_dir, "efirma", "goodCertificate.cer"]),
    key: Path.join([@files_dir, "efirma", "goodPrivateKeyEncrypt.key"]),
    password: "12345678a"
  }

  describe "información de un CSD" do
    test "imprime y valida los datos del CSD #{Path.basename(@csd.cer)}" do
      print_certificado(@csd)

      {:ok, cert} = Certificate.from_file(@csd.cer)
      {:ok, key} = PrivateKey.from_file(@csd.key, @csd.password)
      {:ok, cred} = Credential.create(@csd.cer, @csd.key, @csd.password)

      assert Certificate.rfc(cert) == "LAN7008173R5"
      assert Certificate.legal_name(cert) == "CINDEMEX SA DE CV"
      assert Certificate.subject_type(cert) == :moral
      assert Certificate.certificate_type(cert) == :csd
      assert Certificate.is_csd?(cert)
      refute Certificate.is_fiel?(cert)

      assert Certificate.no_certificado(cert) == "20001000000300022815"
      assert Certificate.ac_version(cert) == 3

      assert Certificate.valid_from(cert) == ~U[2016-10-25 21:52:11Z]
      assert Certificate.valid_to(cert) == ~U[2020-10-25 21:52:11Z]
      assert Certificate.expired?(cert)
      refute Certificate.valid?(cert)

      assert Certificate.fingerprint(cert) ==
               "D5:D8:CA:9E:E7:29:71:0F:0C:BC:4A:F2:80:8B:F0:CF:3E:8F:35:43"

      assert Certificate.fingerprint_sha256(cert) ==
               "83BDC4B0E315A70EFBB99E6E3B194F2F8AAAB74647BD162B463CCB387839AD08"

      sub = Certificate.subject(cert)
      assert sub["CN"] == "CINDEMEX SA DE CV"
      assert sub["O"] == "CINDEMEX SA DE CV"
      assert sub["OU"] == "Prueba_CFDI"
      assert sub["x500UniqueIdentifier"] =~ "LAN7008173R5"

      iss = Certificate.issuer(cert)
      assert iss["C"] == "MX"
      assert iss["O"] == "Servicio de Administración Tributaria"
      assert iss["x500UniqueIdentifier"] == "SAT970701NN3"

      {:RSAPublicKey, modulus, exponent} = Certificate.public_key(cert)
      assert bit_length(modulus) == 2048
      assert exponent == 65_537

      assert PrivateKey.belongs_to_certificate?(key, cert)
      assert Credential.key_matches_certificate?(cred)

      sello = Credential.sign(cred, "||cadena|original||")
      assert Credential.verify(cred, "||cadena|original||", sello)
    end
  end

  describe "información de una FIEL" do
    test "imprime y valida los datos del FIEL #{Path.basename(@fiel.cer)}" do
      print_certificado(@fiel)

      {:ok, cert} = Certificate.from_file(@fiel.cer)
      {:ok, key} = PrivateKey.from_file(@fiel.key, @fiel.password)
      {:ok, cred} = Credential.create(@fiel.cer, @fiel.key, @fiel.password)

      assert Certificate.rfc(cert) == "CACX7605101P8"
      assert Certificate.legal_name(cert) == "XOCHILT CASAS CHAVEZ"
      assert Certificate.subject_type(cert) == :fisica
      assert Certificate.certificate_type(cert) == :fiel
      assert Certificate.is_fiel?(cert)
      refute Certificate.is_csd?(cert)

      assert Certificate.no_certificado(cert) == "30001000000500003282"
      assert Certificate.ac_version(cert) == 5

      assert Certificate.valid_from(cert) == ~U[2023-05-09 18:05:49Z]
      assert Certificate.valid_to(cert) == ~U[2027-05-08 18:05:49Z]

      assert Certificate.fingerprint(cert) ==
               "9C:E9:14:C2:C9:BB:47:A2:A1:6B:2D:3E:50:43:40:D0:CF:F3:C2:40"

      assert Certificate.fingerprint_sha256(cert) ==
               "EF9BB92EDDFBC2F675B6A6B91751A8EF9A02CEB4C9133AB9D4F675DA90B76465"

      sub = Certificate.subject(cert)
      assert sub["CN"] == "XOCHILT CASAS CHAVEZ"
      assert sub["serialNumber"] == "CACX760510MGTSHC04"
      assert sub["x500UniqueIdentifier"] == "CACX7605101P8"

      iss = Certificate.issuer(cert)
      assert iss["C"] == "MX"
      assert iss["CN"] == "AC UAT"
      assert iss["O"] == "SERVICIO DE ADMINISTRACION TRIBUTARIA"
      assert iss["OU"] == "SAT-IES Authority"

      {:RSAPublicKey, modulus, exponent} = Certificate.public_key(cert)
      assert bit_length(modulus) == 2048
      assert exponent == 65_537

      assert PrivateKey.belongs_to_certificate?(key, cert)
      assert Credential.key_matches_certificate?(cred)

      sello = Credential.sign(cred, "||cadena|original||")
      assert Credential.verify(cred, "||cadena|original||", sello)
    end
  end

  defp print_certificado(%{label: label, cer: cer_path, key: key_path, password: pwd}) do
    {:ok, cert} = Certificate.from_file(cer_path)
    key_result = PrivateKey.from_file(key_path, pwd)

    seccion("=== #{label} ===")
    linea("Archivo .cer", cer_path)
    linea("Archivo .key", key_path)
    linea("Tamaño DER (bytes)", byte_size(Certificate.to_der(cert)))

    seccion("--- Identidad del titular ---")
    linea("RFC", Certificate.rfc(cert))
    linea("Nombre legal", Certificate.legal_name(cert))
    linea("Tipo de sujeto", Certificate.subject_type(cert))
    linea("Tipo de certificado", Certificate.certificate_type(cert))
    linea("¿Es CSD?", Certificate.is_csd?(cert))
    linea("¿Es FIEL?", Certificate.is_fiel?(cert))

    seccion("--- Identificadores SAT ---")
    linea("No. certificado SAT (20 dig.)", Certificate.no_certificado(cert))
    linea("Versión AC del SAT", Certificate.ac_version(cert))
    linea("Número de serie (hex)", Certificate.serial_number(cert))

    seccion("--- Vigencia ---")
    linea("Inicio de vigencia (UTC)", Certificate.valid_from(cert))
    linea("Fin de vigencia (UTC)", Certificate.valid_to(cert))
    linea("¿Vigente ahora?", Certificate.valid?(cert))
    linea("¿Vencido?", Certificate.expired?(cert))

    seccion("--- Huellas digitales ---")
    linea("SHA-1", Certificate.fingerprint(cert))
    linea("SHA-256", Certificate.fingerprint_sha256(cert))

    seccion("--- Subject (titular) ---")
    print_mapa(Certificate.subject(cert))

    seccion("--- Issuer (emisor) ---")
    print_mapa(Certificate.issuer(cert))

    seccion("--- Llave pública ---")
    {:RSAPublicKey, modulus, exponent} = Certificate.public_key(cert)
    linea("Tamaño módulo RSA (bits)", bit_length(modulus))
    linea("Exponente público", exponent)
    linea("PEM (primeros 80 chars)", String.slice(Certificate.public_key_pem(cert), 0, 80) <> "...")

    seccion("--- Llave privada ---")
    case key_result do
      {:ok, key} ->
        linea("Carga", "OK (con contraseña #{inspect(pwd)})")
        linea("¿Pertenece al certificado?", PrivateKey.belongs_to_certificate?(key, cert))
        linea("PEM (primeros 80 chars)", String.slice(PrivateKey.to_pem(key), 0, 80) <> "...")

        case Credential.create(cer_path, key_path, pwd) do
          {:ok, cred} ->
            seccion("--- Credential (cer + key) ---")
            linea("RFC (vía credential)", Credential.rfc(cred))
            linea("Nombre legal (vía credential)", Credential.legal_name(cred))
            linea("¿Llave coincide con cert?", Credential.key_matches_certificate?(cred))
            sello = Credential.sign(cred, "||cadena|original|de|prueba||")
            linea("Sello SHA-256 base64 (primeros 60 chars)", String.slice(sello, 0, 60) <> "...")
            linea("Verificación de sello", Credential.verify(cred, "||cadena|original|de|prueba||", sello))

          {:error, reason} ->
            linea("Credential.create", "ERROR: #{inspect(reason)}")
        end

      {:error, reason} ->
        linea("Carga", "ERROR: #{inspect(reason)}")
    end

    IO.puts("")
  end

  defp seccion(titulo) do
    IO.puts("\n" <> titulo)
  end

  defp linea(etiqueta, valor) do
    IO.puts("  #{String.pad_trailing(etiqueta <> ":", 36)} #{inspect(valor)}")
  end

  defp print_mapa(mapa) when is_map(mapa) do
    mapa
    |> Enum.sort()
    |> Enum.each(fn {k, v} -> linea("  " <> k, v) end)
  end

  defp bit_length(n) when is_integer(n) and n > 0 do
    n |> :binary.encode_unsigned() |> byte_size() |> Kernel.*(8)
  end
end
