defmodule Cfdi.Complementos.ChildOrderTest do
  use ExUnit.Case, async: true

  alias Cfdi.Complementos.ChildOrder

  describe "for_tag/1" do
    test "Pago20 — Totales va antes que Pago" do
      assert ChildOrder.for_tag("pago20:Pagos") == ["pago20:Totales", "pago20:Pago"]
    end

    test "Nomina12 — el orden del Anexo 20, no el alfabético" do
      assert ChildOrder.for_tag("nomina12:Nomina") == [
               "nomina12:Emisor",
               "nomina12:Receptor",
               "nomina12:Percepciones",
               "nomina12:Deducciones",
               "nomina12:OtrosPagos",
               "nomina12:Incapacidades"
             ]
    end

    test "CartaPorte31" do
      assert ChildOrder.for_tag("cartaporte31:CartaPorte") == [
               "cartaporte31:RegimenesAduaneros",
               "cartaporte31:Ubicaciones",
               "cartaporte31:Mercancias",
               "cartaporte31:FiguraTransporte"
             ]
    end

    test "un complemento plano no tiene entrada — no hay orden que imponer" do
      assert ChildOrder.for_tag("iedu:instEducativas") == nil
      assert ChildOrder.for_tag("tfd:TimbreFiscalDigital") == nil
    end

    test "un tag desconocido devuelve nil" do
      assert ChildOrder.for_tag("foo:Bar") == nil
    end
  end

  describe "all/0" do
    test "sólo incluye elementos con 2+ hijos distintos" do
      for {tag, orden} <- ChildOrder.all() do
        assert length(orden) > 1, "#{tag} no debería estar en el catálogo"
        assert length(Enum.uniq(orden)) == length(orden), "#{tag} tiene hijos duplicados"
      end
    end

    test "cubre los complementos anidados que audité" do
      tags = ChildOrder.all() |> Map.keys()

      for esperado <- [
            "pago20:Pagos",
            "nomina12:Nomina",
            "cartaporte31:CartaPorte",
            "cce20:ComercioExterior",
            "gceh:Erogacion"
          ] do
        assert esperado in tags
      end
    end
  end
end
