defmodule Cfdi.ComplementosTest do
  use ExUnit.Case

  alias Cfdi.Complementos.{LeyendasFisc, Nomina12, Pago20, Spei, Tfd}

  test "Pago20 expone metadatos SAT Pagos 2.0" do
    c = Pago20.new(%{version: "2.0"})
    m = Pago20.get_complement(c)

    assert m.key == "pago20:Pagos"
    assert m.xmlns == "http://www.sat.gob.mx/Pagos20"
    assert m.xmlns_key == "pago20"
    assert m.complement == %{version: "2.0"}
    assert String.contains?(m.schema_location, "Pagos20.xsd")
  end

  test "Tfd usa TimbreFiscalDigital" do
    m = Tfd.new(%{}) |> Tfd.get_complement()

    assert m.key == "tfd:TimbreFiscalDigital"
    assert m.xmlns == "http://www.sat.gob.mx/TimbreFiscalDigital"
  end

  test "Nomina12" do
    m = Nomina12.new(%{foo: 1}) |> Nomina12.get_complement()
    assert m.xmlns_key == "nomina12"
    assert m.key == "nomina12:Nomina"
  end

  test "LeyendasFisc preserva prefijo xmlns camelCase" do
    m = LeyendasFisc.new(%{}) |> LeyendasFisc.get_complement()
    assert m.xmlns_key == "leyendasFisc"
  end

  test "Spei usa elemento Complemento_SPEI" do
    m = Spei.new(%{}) |> Spei.get_complement()
    assert m.key == "spei:Complemento_SPEI"
  end
end
