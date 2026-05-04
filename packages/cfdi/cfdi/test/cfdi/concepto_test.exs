defmodule Cfdi.ConceptoTest do
  use ExUnit.Case, async: true

  alias Cfdi.Concepto
  alias Cfdi.Concepto.{ACuentaTerceros, Complemento, CuentaPredial, InformacionAduanera, Parte}

  defp base_concepto do
    %Concepto{
      ClaveProdServ: "01010101",
      NoIdentificacion: "12345",
      Cantidad: "1",
      ClaveUnidad: "H87",
      Unidad: "Pieza",
      Descripcion: "Producto de prueba",
      ValorUnitario: "100.00",
      Importe: "100.00",
      ObjetoImp: "01"
    }
  end

  defp xml_fragment(element) do
    element
    |> XmlBuilder.generate(format: :none)
    |> IO.iodata_to_binary()
  end

  test "add_informacion_aduanera/2 acepta string y struct" do
    c =
      base_concepto()
      |> Concepto.add_informacion_aduanera("15  48  0301 0001234")
      |> Concepto.add_informacion_aduanera(%InformacionAduanera{
        NumeroPedimento: "15  48  0301 9999999"
      })

    assert length(c.informacion_aduanera) == 2
    xml = xml_fragment(Concepto.to_element(c))
    assert xml =~ ~s(<cfdi:InformacionAduanera NumeroPedimento="15  48  0301 0001234"/>)
    assert xml =~ ~s(<cfdi:InformacionAduanera NumeroPedimento="15  48  0301 9999999"/>)
  end

  test "set_cuenta_predial/2 emite <cfdi:CuentaPredial Numero=.../>" do
    c = Concepto.set_cuenta_predial(base_concepto(), "1234567890")
    assert c.cuenta_predial == %CuentaPredial{Numero: "1234567890"}
    assert xml_fragment(Concepto.to_element(c)) =~ ~s(<cfdi:CuentaPredial Numero="1234567890"/>)
  end

  test "set_a_cuenta_terceros/2 emite <cfdi:ACuentaTerceros .../>" do
    c =
      Concepto.set_a_cuenta_terceros(base_concepto(), %{
        RfcACuentaTerceros: "XAXX010101000",
        NombreACuentaTerceros: "Tercero Ejemplo",
        DomicilioFiscalACuentaTerceros: "54321",
        RegimenFiscalACuentaTerceros: "601"
      })

    assert %ACuentaTerceros{RfcACuentaTerceros: "XAXX010101000"} = c.a_cuenta_terceros
    xml = xml_fragment(Concepto.to_element(c))
    assert xml =~ ~s(cfdi:ACuentaTerceros)
    assert xml =~ ~s(RfcACuentaTerceros="XAXX010101000")
  end

  test "add_parte/2 emite <cfdi:Parte .../>" do
    c =
      Concepto.add_parte(base_concepto(), %{
        ClaveProdServ: "01010101",
        NoIdentificacion: "54321",
        Cantidad: "2",
        Unidad: "Pieza",
        Descripcion: "Parte de prueba",
        ValorUnitario: "50.00",
        Importe: "100.00"
      })

    assert [%Parte{NoIdentificacion: "54321"}] = c.parte
    xml = xml_fragment(Concepto.to_element(c))
    assert xml =~ ~s(<cfdi:Parte )
    assert xml =~ ~s(NoIdentificacion="54321")
  end

  test "add_parte_informacion_aduanera/2 anida bajo la última parte" do
    c =
      base_concepto()
      |> Concepto.add_parte(%{ClaveProdServ: "01010101", Cantidad: "1", Descripcion: "P"})
      |> Concepto.add_parte_informacion_aduanera("15  48  0301 0001234")

    [%Parte{informacion_aduanera: [%InformacionAduanera{NumeroPedimento: ped}]}] = c.parte
    assert ped == "15  48  0301 0001234"

    xml = xml_fragment(Concepto.to_element(c))
    assert xml =~ ~s(<cfdi:Parte)
    assert xml =~ ~s(<cfdi:InformacionAduanera NumeroPedimento="15  48  0301 0001234"/>)
  end

  test "add_parte_informacion_aduanera/2 es no-op cuando no hay partes" do
    c = Concepto.add_parte_informacion_aduanera(base_concepto(), "cualquier")
    assert c == base_concepto()
  end

  test "add_complemento/2 envuelve hijos en <cfdi:ComplementoConcepto>" do
    iedu =
      Cfdi.Complementos.Iedu.new(%{
        version: "1.0",
        CURP: "PEPE900101HDFRRD09"
      })

    c = Concepto.add_complemento(base_concepto(), iedu)

    assert %Complemento{complementos: [^iedu]} = c.complemento
    xml = xml_fragment(Concepto.to_element(c))
    assert xml =~ ~s(<cfdi:ComplementoConcepto>)
    assert xml =~ ~s(<iedu:instEducativas)
    assert xml =~ ~s(CURP="PEPE900101HDFRRD09")
    assert xml =~ ~s(</cfdi:ComplementoConcepto>)
  end

  test "add_complemento/2 acumula múltiples complementos" do
    iedu1 = Cfdi.Complementos.Iedu.new(%{CURP: "C1"})
    iedu2 = Cfdi.Complementos.Iedu.new(%{CURP: "C2"})

    c =
      base_concepto()
      |> Concepto.add_complemento(iedu1)
      |> Concepto.add_complemento(iedu2)

    assert %Complemento{complementos: [^iedu1, ^iedu2]} = c.complemento
  end
end
