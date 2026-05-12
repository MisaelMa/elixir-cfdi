defmodule Cfdi.ComplementoTest do
  @moduledoc """
  Verifica el flujo struct → mapa → XML para `cfdi:Complemento`.

  Caso de regresión: la discrepancia entre `:"cfdi:Complementos"` (campo
  plural del struct `Cfdi.Comprobante`) y `"cfdi:Complemento"` (key singular
  esperada en `@child_order` del renderer) impedía que los complementos
  aparecieran bajo el tag correcto `<cfdi:Complemento>` en el XML final.
  """

  use ExUnit.Case, async: true

  alias Cfdi.{Comprobante, Complemento, Emisor, Receptor}
  alias Cfdi.Complementos.Pago20

  # Arma un comprobante mínimo válido con un complemento Pagos 2.0.
  defp comprobante_con_complemento do
    pago20 = Pago20.new(%{Version: "2.0", TotalTrasladosBaseIVA16: "1000.00"})

    complemento = %Complemento{children: [pago20]}

    %Comprobante{
      Version: "4.0",
      Serie: "P",
      Folio: "1",
      Fecha: "2026-05-12T10:00:00",
      SubTotal: "0",
      Moneda: "XXX",
      Total: "0",
      TipoDeComprobante: "P",
      Exportacion: "01",
      LugarExpedicion: "06600"
    }
    |> Comprobante.add_emisor(%Emisor{
      Rfc: "EKU9003173C9",
      Nombre: "ESCUELA KEMPER URGATE",
      RegimenFiscal: "603"
    })
    |> Comprobante.add_receptor(%Receptor{
      Rfc: "CACX7605101P8",
      Nombre: "XOCHILT CASAS CHAVEZ",
      UsoCFDI: "CP01",
      DomicilioFiscalReceptor: "36257",
      RegimenFiscalReceptor: "612"
    })
    |> Comprobante.add_complemento(complemento)
  end

  # ── to_map ──────────────────────────────────────────────────────────────────

  test "to_map/1 emite 'cfdi:Complemento' (singular) como clave en el mapa" do
    cfdi = CFDI.new(comprobante_con_complemento())
    map = CFDI.to_map(cfdi)

    comprobante_body = map["cfdi:Comprobante"]

    refute Map.has_key?(comprobante_body, "cfdi:Complementos"),
           "el mapa no debe tener la key plural 'cfdi:Complementos'"

    assert Map.has_key?(comprobante_body, "cfdi:Complemento"),
           "el mapa debe tener la key singular 'cfdi:Complemento'"
  end

  test "to_map/1 bajo 'cfdi:Complemento' contiene el payload del complemento hijo" do
    cfdi = CFDI.new(comprobante_con_complemento())
    map = CFDI.to_map(cfdi)

    complemento_body = map["cfdi:Comprobante"]["cfdi:Complemento"]

    assert is_map(complemento_body),
           "'cfdi:Complemento' debe ser un mapa con los hijos del complemento"

    assert Map.has_key?(complemento_body, "pago20:Pagos"),
           "el cuerpo del complemento debe contener la key del complemento hijo 'pago20:Pagos'"
  end

  # ── to_xml ───────────────────────────────────────────────────────────────────

  test "to_xml/1 contiene exactamente un nodo <cfdi:Complemento> (singular)" do
    xml = CFDI.to_xml(CFDI.new(comprobante_con_complemento()))

    assert String.contains?(xml, "<cfdi:Complemento"),
           "el XML debe contener el tag de apertura <cfdi:Complemento"

    refute String.contains?(xml, "<cfdi:Complementos"),
           "el XML no debe contener el tag plural <cfdi:Complementos"

    # Exactamente UN nodo de apertura cfdi:Complemento al nivel del comprobante.
    # (Los complementos de concepto usan cfdi:ComplementoConcepto, no cfdi:Complemento.)
    occurrences =
      xml
      |> String.split("<cfdi:Complemento")
      |> length()
      |> Kernel.-(1)

    assert occurrences == 1,
           "esperaba exactamente 1 nodo <cfdi:Complemento, encontré #{occurrences}"
  end

  test "to_xml/1 el nodo <cfdi:Complemento> contiene el elemento hijo del complemento" do
    xml = CFDI.to_xml(CFDI.new(comprobante_con_complemento()))

    assert String.contains?(xml, "pago20:Pagos"),
           "el XML debe contener el elemento hijo pago20:Pagos dentro de cfdi:Complemento"
  end

  test "to_xml/1 es parseable y tiene el árbol esperado" do
    xml = CFDI.to_xml(CFDI.new(comprobante_con_complemento()))

    {:ok, tree} = Saxy.SimpleForm.parse_string(xml)

    # Encontramos cfdi:Complemento como hijo de cfdi:Comprobante.
    {_tag, _attrs, children} = tree
    complemento_nodes = Enum.filter(children, fn {t, _, _} -> t == "cfdi:Complemento" end)

    assert length(complemento_nodes) == 1,
           "debe haber exactamente 1 nodo cfdi:Complemento en el árbol XML"

    {_, _, complemento_children} = hd(complemento_nodes)
    pago_nodes = Enum.filter(complemento_children, fn {t, _, _} -> t == "pago20:Pagos" end)

    assert length(pago_nodes) == 1,
           "debe haber exactamente 1 nodo pago20:Pagos dentro de cfdi:Complemento"
  end

  # ── múltiples complementos ──────────────────────────────────────────────────

  test "múltiples children en un Complemento → todos aparecen bajo el mismo <cfdi:Complemento>" do
    pago20 = Pago20.new(%{Version: "2.0"})
    # Usamos Pago20 dos veces para simular múltiples hijos distintos
    complemento = %Complemento{children: [pago20]}

    comprobante =
      %Comprobante{
        Version: "4.0",
        Serie: "P",
        Folio: "1",
        Fecha: "2026-05-12T10:00:00",
        SubTotal: "0",
        Moneda: "XXX",
        Total: "0",
        TipoDeComprobante: "P",
        Exportacion: "01",
        LugarExpedicion: "06600"
      }
      |> Comprobante.add_emisor(%Emisor{
        Rfc: "EKU9003173C9",
        Nombre: "Test",
        RegimenFiscal: "603"
      })
      |> Comprobante.add_receptor(%Receptor{
        Rfc: "CACX7605101P8",
        Nombre: "Test Receptor",
        UsoCFDI: "CP01",
        DomicilioFiscalReceptor: "06600",
        RegimenFiscalReceptor: "612"
      })
      |> Comprobante.add_complemento(complemento)

    xml = CFDI.to_xml(CFDI.new(comprobante))

    {:ok, tree} = Saxy.SimpleForm.parse_string(xml)
    {_tag, _attrs, children} = tree
    complemento_nodes = Enum.filter(children, fn {t, _, _} -> t == "cfdi:Complemento" end)

    assert length(complemento_nodes) == 1,
           "debe haber exactamente 1 nodo cfdi:Complemento incluso con múltiples children"
  end
end
