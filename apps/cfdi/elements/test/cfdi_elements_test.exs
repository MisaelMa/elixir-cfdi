defmodule Cfdi.ElementsTest do
  use ExUnit.Case, async: true

  alias Cfdi.Elements.{Elemento, Comprobante, Complementos}

  test "Elemento parses qualified name" do
    elem = Elemento.new("cfdi:Comprobante")
    assert elem.prefix == "cfdi"
    assert elem.name == "Comprobante"
    assert elem.tag == "cfdi:Comprobante"
  end

  test "Comprobante constants" do
    assert Comprobante.comprobante() == "cfdi:Comprobante"
    assert Comprobante.emisor() == "cfdi:Emisor"
  end

  test "Complementos constants" do
    assert Complementos.cartaporte() == "cartaporte31:CartaPorte"
    assert Complementos.vehiculo_usado() == "vehiculousado:VehiculoUsado"
  end
end
