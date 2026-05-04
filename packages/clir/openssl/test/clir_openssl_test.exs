defmodule Clir.OpensslTest do
  use ExUnit.Case

  alias Clir.Openssl.{Pkcs8, X509}

  @moduletag :openssl

  setup_all do
    tmp = Path.join(System.tmp_dir!(), "clir_openssl_test_#{:erlang.unique_integer([:positive])}")
    :ok = File.mkdir_p!(tmp)

    key_pem = Path.join(tmp, "key.pem")
    cert_pem = Path.join(tmp, "cert.pem")

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
          cert_pem,
          "-days",
          "1",
          "-nodes",
          "-subj",
          "/O=Test/CN=AAA010101AAA"
        ],
        stderr_to_stdout: true
      )

    %{tmp: tmp, key_pem: key_pem, cert_pem: cert_pem}
  end

  describe "Clir.Openssl root" do
    test "version/0 returns application version" do
      assert is_binary(Clir.Openssl.version())
    end
  end

  describe "X509" do
    test "from_file, serial, subject, issuer, validity, fingerprint", %{cert_pem: cert_pem} do
      assert {:ok, cert} = X509.from_file(cert_pem)
      serial = X509.serial(cert)
      assert String.match?(serial, ~r/^[0-9A-F]+$/)
      assert String.contains?(X509.subject(cert), "CN=")
      assert String.contains?(X509.issuer(cert), "CN=")
      %{not_before: nb, not_after: na} = X509.validity(cert)
      assert %DateTime{} = nb
      assert %DateTime{} = na
      assert DateTime.compare(nb, na) == :lt
      assert String.length(X509.fingerprint(cert, :sha)) == 40
      assert String.length(X509.fingerprint(cert, :sha256)) == 64
      assert is_binary(X509.no_certificado(cert))
    end

    test "from_pem and get_pem round-trip DER", %{cert_pem: cert_pem} do
      pem = File.read!(cert_pem)
      assert {:ok, cert} = X509.from_pem(pem)
      der = pem_to_der(pem)
      assert {:ok, pem_out} = X509.get_pem(der)
      assert {:ok, cert2} = X509.from_pem(pem_out)
      assert X509.serial(cert) == X509.serial(cert2)
      assert {:ok, cert3} = X509.from_der(der)
      assert X509.serial(cert) == X509.serial(cert3)
    end
  end

  describe "Pkcs8" do
    test "from_pem, to_pem, get_data", %{key_pem: key_pem} do
      pem = File.read!(key_pem)
      assert {:ok, decoded} = Pkcs8.from_pem(pem, nil)
      assert match?({:RSAPrivateKey, _, _, _, _, _, _, _, _}, decoded) or
               match?({:PrivateKeyInfo, _, _, _, _}, decoded)

      der =
        cond do
          match?({:RSAPrivateKey, _, _, _, _, _, _, _, _}, decoded) ->
            :public_key.der_encode(:RSAPrivateKey, decoded)

          match?({:PrivateKeyInfo, _, _, _, _}, decoded) ->
            :public_key.der_encode(:PrivateKeyInfo, decoded)
        end

      assert {:ok, pem2} = Pkcs8.to_pem(der, nil)
      assert String.contains?(pem2, "BEGIN")
      assert String.contains?(pem2, "END")
      assert {:ok, _} = Pkcs8.get_data(key_pem, nil)
    end
  end

  defp pem_to_der(pem) do
    case :public_key.pem_decode(pem) do
      [{:Certificate, der, _} | _] -> der
      _ -> flunk("expected CERTIFICATE PEM")
    end
  end
end
