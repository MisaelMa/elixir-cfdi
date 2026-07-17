defmodule Cfdi.Complementos.ComplementoTest do
  use ExUnit.Case, async: true

  alias Cfdi.Complementos.{Iedu, LeyendasFisc, Pago20, Spei}

  describe "accessors generados por el macro" do
    test "key/0, xmlns/0, xsd/0 y xmlns_key/0 son públicos" do
      assert Pago20.key() == "pago20:Pagos"
      assert Pago20.xmlns() == "http://www.sat.gob.mx/Pagos20"
      assert Pago20.xmlns_key() == "pago20"
      assert String.ends_with?(Pago20.xsd(), "Pagos20.xsd")
    end

    test "local_name/0 devuelve el nombre sin prefijo" do
      assert Pago20.local_name() == "Pagos"
      assert Iedu.local_name() == "instEducativas"
      assert Spei.local_name() == "Complemento_SPEI"
    end

    test "preserva prefijos con capitalización no trivial" do
      assert LeyendasFisc.xmlns_key() == "leyendasFisc"
      assert LeyendasFisc.local_name() == "LeyendasFiscales"
    end
  end

  describe "compatibilidad con la API previa al macro" do
    test "new/1 sigue envolviendo data opaca" do
      assert Pago20.new(%{version: "2.0"}) == %Pago20{data: %{version: "2.0"}}
    end

    test "get_complement/1 devuelve el mismo mapa que antes del refactor" do
      m = Pago20.new(%{version: "2.0"}) |> Pago20.get_complement()

      assert m == %{
               complement: %{version: "2.0"},
               key: "pago20:Pagos",
               schema_location:
                 "http://www.sat.gob.mx/Pagos20 http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd",
               xmlns: "http://www.sat.gob.mx/Pagos20",
               xmlns_key: "pago20"
             }
    end
  end

  describe "__complemento__/0" do
    test "marca el módulo como complemento para el Registry" do
      assert Pago20.__complemento__() == %{
               key: "pago20:Pagos",
               xmlns: "http://www.sat.gob.mx/Pagos20",
               xsd: "http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd"
             }
    end

    test "el módulo base NO se marca a sí mismo" do
      refute function_exported?(Cfdi.Complementos.Complemento, :__complemento__, 0)
    end
  end
end
