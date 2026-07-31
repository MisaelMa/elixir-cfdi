defmodule CFDITest do
  use ExUnit.Case, async: true

  alias Cfdi.{Comprobante, Emisor, Receptor}

  test "to_map/1 proyecta emisor y receptor bajo cfdi:Comprobante" do
    comprobante =
      %Comprobante{}
      |> Comprobante.add_emisor(%Emisor{
        Rfc: "EKU9003173C9",
        Nombre: "ESCUELA KEMPER URGATE",
        RegimenFiscal: "603"
      })
      |> Comprobante.add_receptor(%Receptor{
        Rfc: "CACX7605101P8",
        Nombre: "XOCHILT CASAS CHAVEZ",
        UsoCFDI: "G03",
        DomicilioFiscalReceptor: "36257",
        RegimenFiscalReceptor: "612"
      })

    cfdi = CFDI.new(comprobante)
    IO.inspect(CFDI.to_map(cfdi, ns: false))
    IO.inspect(CFDI.to_map(cfdi, ns: true))
    IO.puts("\n=== to_json compact ===")
    IO.puts(CFDI.to_json(cfdi, ns: false, pretty: true))
    IO.puts("\n=== to_json pretty ===")
    IO.puts(CFDI.to_json(cfdi, pretty: true))
    IO.puts("\n=== to_xml pretty ===")
    IO.puts(CFDI.to_xml(cfdi, pretty: true))
    IO.puts("\n=== to_xml compact ===")
    IO.puts(CFDI.to_xml(cfdi))

    # `to_map` proyecta DATOS: las declaraciones de namespace son plomería de
    # XML y no aparecen (viven sólo en el camino de `to_xml/2`). Ver
    # CFDIToMapTest.
    assert CFDI.to_map(cfdi) == %{
             "cfdi:Comprobante" => %{
               "cfdi:Emisor" => %{
                 Nombre: "ESCUELA KEMPER URGATE",
                 RegimenFiscal: "603",
                 Rfc: "EKU9003173C9"
               },
               "cfdi:Receptor" => %{
                 DomicilioFiscalReceptor: "36257",
                 Nombre: "XOCHILT CASAS CHAVEZ",
                 RegimenFiscalReceptor: "612",
                 Rfc: "CACX7605101P8",
                 UsoCFDI: "G03"
               }
             }
           }
  end

  describe "to_xml/2 schemaLocation" do
    defp comprobante_a_mano do
      %Comprobante{}
      |> Comprobante.add_emisor(%Emisor{
        Rfc: "EKU9003173C9",
        Nombre: "ESCUELA KEMPER URGATE",
        RegimenFiscal: "603"
      })
      |> Comprobante.add_receptor(%Receptor{
        Rfc: "CACX7605101P8",
        Nombre: "XOCHILT CASAS CHAVEZ",
        UsoCFDI: "G03",
        DomicilioFiscalReceptor: "36257",
        RegimenFiscalReceptor: "612"
      })
    end

    test "un comprobante armado a mano emite xsi:schemaLocation (evita CC3001)" do
      xml = comprobante_a_mano() |> CFDI.new() |> CFDI.to_xml()

      assert xml =~
               ~s(xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd")
    end

    test "declara ambos namespaces junto al schemaLocation en la raíz" do
      xml = comprobante_a_mano() |> CFDI.new() |> CFDI.to_xml()

      assert xml =~ ~s(xmlns:cfdi="http://www.sat.gob.mx/cfd/4")
      assert xml =~ ~s(xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance")
      assert xml =~ "xsi:schemaLocation="
    end

    test "un schema_location explícito gana al default (dedup por namespace)" do
      # el usuario fija el par cfd/4 con un xsd propio; el seed base NO lo pisa
      # porque deduplica por namespace.
      xml =
        comprobante_a_mano()
        |> Comprobante.add_schema_location(
          {"http://www.sat.gob.mx/cfd/4", "http://ejemplo.test/custom.xsd"}
        )
        |> CFDI.new()
        |> CFDI.to_xml()

      assert xml =~
               ~s(xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://ejemplo.test/custom.xsd")
    end
  end

  describe "modelo eager — las listas del struct son la fuente de la verdad" do
    test "add_complemento siembra xmlns y schema_location EN EL STRUCT" do
      pago20 = Cfdi.Complementos.Pago20.new(%{Version: "2.0"})

      cfdi =
        comprobante_a_mano()
        |> Comprobante.add_complemento(%Cfdi.Complemento{children: [pago20]})
        |> CFDI.new()

      comp = cfdi.comprobante

      # base + complemento, ya materializados en el struct (no al serializar)
      assert {:cfdi, "http://www.sat.gob.mx/cfd/4"} in comp.xmlns
      assert {"pago20", "http://www.sat.gob.mx/Pagos20"} in comp.xmlns

      assert {"http://www.sat.gob.mx/cfd/4",
              "http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd"} in comp.schema_location

      assert {"http://www.sat.gob.mx/Pagos20",
              "http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd"} in comp.schema_location
    end

    test "new/1 siembra el par base según Version — 3.3 → cfd/3" do
      comp = %Comprobante{Version: "3.3"} |> CFDI.new() |> Map.fetch!(:comprobante)

      assert {:cfdi, "http://www.sat.gob.mx/cfd/3"} in comp.xmlns

      assert {"http://www.sat.gob.mx/cfd/3",
              "http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd"} in comp.schema_location
    end

    test "el mismo complemento en varios lugares no se duplica" do
      pago20 = Cfdi.Complementos.Pago20.new(%{Version: "2.0"})

      comp =
        comprobante_a_mano()
        |> Comprobante.add_complemento(%Cfdi.Complemento{children: [pago20]})
        |> Comprobante.add_complemento(%Cfdi.Complemento{children: [pago20]})
        |> CFDI.new()
        |> Map.fetch!(:comprobante)

      pares =
        Enum.filter(comp.schema_location, fn {ns, _} -> ns == "http://www.sat.gob.mx/Pagos20" end)

      assert length(pares) == 1
    end
  end
end
