defmodule Cfdi.ValidadorTest do
  use ExUnit.Case

  test "validate/1 acepta comprobante mínimo coherente" do
    xml = """
    <cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" SubTotal="0" Total="0">
      <cfdi:Emisor Rfc="AAA010101AAA" Nombre="X" RegimenFiscal="601"/>
      <cfdi:Receptor Rfc="BBB020202BBB" Nombre="Y" UsoCFDI="G03"/>
    </cfdi:Comprobante>
    """

    assert {:ok, res} = Cfdi.Validador.validate(xml)
    assert res.valid?
  end

  test "validate/1 rechaza sin Emisor" do
    xml = """
    <cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" SubTotal="0" Total="0">
      <cfdi:Receptor Rfc="BBB020202BBB" Nombre="Y" UsoCFDI="G03"/>
    </cfdi:Comprobante>
    """

    assert {:ok, res} = Cfdi.Validador.validate(xml)
    refute res.valid?
    assert Enum.any?(res.issues, &(&1.rule_id == :emisor_exists))
  end
end
