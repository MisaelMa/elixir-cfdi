defmodule Cfdi.Xml2Json.XmlToJsonTest do
  use ExUnit.Case

  test "parse_string/1 devuelve mapa anidado" do
    xml = ~s(<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0"/>)

    assert {:ok, %{"name" => "cfdi:Comprobante", "attributes" => attrs}} =
             Cfdi.Xml2Json.XmlToJson.parse_string(xml)

    assert attrs["Version"] == "4.0"
  end
end
