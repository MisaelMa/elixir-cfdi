defmodule Cfdi.CatalogosTest do
  use ExUnit.Case, async: true

  alias Cfdi.Catalogos.{FormaPago, MetodoPago, TipoComprobante, Impuesto, UsoCFDI, Exportacion, RegimenFiscal}

  test "FormaPago returns correct code" do
    assert FormaPago.value(:efectivo) == "01"
    assert FormaPago.value(:transferencia_electronica) == "03"
    assert FormaPago.valid?("01")
    refute FormaPago.valid?("ZZ")
  end

  test "MetodoPago returns correct code" do
    assert MetodoPago.value(:pago_en_una_exhibicion) == "PUE"
    assert MetodoPago.from_code("PPD") == {:ok, :pago_en_parcialidades_diferido}
  end

  test "TipoComprobante returns correct code" do
    assert TipoComprobante.value(:ingreso) == "I"
    assert TipoComprobante.from_code("P") == {:ok, :pago}
  end

  test "Impuesto returns correct code" do
    assert Impuesto.value(:iva) == "002"
    assert Impuesto.from_code("001") == {:ok, :isr}
  end

  test "UsoCFDI returns correct code" do
    assert UsoCFDI.value(:gastos_en_general) == "G03"
    assert UsoCFDI.valid?("G01")
  end

  test "Exportacion returns correct code" do
    assert Exportacion.value(:no_aplica) == "01"
    assert Exportacion.valid?("02")
  end

  test "RegimenFiscal list has entries" do
    assert length(RegimenFiscal.list()) == 22
    assert RegimenFiscal.valid?(601)
    assert RegimenFiscal.valid?("601")
    assert RegimenFiscal.descripcion(601) == "General de Ley Personas Morales"
  end
end
