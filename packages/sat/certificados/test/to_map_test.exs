defmodule Sat.Certificados.ToMapTest do
  @moduledoc """
  Tests de `Certificate.to_map/2` y `Credential.to_map/2` usando pattern
  matching `%{}` para documentar la forma esperada del mapa en cada modo
  (`:keys`).

  Funcionan como spec viva — si alguien rompe el shape en el futuro, el
  pattern match falla con un mensaje detallado mostrando el árbol entero.
  """

  use ExUnit.Case, async: false

  alias Sat.Certificados.{Certificate, Credential}

  @files_dir Path.expand("../../../files/certificados", __DIR__)

  @csd_cer Path.join(@files_dir, "LAN7008173R5.cer")
  @csd_key Path.join(@files_dir, "LAN7008173R5.key")
  @csd_password "12345678a"

  @fiel_cer Path.join([@files_dir, "efirma", "goodCertificate.cer"])
  @fiel_key Path.join([@files_dir, "efirma", "goodPrivateKeyEncrypt.key"])
  @fiel_password "12345678a"

  describe "Certificate.to_map/2 — CSD" do
    setup do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      %{cert: cert}
    end

    test "default :atom — pattern match con átomos snake_case", %{cert: cert} do
      map = Certificate.to_map(cert)
      IO.inspect(map, label: "Certificate.to_map/2 :atom")

      assert %{
               type: :csd,
               subject_type: :moral,
               rfc: "LAN7008173R5",
               legal_name: "CINDEMEX SA DE CV",
               no_certificado: "20001000000300022815",
               serial_number: serial,
               valid_from: %DateTime{} = vf,
               valid_to: %DateTime{} = vt,
               expired: true,
               valid: false,
               fingerprint_sha1: fp1,
               fingerprint_sha256: fp256,
               # `issuer` y `subject` son Distinguished Names (mapas con
               # códigos LDAP). En modo :atom van como átomos.
               issuer: %{
                 CN: "A.C. 2 de pruebas(4096)",
                 O: "Servicio de Administración Tributaria"
               },
               subject: %{CN: "CINDEMEX SA DE CV", O: "CINDEMEX SA DE CV"}
             } = map

      assert is_binary(serial) and String.match?(serial, ~r/^[0-9A-F]+$/)
      assert String.match?(fp1, ~r/^[0-9A-F:]+$/)
      assert String.match?(fp256, ~r/^[0-9A-F]+$/) and byte_size(fp256) == 64
      assert DateTime.compare(vf, vt) == :lt
    end

    test ":string — pattern match con strings", %{cert: cert} do
      map = Certificate.to_map(cert, keys: :string)

      assert %{
               "type" => :csd,
               "subject_type" => :moral,
               "rfc" => "LAN7008173R5",
               "legal_name" => "CINDEMEX SA DE CV",
               "no_certificado" => "20001000000300022815",
               "subject" => %{"CN" => "CINDEMEX SA DE CV"}
             } = map
    end

    test ":existing — átomos solo si ya existen", %{cert: cert} do
      # Las llaves del módulo (definidas en el `to_map`) ya existen como
      # átomos al cargar Certificate → resuelven a átomo.
      map = Certificate.to_map(cert, keys: :existing)

      assert %{
               type: :csd,
               rfc: "LAN7008173R5",
               legal_name: "CINDEMEX SA DE CV"
             } = map
    end

    test ":keys inválido lanza ArgumentError", %{cert: cert} do
      assert_raise ArgumentError, ~r/:keys inválida/, fn ->
        Certificate.to_map(cert, keys: :foo)
      end
    end
  end

  describe "Certificate.to_map/2 — FIEL" do
    test "tipo :fiel, persona física, y expone CURP del subject" do
      {:ok, cert} = Certificate.from_file(@fiel_cer)

      assert %{
               type: :fiel,
               subject_type: :fisica,
               curp: "CACX760510MGTSHC04"
             } = Certificate.to_map(cert)
    end
  end

  describe "Credential.to_map/2 — CSD" do
    setup do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @csd_password)
      %{cred: cred}
    end

    test "default :atom — pattern match anidado completo", %{cred: cred} do
      map = Credential.to_map(cred)

      assert %{
               is_csd: true,
               is_fiel: false,
               rfc: "LAN7008173R5",
               legal_name: "CINDEMEX SA DE CV",
               no_certificado: "20001000000300022815",
               valid: false,
               key_matches_certificate: true,
               certificate: %{
                 type: :csd,
                 subject_type: :moral,
                 rfc: "LAN7008173R5",
                 fingerprint_sha256: fp,
                 subject: %{CN: "CINDEMEX SA DE CV", O: "CINDEMEX SA DE CV"}
               }
             } = map

      assert byte_size(fp) == 64
    end

    test ":string — propaga a certificado anidado", %{cred: cred} do
      map = Credential.to_map(cred, keys: :string)

      assert %{
               "is_csd" => true,
               "rfc" => "LAN7008173R5",
               "certificate" => %{
                 "type" => :csd,
                 "rfc" => "LAN7008173R5"
               }
             } = map
    end

    test "no incluye la llave privada (PII)", %{cred: cred} do
      map = Credential.to_map(cred)

      refute Map.has_key?(map, :private_key)
      refute Map.has_key?(map, :key)
      refute Map.has_key?(map.certificate, :private_key)
    end
  end

  describe "Credential.to_map/2 — FIEL" do
    test "is_fiel: true y is_csd: false" do
      {:ok, cred} = Credential.create(@fiel_cer, @fiel_key, @fiel_password)

      assert %{
               is_fiel: true,
               is_csd: false,
               certificate: %{type: :fiel}
             } = Credential.to_map(cred)
    end
  end
end
