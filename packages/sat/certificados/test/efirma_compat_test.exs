defmodule Cfdi.EfirmaCompatTest do
  @moduledoc """
  Tests portados de [`e.firma`](https://www.npmjs.com/package/e.firma) para
  validar paridad con Node `@cfdi/csd`: detección CSD/FIEL por extensiones,
  AC version, subject_type, issued_by?, rsa_encrypt/rsa_decrypt, strict mode.
  """

  use ExUnit.Case, async: true

  alias Sat.Certificados.{Certificate, PrivateKey}

  @fixtures Path.expand("../../../files/certificados/efirma", __DIR__)
  defp f(name), do: Path.join(@fixtures, name)
  @key_password "12345678a"

  describe "Certificate.certificate_type (por extensiones)" do
    test "detecta :fiel en goodCertificate.cer" do
      {:ok, cert} = Certificate.from_file(f("goodCertificate.cer"))
      assert Certificate.certificate_type(cert) == :fiel
      assert Certificate.is_fiel?(cert)
      refute Certificate.is_csd?(cert)
    end

    test "detecta :csd en CSD_Certificate.cer" do
      {:ok, cert} = Certificate.from_file(f("CSD_Certificate.cer"))
      assert Certificate.certificate_type(cert) == :csd
      assert Certificate.is_csd?(cert)
      refute Certificate.is_fiel?(cert)
    end

    test "detecta :fiel en ipnCertificate.cer (persona moral)" do
      {:ok, cert} = Certificate.from_file(f("ipnCertificate.cer"))
      assert Certificate.certificate_type(cert) == :fiel
    end
  end

  describe "Certificate.valid? / expired? (vigencia)" do
    test "expiredCertificate.cer no está vigente" do
      {:ok, cert} = Certificate.from_file(f("expiredCertificate.cer"))
      refute Certificate.valid?(cert)
      assert Certificate.expired?(cert)
    end
  end

  describe "Certificate.ac_version" do
    test "goodCertificate.cer fue emitido por AC5" do
      {:ok, cert} = Certificate.from_file(f("goodCertificate.cer"))
      assert Certificate.ac_version(cert) == 5
    end

    test "ipnCertificate.cer fue emitido por AC5" do
      {:ok, cert} = Certificate.from_file(f("ipnCertificate.cer"))
      assert Certificate.ac_version(cert) == 5
    end
  end

  describe "Certificate.subject_type" do
    test "ipnCertificate.cer es persona MORAL" do
      {:ok, cert} = Certificate.from_file(f("ipnCertificate.cer"))
      assert Certificate.subject_type(cert) == :moral
    end

    test "goodCertificate.cer es persona FISICA" do
      {:ok, cert} = Certificate.from_file(f("goodCertificate.cer"))
      assert Certificate.subject_type(cert) == :fisica
    end
  end

  describe "Certificate.serial_number" do
    test "goodCertificate.cer tiene el serial esperado" do
      {:ok, cert} = Certificate.from_file(f("goodCertificate.cer"))
      assert Certificate.serial_number(cert) ==
               "3330303031303030303030353030303033323832"
    end
  end

  describe "Certificate.issued_by? / verify_integrity" do
    test "ipnCertificate.cer fue emitido por AC5_SAT.cer" do
      {:ok, subject} = Certificate.from_file(f("ipnCertificate.cer"))
      {:ok, ac5} = Certificate.from_file(f("AC5_SAT.cer"))
      assert Certificate.issued_by?(subject, ac5)
      assert Certificate.verify_integrity(subject, ac5)
    end

    test "ipnCertificate.cer NO fue emitido por AC4_SAT.cer" do
      {:ok, subject} = Certificate.from_file(f("ipnCertificate.cer"))
      {:ok, ac4} = Certificate.from_file(f("AC4_SAT.cer"))
      refute Certificate.issued_by?(subject, ac4)
    end

    test "un cert ajeno no es emitido por AC5_SAT" do
      {:ok, stranger} = Certificate.from_file(f("00001000000506724016.cer"))
      {:ok, ac5} = Certificate.from_file(f("AC5_SAT.cer"))
      refute Certificate.issued_by?(stranger, ac5)
    end
  end

  describe "Certificate.rsa_encrypt + PrivateKey.rsa_decrypt" do
    test "round-trip de mensaje" do
      {:ok, cert} = Certificate.from_file(f("goodCertificate.cer"))
      {:ok, key} = PrivateKey.from_file(f("goodPrivateKeyEncrypt.key"), @key_password)
      message = "Hola Mundo!"
      enc = Certificate.rsa_encrypt(cert, message)
      assert {:ok, ^message} = PrivateKey.rsa_decrypt(key, enc)
    end
  end

  describe "Certificate.verify (firma directa)" do
    test "firma con key + verify directo en cert" do
      {:ok, cert} = Certificate.from_file(f("goodCertificate.cer"))
      {:ok, key} = PrivateKey.from_file(f("goodPrivateKeyEncrypt.key"), @key_password)
      msg = "Hola Mundo!"
      sig = PrivateKey.sign(key, msg)
      assert Certificate.verify(cert, msg, sig)
    end

    test "verify con datos diferentes retorna false" do
      {:ok, cert} = Certificate.from_file(f("goodCertificate.cer"))
      {:ok, key} = PrivateKey.from_file(f("goodPrivateKeyEncrypt.key"), @key_password)
      sig = PrivateKey.sign(key, "uno")
      refute Certificate.verify(cert, "otro", sig)
    end
  end

  describe "Certificate.from_file con archivo inválido" do
    test "lanza al cargar invalid.der" do
      assert {:error, _} = Certificate.from_file(f("invalid.der"))
    end
  end

  describe "PrivateKey strict mode" do
    test "acepta llave PKCS#8 cifrada del SAT" do
      assert {:ok, %PrivateKey{}} =
               PrivateKey.from_file(f("goodPrivateKeyEncrypt.key"), @key_password,
                 strict: true
               )
    end

    test "rechaza llave desencriptada en modo strict" do
      assert {:error, :not_encrypted_pkcs8} =
               PrivateKey.from_file(f("goodPrivateKeyDecrypt.key"), nil, strict: true)
    end

    test "en modo no-strict permite llave desencriptada" do
      assert {:ok, %PrivateKey{}} =
               PrivateKey.from_file(f("goodPrivateKeyDecrypt.key"), nil)
    end
  end

  describe "Certificate.to_pem" do
    test "incluye los marcadores de cert" do
      {:ok, cert} = Certificate.from_file(f("ipnCertificate.cer"))
      pem = Certificate.to_pem(cert)
      assert String.contains?(pem, "-----BEGIN CERTIFICATE-----")
      assert String.contains?(pem, "-----END CERTIFICATE-----")
    end
  end
end
