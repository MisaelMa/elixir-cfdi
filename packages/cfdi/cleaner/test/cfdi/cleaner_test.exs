defmodule Cfdi.CleanerTest do
  use ExUnit.Case

  test "clean/1 removes stylesheet PI and addenda" do
    xml = """
    <?xml version="1.0"?>
    <?xml-stylesheet type="text/xsl" href="a.xsl"?>
    <cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0">
    <cfdi:Addenda><x>y</x></cfdi:Addenda>
    </cfdi:Comprobante>
    """

    assert {:ok, out} = Cfdi.Cleaner.clean(xml)
    refute out =~ "xml-stylesheet"
    refute out =~ "Addenda"
    assert out =~ "Comprobante"
  end

  test "clean/1 strips non-SAT xmlns on root pattern" do
    xml = ~s(<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:ext="http://vendor.example/ns" Version="4.0"/>)

    assert {:ok, out} = Cfdi.Cleaner.clean(xml)
    refute out =~ "vendor.example"
  end
end
