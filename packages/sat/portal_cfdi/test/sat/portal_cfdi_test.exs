defmodule Sat.PortalCfdiTest do
  use ExUnit.Case, async: true

  alias Sat.PortalCfdi
  alias Sat.PortalCfdi.Portal
  alias Sat.PortalCfdi.Types.{ConsultaCfdiParams, CredencialPortal, SesionSAT}

  test "version/0 retorna la version del paquete" do
    assert is_list(PortalCfdi.version()) or is_binary(to_string(PortalCfdi.version()))
  end

  describe "Portal stubs" do
    test "login/1 retorna {:error, :not_implemented}" do
      cred = %CredencialPortal{tipo: :ciec, ciec: nil, fiel: nil}
      assert {:error, {:not_implemented, _}} = Portal.login(cred)
    end

    test "consultar_cfdis/2 retorna {:error, :not_implemented}" do
      sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}
      params = %ConsultaCfdiParams{}
      assert {:error, {:not_implemented, _}} = Portal.consultar_cfdis(sesion, params)
    end

    test "descargar_xml/2 retorna {:error, :not_implemented}" do
      sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}
      assert {:error, {:not_implemented, _}} = Portal.descargar_xml(sesion, "uuid-test")
    end

    test "logout/1 retorna :ok" do
      sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}
      assert :ok = Portal.logout(sesion)
    end
  end
end
