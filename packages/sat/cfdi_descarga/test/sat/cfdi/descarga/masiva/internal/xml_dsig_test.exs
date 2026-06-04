defmodule Sat.Cfdi.Descarga.Masiva.Internal.XmlDsigTest do
  use ExUnit.Case, async: true

  alias Sat.Cfdi.Descarga.Masiva.Internal.XmlDsig

  describe "sha1_base64/1" do
    test "calcula SHA-1 + base64 de un string conocido" do
      assert XmlDsig.sha1_base64("hello") == "qvTGHdzF6KLavt4PO0gs2a6pQ00="
    end

    test "calcula SHA-1 + base64 de un fragmento XML" do
      input = ~s|<u:Timestamp xmlns:u="ns" u:Id="_0"></u:Timestamp>|
      result = XmlDsig.sha1_base64(input)
      assert is_binary(result)
      assert byte_size(result) == 28
    end
  end

  describe "build_signed_info/2" do
    test "produce SignedInfo con CanonicalizationMethod, SignatureMethod, DigestMethod y URI" do
      xml = XmlDsig.build_signed_info("_0", "DIGEST_BASE64==")

      assert xml =~ ~s|xmlns="http://www.w3.org/2000/09/xmldsig#"|
      assert xml =~ ~s|Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"|
      assert xml =~ ~s|Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"|
      assert xml =~ ~s|Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"|
      assert xml =~ ~s|URI="#_0"|
      assert xml =~ "DIGEST_BASE64=="
    end

    test "es deterministico (mismo input -> mismo output)" do
      a = XmlDsig.build_signed_info("ref-1", "ABC=")
      b = XmlDsig.build_signed_info("ref-1", "ABC=")
      assert a == b
    end
  end

  describe "build_key_info_str/1" do
    test "produce KeyInfo con SecurityTokenReference apuntando al token id" do
      xml = XmlDsig.build_key_info_str("BST-1")

      assert xml =~ ~s|<o:Reference URI="#BST-1"|
      assert xml =~ "X509v3"
    end
  end

  describe "algorithms/0" do
    test "expone los algoritmos canonicos del WS de Descarga Masiva" do
      a = XmlDsig.algorithms()
      assert a.canonicalization == "http://www.w3.org/2001/10/xml-exc-c14n#"
      assert a.signature == "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
      assert a.digest == "http://www.w3.org/2000/09/xmldsig#sha1"
    end
  end
end
