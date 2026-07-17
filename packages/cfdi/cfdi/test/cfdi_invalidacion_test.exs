defmodule CFDIInvalidacionTest do
  use ExUnit.Case, async: true

  alias Cfdi.{Complemento, Comprobante}
  alias Cfdi.Complementos.{Pago20, Tfd}

  @xml_dir Path.expand("../../../files/xml", __DIR__)

  # CFDI real timbrado: trae `Sello` en el comprobante y `tfd:TimbreFiscalDigital`
  # en el complemento.
  defp timbrado!() do
    xml = File.read!(Path.join(@xml_dir, "535BBAC7-85BB-45B0-B067-C8198CD5A52B.xml"))
    {:ok, cfdi} = CFDI.from_xml(xml)
    cfdi
  end

  describe "premisa: from_xml preserva el timbre (no lo dispara la lectura)" do
    test "un CFDI recién parseado sigue sellado y timbrado" do
      cfdi = timbrado!()

      assert CFDI.sellado?(cfdi)
      assert CFDI.timbrado?(cfdi)
      assert cfdi.comprobante."Sello" != nil
    end
  end

  describe "mutar contenido invalida el sello y el timbre" do
    test "add_concepto limpia Sello y elimina el TFD" do
      comp = timbrado!().comprobante
      mutado = Comprobante.add_concepto(comp, %{ClaveProdServ: "010101", Importe: "1"})

      assert mutado."Sello" == nil
      refute CFDI.timbrado?(CFDI.new(mutado))
      assert CFDI.uuid(CFDI.new(mutado)) == nil
    end

    test "cada setter de contenido invalida" do
      comp = timbrado!().comprobante

      mutaciones = [
        &Comprobante.add_emisor(&1, %{Rfc: "XAXX010101000"}),
        &Comprobante.add_receptor(&1, %{Rfc: "XAXX010101000"}),
        &Comprobante.add_impuesto(&1, %{TotalImpuestosTrasladados: "1"}),
        &Comprobante.add_relacionado(&1, %{TipoRelacion: "04"}),
        &Comprobante.add_informacion_global(&1, %{Periodicidad: "01"}),
        &Comprobante.add_concepto(&1, %{ClaveProdServ: "1"})
      ]

      for mutar <- mutaciones do
        assert mutar.(comp)."Sello" == nil
        refute CFDI.timbrado?(CFDI.new(mutar.(comp)))
      end
    end

    test "conserva otros complementos, sólo elimina el TFD" do
      comp =
        %Comprobante{Version: "4.0", Sello: "SELLO-VIEJO"}
        |> Comprobante.add_complemento(%Complemento{
          children: [Pago20.new(%{Version: "2.0"}), Tfd.new(%{UUID: "abc"})]
        })

      mutado = Comprobante.add_concepto(comp, %{ClaveProdServ: "1"})

      restantes =
        (Map.get(mutado, :"cfdi:Complementos") || [])
        |> Enum.flat_map(fn %Complemento{children: ch} -> ch || [] end)

      assert Enum.any?(restantes, &is_struct(&1, Pago20))
      refute Enum.any?(restantes, &is_struct(&1, Tfd))
      assert mutado."Sello" == nil
    end
  end

  describe "la addenda NO invalida — es lo único tocable en un timbrado" do
    test "set_addenda preserva Sello y TFD" do
      comp = timbrado!().comprobante
      con_addenda = Comprobante.set_addenda(comp, %{"x:Nota" => %{v: "1"}})

      assert con_addenda."Sello" == comp."Sello"
      assert con_addenda."Sello" != nil
      assert CFDI.timbrado?(CFDI.new(con_addenda))
    end
  end

  describe "desellar/1 — invalidación explícita" do
    test "para las mutaciones que la lib no puede interceptar (cambios de atributo)" do
      # Cambiar un atributo con la sintaxis de struct NO pasa por ningún setter,
      # así que la lib no lo puede interceptar. `desellar/1` es la palanca manual.
      comp = %{timbrado!().comprobante | Total: "999999.00"}
      assert comp."Sello" != nil

      desellado = Comprobante.desellar(comp)

      assert desellado."Sello" == nil
      refute CFDI.timbrado?(CFDI.new(desellado))
    end

    test "CFDI.desellar/1 opera sobre el documento completo" do
      desellado = CFDI.desellar(timbrado!())

      refute CFDI.sellado?(desellado)
      refute CFDI.timbrado?(desellado)
    end
  end

  describe "no rompe el flujo de construcción normal" do
    test "mutar un borrador sin sellar es un no-op de invalidación" do
      comp =
        %Comprobante{Version: "4.0"}
        |> Comprobante.add_emisor(%{Rfc: "EKU9003173C9"})
        |> Comprobante.add_concepto(%{ClaveProdServ: "1", Importe: "1"})

      assert comp."Sello" == nil
      assert %Cfdi.Emisor{} = Map.get(comp, :"cfdi:Emisor")
      assert [%Cfdi.Concepto{}] = Map.get(comp, :"cfdi:Conceptos")
    end
  end
end
