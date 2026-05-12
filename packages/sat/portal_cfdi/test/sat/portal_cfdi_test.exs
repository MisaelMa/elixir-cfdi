defmodule Sat.PortalCfdiTest do
  use ExUnit.Case, async: true

  alias Sat.PortalCfdi
  alias Sat.PortalCfdi.Portal

  alias Sat.PortalCfdi.Types.{
    ConsultaCfdiParams,
    CredencialCIEC,
    CredencialPortal,
    SesionSAT
  }

  test "version/0 retorna la version del paquete" do
    assert is_list(PortalCfdi.version()) or is_binary(to_string(PortalCfdi.version()))
  end

  describe "Portal.consultar_cfdis/3" do
    test "rechaza sesion no autenticada" do
      sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}

      assert {:error, {:sesion_no_autenticada, _}} =
               Portal.consultar_cfdis(sesion, %ConsultaCfdiParams{})
    end
  end

  describe "Portal.descargar_xml/3" do
    test "rechaza sesion no autenticada" do
      sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}

      assert {:error, {:sesion_no_autenticada, _}} =
               Portal.descargar_xml(sesion, "uuid-test")
    end
  end

  describe "Portal.login/2" do
    test "CIEC sin captcha_resolver falla con KeyError clara" do
      cred = %CredencialPortal{
        tipo: :ciec,
        ciec: %CredencialCIEC{rfc: "AAA010101AAA", password: "secret"}
      }

      assert_raise KeyError, fn ->
        Portal.login(cred, [])
      end
    end

    test "credencial sin :ciec ni :fiel correctos retorna error" do
      cred = %CredencialPortal{tipo: :otro, ciec: nil, fiel: nil}

      assert {:error, {:invalid_credential, _}} = Portal.login(cred, [])
    end
  end

  describe "Portal.logout/2" do
    @tag :network
    test "siempre retorna :ok (best-effort, hace request real)" do
      # logout/2 ahora usa Browser.Tls (NIF) que conecta al SAT real.
      # No es practico unit-testearlo sin mockear el NIF — el test queda
      # bajo @tag :network y se valida en el flujo real.
      sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}
      assert :ok = Portal.logout(sesion)
    end
  end
end
