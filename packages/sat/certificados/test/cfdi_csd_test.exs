defmodule Cfdi.CsdTest do
  use ExUnit.Case, async: true

  alias Sat.Certificados.{Certificate, Credential, PrivateKey}

  @certs_dir Path.expand("../../../files/certificados", __DIR__)
  @csd_cer Path.join(@certs_dir, "LAN7008173R5.cer")
  @csd_cer_pem Path.join(@certs_dir, "LAN7008173R5.cer.pem")
  @csd_key Path.join(@certs_dir, "LAN7008173R5.key")
  @csd_key_pem Path.join(@certs_dir, "LAN7008173R5.key.pem")
  @key_password "12345678a"
  @rfc_esperado "LAN7008173R5"

  describe "Certificate.from_file (DER)" do
    test "carga el certificado desde archivo .cer (DER)" do
      assert {:ok, %Certificate{}} = Certificate.from_file(@csd_cer)
    end

    test "carga el certificado desde archivo .pem" do
      assert {:ok, %Certificate{}} = Certificate.from_file(@csd_cer_pem)
    end
  end

  describe "Certificate.from_pem" do
    test "carga el certificado desde PEM string" do
      pem = File.read!(@csd_cer_pem)
      assert {:ok, %Certificate{}} = Certificate.from_pem(pem)
    end
  end

  describe "Certificate.from_der" do
    test "carga el certificado desde buffer DER" do
      der = File.read!(@csd_cer)
      assert {:ok, %Certificate{}} = Certificate.from_der(der)
    end
  end

  describe "Certificate.serial_number" do
    test "retorna el número de serie en hex" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      serial = Certificate.serial_number(cert)
      assert is_binary(serial)
      assert serial != ""
    end
  end

  describe "Certificate.no_certificado" do
    test "retorna el número de certificado SAT (20 dígitos)" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      no_cer = Certificate.no_certificado(cert)
      assert Regex.match?(~r/^\d{20}$/, no_cer)
    end

    test "el número de certificado coincide en DER y PEM" do
      {:ok, cert_der} = Certificate.from_file(@csd_cer)
      {:ok, cert_pem} = Certificate.from_file(@csd_cer_pem)
      assert Certificate.no_certificado(cert_der) == Certificate.no_certificado(cert_pem)
    end
  end

  describe "Certificate.rfc" do
    test "extrae el RFC del subject" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      rfc = Certificate.rfc(cert)
      assert rfc != ""
      assert String.length(rfc) >= 12
      assert String.length(rfc) <= 13
    end

    test "el RFC del CSD es LAN7008173R5" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert Certificate.rfc(cert) == @rfc_esperado
    end
  end

  describe "Certificate.legal_name" do
    test "extrae el nombre legal del subject" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert Certificate.legal_name(cert) != ""
    end

    test "el nombre legal contiene CINDEMEX" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert String.contains?(String.upcase(Certificate.legal_name(cert)), "CINDEMEX")
    end
  end

  describe "Certificate.subject e issuer" do
    test "retorna subject como mapa con atributos" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      sub = Certificate.subject(cert)
      assert is_map(sub)
      assert map_size(sub) > 0
    end

    test "retorna issuer como mapa con atributos" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      iss = Certificate.issuer(cert)
      assert is_map(iss)
      assert map_size(iss) > 0
    end
  end

  describe "Certificate.valid_from / valid_to" do
    test "retorna fecha de inicio de vigencia como DateTime" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert %DateTime{} = Certificate.valid_from(cert)
    end

    test "retorna fecha de fin de vigencia como DateTime" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert %DateTime{} = Certificate.valid_to(cert)
    end

    test "la fecha de fin es posterior a la de inicio" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert DateTime.compare(Certificate.valid_to(cert), Certificate.valid_from(cert)) == :gt
    end
  end

  describe "Certificate.expired?" do
    test "el certificado de prueba del SAT está vencido" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert Certificate.expired?(cert) == true
    end
  end

  describe "Certificate.fingerprint" do
    test "retorna SHA-1 en formato XX:XX:XX (59 chars)" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      fp = Certificate.fingerprint(cert)
      assert Regex.match?(~r/^[0-9A-F]{2}(:[0-9A-F]{2})+$/, fp)
      assert String.length(fp) == 59
    end

    test "fingerprint es consistente entre llamadas" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert Certificate.fingerprint(cert) == Certificate.fingerprint(cert)
    end

    test "fingerprint_sha256 es 64 chars hex" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      fp = Certificate.fingerprint_sha256(cert)
      assert String.length(fp) == 64
      assert Regex.match?(~r/^[0-9A-F]+$/, fp)
    end
  end

  describe "Certificate.public_key_pem" do
    test "retorna la llave pública en PEM" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      pem = Certificate.public_key_pem(cert)
      assert String.contains?(pem, "-----BEGIN PUBLIC KEY-----")
    end
  end

  describe "Certificate.is_csd? / is_fiel?" do
    test "el certificado LAN7008173R5 es CSD" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert Certificate.is_csd?(cert) == true
    end

    test "is_fiel? retorna false para un CSD" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert Certificate.is_fiel?(cert) == false
    end
  end

  describe "Certificate.to_pem / to_der" do
    test "to_pem retorna string PEM válido" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      pem = Certificate.to_pem(cert)
      assert String.contains?(pem, "-----BEGIN CERTIFICATE-----")
      assert String.contains?(pem, "-----END CERTIFICATE-----")
    end

    test "to_der retorna binary" do
      {:ok, cert} = Certificate.from_file(@csd_cer)
      der = Certificate.to_der(cert)
      assert is_binary(der)
      assert byte_size(der) > 0
    end

    test "round-trip DER -> Certificate -> DER produce el mismo no_certificado" do
      {:ok, cert1} = Certificate.from_file(@csd_cer)
      der1 = Certificate.to_der(cert1)
      {:ok, cert2} = Certificate.from_der(der1)
      assert Certificate.no_certificado(cert2) == Certificate.no_certificado(cert1)
    end
  end

  describe "PrivateKey.from_file (DER cifrado)" do
    test "carga la llave privada desde archivo .key con contraseña" do
      assert {:ok, %PrivateKey{}} = PrivateKey.from_file(@csd_key, @key_password)
    end

    test "falla con contraseña incorrecta" do
      assert {:error, _} = PrivateKey.from_file(@csd_key, "contrasena_incorrecta")
    end
  end

  describe "PrivateKey.from_pem" do
    test "carga la llave privada desde PEM sin cifrado" do
      pem = File.read!(@csd_key_pem)
      assert {:ok, %PrivateKey{}} = PrivateKey.from_pem(pem)
    end
  end

  describe "PrivateKey.from_der" do
    test "carga la llave privada desde buffer DER cifrado" do
      der = File.read!(@csd_key)
      assert {:ok, %PrivateKey{}} = PrivateKey.from_der(der, @key_password)
    end
  end

  describe "PrivateKey.to_pem" do
    test "retorna la llave privada en formato PEM" do
      {:ok, key} = PrivateKey.from_file(@csd_key, @key_password)
      pem = PrivateKey.to_pem(key)
      assert String.contains?(pem, "-----BEGIN PRIVATE KEY-----")
      assert String.contains?(pem, "-----END PRIVATE KEY-----")
    end
  end

  describe "PrivateKey.sign" do
    test "firma datos y retorna base64" do
      {:ok, key} = PrivateKey.from_file(@csd_key, @key_password)
      sig = PrivateKey.sign(key, "cadena original de prueba")
      assert is_binary(sig)
      assert byte_size(sig) > 0
      assert {:ok, _} = Base.decode64(sig)
    end

    test "firmas son verificables con la llave pública del certificado" do
      {:ok, key} = PrivateKey.from_file(@csd_key, @key_password)
      {:ok, cert} = Certificate.from_file(@csd_cer)
      data = "datos a firmar"
      sig_b64 = PrivateKey.sign(key, data)
      sig = Base.decode64!(sig_b64)
      pub = Certificate.public_key(cert)
      assert :public_key.verify(data, :sha256, sig, pub)
    end

    test "la firma cambia con datos diferentes" do
      {:ok, key} = PrivateKey.from_file(@csd_key, @key_password)
      sig1 = PrivateKey.sign(key, "datos 1")
      sig2 = PrivateKey.sign(key, "datos 2")
      assert sig1 != sig2
    end

    test "firma con algoritmo alternativo SHA512" do
      {:ok, key} = PrivateKey.from_file(@csd_key, @key_password)
      sig = PrivateKey.sign(key, "datos", :sha512)
      assert is_binary(sig)
      assert byte_size(sig) > 0
    end
  end

  describe "PrivateKey.belongs_to_certificate?" do
    test "la llave pertenece al certificado correspondiente" do
      {:ok, key} = PrivateKey.from_file(@csd_key, @key_password)
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert PrivateKey.belongs_to_certificate?(key, cert)
    end

    test "la llave PEM pertenece al certificado correspondiente" do
      {:ok, key} = PrivateKey.from_pem(File.read!(@csd_key_pem))
      {:ok, cert} = Certificate.from_pem(File.read!(@csd_cer_pem))
      assert PrivateKey.belongs_to_certificate?(key, cert)
    end

    test "DER y PEM son consistentes contra el mismo certificado" do
      {:ok, key_der} = PrivateKey.from_file(@csd_key, @key_password)
      {:ok, key_pem} = PrivateKey.from_pem(File.read!(@csd_key_pem))
      {:ok, cert} = Certificate.from_file(@csd_cer)
      assert PrivateKey.belongs_to_certificate?(key_der, cert)
      assert PrivateKey.belongs_to_certificate?(key_pem, cert)
    end
  end

  describe "Credential.create" do
    test "crea una credencial desde archivos .cer y .key" do
      assert {:ok, %Credential{}} = Credential.create(@csd_cer, @csd_key, @key_password)
    end

    test "crea una credencial desde archivos PEM" do
      assert {:ok, %Credential{}} = Credential.create(@csd_cer_pem, @csd_key_pem, @key_password)
    end

    test "falla con contraseña incorrecta" do
      assert {:error, _} = Credential.create(@csd_cer, @csd_key, "mal_password")
    end
  end

  describe "Credential.from_pem" do
    test "crea una credencial desde strings PEM" do
      cer_pem = File.read!(@csd_cer_pem)
      key_pem = File.read!(@csd_key_pem)
      assert {:ok, %Credential{}} = Credential.from_pem(cer_pem, key_pem)
    end
  end

  describe "Credential.is_csd? / is_fiel?" do
    test "la credencial con CSD de prueba es CSD" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Credential.is_csd?(cred)
    end

    test "is_fiel? es false para un CSD" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      refute Credential.is_fiel?(cred)
    end
  end

  describe "Credential.rfc / legal_name / serial_number / no_certificado" do
    test "rfc retorna el RFC del titular" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Credential.rfc(cred) == @rfc_esperado
    end

    test "legal_name retorna el nombre legal" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      name = Credential.legal_name(cred)
      assert name != ""
      assert String.contains?(String.upcase(name), "CINDEMEX")
    end

    test "serial_number retorna el número de serie hex" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Credential.serial_number(cred) != ""
    end

    test "no_certificado retorna 20 dígitos" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Regex.match?(~r/^\d{20}$/, Credential.no_certificado(cred))
    end
  end

  describe "Credential.sign / verify" do
    test "firma datos y verifica la firma" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      data = "||cadena|original|de|prueba||"
      sig = Credential.sign(cred, data)

      assert is_binary(sig)
      assert byte_size(sig) > 0
      assert Credential.verify(cred, data, sig) == true
    end

    test "verifica firma incorrecta retorna false" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      data = "datos originales"
      _ = Credential.sign(cred, data)
      firma_falsa = Base.encode64("firma_falsa")
      assert Credential.verify(cred, data, firma_falsa) == false
    end

    test "firma de otros datos no verifica como firma de datos originales" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      firma_otros = Credential.sign(cred, "datos diferentes")
      assert Credential.verify(cred, "datos originales", firma_otros) == false
    end

    test "firma desde PEM equivale a firma desde DER" do
      {:ok, cred_der} = Credential.create(@csd_cer, @csd_key, @key_password)
      cer_pem = File.read!(@csd_cer_pem)
      key_pem = File.read!(@csd_key_pem)
      {:ok, cred_pem} = Credential.from_pem(cer_pem, key_pem)

      data = "cadena de prueba"
      sig_pem = Credential.sign(cred_pem, data)
      assert Credential.verify(cred_der, data, sig_pem) == true
    end
  end

  describe "Credential.valid?" do
    test "el certificado de prueba del SAT está vencido" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Credential.valid?(cred) == false
    end
  end

  describe "Credential.belongs_to?" do
    test "pertenece al RFC correcto" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Credential.belongs_to?(cred, @rfc_esperado)
    end

    test "pertenece al RFC en minúsculas (case insensitive)" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Credential.belongs_to?(cred, String.downcase(@rfc_esperado))
    end

    test "no pertenece a un RFC diferente" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      refute Credential.belongs_to?(cred, "XAXX010101000")
    end
  end

  describe "Credential.key_matches_certificate?" do
    test "la llave coincide con el certificado" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert Credential.key_matches_certificate?(cred)
    end
  end

  describe "Credential acceso a certificate y private_key" do
    test "expone el certificado" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert %Certificate{} = cred.certificate
      assert Certificate.rfc(cred.certificate) == @rfc_esperado
    end

    test "expone la llave privada" do
      {:ok, cred} = Credential.create(@csd_cer, @csd_key, @key_password)
      assert %PrivateKey{} = cred.private_key
      assert String.contains?(PrivateKey.to_pem(cred.private_key), "-----BEGIN PRIVATE KEY-----")
    end
  end
end
