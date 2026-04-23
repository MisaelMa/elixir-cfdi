defmodule Cfdi.CsdTest do
  use ExUnit.Case

  @moduletag :openssl

  setup_all do
    tmp = Path.join(System.tmp_dir!(), "cfdi_csd_test_#{:erlang.unique_integer([:positive])}")
    :ok = File.mkdir_p!(tmp)

    key_pem = Path.join(tmp, "key.pem")
    cer_pem = Path.join(tmp, "test.cer")

    {_, 0} =
      System.cmd(
        "openssl",
        [
          "req",
          "-x509",
          "-newkey",
          "rsa:2048",
          "-keyout",
          key_pem,
          "-out",
          cer_pem,
          "-days",
          "1",
          "-nodes",
          "-subj",
          "/O=Sat Test/OU=CSD UNIT/CN=BBB020202BBB"
        ],
        stderr_to_stdout: true
      )

    %{cer_path: cer_pem, key_path: key_pem}
  end

  describe "Certificate" do
    test "from_file builds struct with raw_der and parsed", %{cer_path: cer_path} do
      assert {:ok, cert} = Cfdi.Csd.Certificate.from_file(cer_path)
      assert is_binary(cert.raw_der)
      assert is_tuple(cert.parsed)
      assert Cfdi.Csd.Certificate.to_der(cert) == cert.raw_der
      pem = Cfdi.Csd.Certificate.to_pem(cert)
      assert String.starts_with?(String.trim(pem), "-----BEGIN CERTIFICATE-----")
      assert is_binary(Cfdi.Csd.Certificate.serial_number(cert))
      assert is_binary(Cfdi.Csd.Certificate.no_certificado(cert))
      assert Cfdi.Csd.Certificate.legal_name(cert) != ""
      assert %DateTime{} = Cfdi.Csd.Certificate.valid_from(cert)
      assert %DateTime{} = Cfdi.Csd.Certificate.valid_to(cert)
      assert is_boolean(Cfdi.Csd.Certificate.expired?(cert))
      assert String.length(Cfdi.Csd.Certificate.fingerprint(cert)) == 64
      assert is_binary(Cfdi.Csd.Certificate.to_base64(cert))
      refute Cfdi.Csd.Certificate.is_fiel?(cert)
      assert Cfdi.Csd.Certificate.is_csd?(cert)
    end
  end

  describe "PrivateKey" do
    test "from_file builds struct", %{key_path: key_path} do
      assert {:ok, pk} = Cfdi.Csd.PrivateKey.from_file(key_path, nil)
      assert is_binary(pk.raw_der)
      assert pk.decoded != nil
    end

    test "sign returns base64", %{key_path: key_path} do
      assert {:ok, pk} = Cfdi.Csd.PrivateKey.from_file(key_path, nil)
      sig = Cfdi.Csd.PrivateKey.sign(pk, "cadena de prueba")
      assert {:ok, _} = Base.decode64(sig)
    end
  end

  describe "Credential" do
    test "create composes certificate and private_key", %{cer_path: cer_path, key_path: key_path} do
      assert {:ok, cred} = Cfdi.Csd.Credential.create(cer_path, key_path, nil)
      assert %Cfdi.Csd.Certificate{} = cred.certificate
      assert %Cfdi.Csd.PrivateKey{} = cred.private_key
      assert is_binary(Cfdi.Csd.Credential.rfc(cred))
      assert is_binary(Cfdi.Csd.Credential.sign(cred, "x"))
      refute Cfdi.Csd.Credential.is_fiel?(cred)
      assert Cfdi.Csd.Credential.is_csd?(cred)
    end
  end
end
