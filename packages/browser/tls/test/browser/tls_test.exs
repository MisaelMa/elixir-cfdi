defmodule Browser.TlsTest do
  use ExUnit.Case, async: true

  alias Browser.Tls

  describe "profiles/0" do
    test "expone los perfiles configurados" do
      assert :chrome in Tls.profiles()
      assert :firefox in Tls.profiles()
      assert :safari in Tls.profiles()
    end
  end

  describe "profile/1" do
    test "retorna la config de un perfil" do
      chrome = Tls.profile(:chrome)
      assert is_map(chrome)
      assert is_binary(chrome.name)
      assert is_binary(chrome.ciphers)
      assert is_binary(chrome.tls13_ciphers)
      assert is_binary(chrome.curves)
      assert is_binary(chrome.sigalgs)
    end

    test "perfil inexistente retorna nil" do
      assert Tls.profile(:nonexistent) == nil
    end
  end

  describe "default_profile/0" do
    test "es :chrome" do
      assert Tls.default_profile() == :chrome
    end
  end
end
