defmodule Cfdi.Xml.CfdiTest do
  use ExUnit.Case

  alias Cfdi.Xml.Cfdi

  test "to_xml/1 genera comprobante mínimo" do
    xml =
      Cfdi.new(Version: "4.0", Fecha: "2024-01-01T12:00:00")
      |> Cfdi.emisor(%{Rfc: "AAA010101AAA", Nombre: "ACME", RegimenFiscal: "601"})
      |> Cfdi.receptor(%{Rfc: "BBB020202BBB", Nombre: "Cliente", UsoCFDI: "G03"})
      |> Cfdi.to_xml()

    assert xml =~ "cfdi:Comprobante"
    assert xml =~ "Version=\"4.0\""
    assert xml =~ "cfdi:Emisor"
  end

  test "get_json/1" do
    json =
      Cfdi.new(Version: "4.0")
      |> Cfdi.get_json()

    assert json =~ "4.0"
  end
end
