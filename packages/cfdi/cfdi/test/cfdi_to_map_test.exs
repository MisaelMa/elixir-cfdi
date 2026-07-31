defmodule CFDIToMapTest do
  use ExUnit.Case, async: true

  alias Cfdi.{Comprobante, Concepto, Emisor, Receptor}

  @xml_dir Path.expand("../../../files/xml", __DIR__)

  # CFDI real timbrado: trae xmlns:cfdi/xsi + schemaLocation en la raíz y
  # xmlns:tfd + schemaLocation dentro del complemento TFD. Es el peor caso de
  # "ruido de namespaces" para probar que to_map devuelve datos limpios.
  defp timbrado!() do
    xml = File.read!(Path.join(@xml_dir, "535BBAC7-85BB-45B0-B067-C8198CD5A52B.xml"))
    {:ok, cfdi} = CFDI.from_xml(xml)
    cfdi
  end

  # Junta todas las llaves del árbol, a cualquier profundidad, como strings.
  defp llaves(map) when is_map(map) do
    Enum.flat_map(map, fn {k, v} -> [to_string(k) | llaves(v)] end)
  end

  defp llaves(list) when is_list(list), do: Enum.flat_map(list, &llaves/1)
  defp llaves(_), do: []

  # Comprobante con complemento iedu en su lugar real: a nivel Concepto
  # (`cfdi:ComplementoConcepto`). Ejercita el camino que inyecta `xmlns:iedu` +
  # su par de schemaLocation EN LA RAÍZ (el schemaLocation siempre vive ahí,
  # aunque el complemento cuelgue de un concepto), para confirmar que `to_map`
  # igual proyecta datos limpios, sin esa plomería.
  defp con_iedu!() do
    concepto =
      %Concepto{
        ClaveProdServ: "86121500",
        Cantidad: "1",
        ClaveUnidad: "E48",
        Descripcion: "Colegiatura",
        ValorUnitario: "1000",
        Importe: "1000",
        ObjetoImp: "02"
      }
      |> Concepto.add_complemento(
        Cfdi.Complementos.Iedu.new(%{
          version: "1.0",
          nombreAlumno: "Pedro Pérez",
          CURP: "PEPE900101HDFRRD09",
          nivelEducativo: "Preescolar",
          autRVOE: "AUT-001",
          rfcPago: "PEPE900101A11"
        })
      )

    %Comprobante{
      Version: "4.0",
      Serie: "A",
      Folio: "1",
      Fecha: "2026-07-31T10:00:00",
      SubTotal: "1000.00",
      Moneda: "MXN",
      Total: "1000.00",
      TipoDeComprobante: "I",
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
      UsoCFDI: "G03",
      DomicilioFiscalReceptor: "36257",
      RegimenFiscalReceptor: "612"
    })
    |> Comprobante.add_concepto(concepto)
    |> CFDI.new()
  end

  describe "to_map devuelve datos, no plomería de XML" do
    test "no hay declaraciones xmlns en ningún nivel (ns: true)" do
      todas = timbrado!() |> CFDI.to_map() |> llaves()

      refute Enum.any?(todas, &(&1 == "xmlns" or String.starts_with?(&1, "xmlns:"))),
             "se coló una declaración xmlns: #{inspect(Enum.filter(todas, &String.contains?(&1, "xmlns")))}"
    end

    test "no hay schemaLocation en ningún nivel (ns: true)" do
      todas = timbrado!() |> CFDI.to_map() |> llaves()

      refute Enum.any?(todas, &String.contains?(&1, "schemaLocation"))
    end

    test "tampoco con ns: false" do
      todas = timbrado!() |> CFDI.to_map(ns: false) |> llaves()

      refute Enum.any?(todas, &String.contains?(&1, "xmlns"))
      refute Enum.any?(todas, &String.contains?(&1, "schemaLocation"))
    end

    test "el complemento TFD conserva sus datos, pierde su plomería" do
      map = CFDI.to_map(timbrado!(), ns: false)
      tfd = get_in(map, ["Comprobante", "Complemento", "tfd:TimbreFiscalDigital"])

      # Los datos fiscales del timbre siguen ahí…
      assert tfd["UUID"] == "535BBAC7-85BB-45B0-B067-C8198CD5A52B"
      assert tfd["NoCertificadoSAT"] == "00001000000705250068"
      # …pero sin xmlns:tfd ni schemaLocation.
      refute Map.has_key?(tfd, "xmlns:tfd")
      refute Map.has_key?(tfd, "xsi:schemaLocation")
    end

    test "los datos fiscales de la raíz sí están (no barremos de más)" do
      comp = CFDI.to_map(timbrado!())["cfdi:Comprobante"]

      assert comp[:Version] == "4.0"
      assert comp[:Total] == "57750.00"
      assert comp[:Sello] != nil
      assert %{Rfc: "SAGL901017EH9"} = comp["cfdi:Emisor"]
    end
  end

  describe "complemento iedu (en Concepto) — to_map lo limpia" do
    test "no se cuela xmlns:iedu ni schemaLocation en ningún nivel (ns: true)" do
      todas = con_iedu!() |> CFDI.to_map() |> llaves()

      refute Enum.any?(todas, &String.contains?(&1, "xmlns")),
             "se coló plomería xmlns: #{inspect(Enum.filter(todas, &String.contains?(&1, "xmlns")))}"

      refute Enum.any?(todas, &String.contains?(&1, "schemaLocation"))
    end

    test "los datos del iedu se conservan bajo cfdi:ComplementoConcepto (ns: true)" do
      [concepto] =
        con_iedu!()
        |> CFDI.to_map()
        |> get_in(["cfdi:Comprobante", "cfdi:Conceptos", "cfdi:Concepto"])

      iedu = concepto["cfdi:ComplementoConcepto"]["iedu:instEducativas"]

      assert iedu[:nombreAlumno] == "Pedro Pérez"
      assert iedu[:CURP] == "PEPE900101HDFRRD09"
      assert iedu[:autRVOE] == "AUT-001"
    end

    test "mismos datos con ns: false (llaves string)" do
      [concepto] =
        con_iedu!()
        |> CFDI.to_map(ns: false)
        |> get_in(["Comprobante", "Conceptos", "Concepto"])

      iedu = concepto["ComplementoConcepto"]["iedu:instEducativas"]

      assert iedu["nombreAlumno"] == "Pedro Pérez"
      assert iedu["nivelEducativo"] == "Preescolar"
    end

    test "contraste: to_xml SÍ emite en la RAÍZ la plomería que to_map quita" do
      xml = con_iedu!() |> CFDI.to_xml()

      assert xml =~ ~s(xmlns:iedu="http://www.sat.gob.mx/iedu")

      assert xml =~
               "http://www.sat.gob.mx/iedu http://www.sat.gob.mx/sitio_internet/cfd/iedu/iedu.xsd"
    end
  end

  describe "opción :ns" do
    test "true (default) — prefijo cfdi: y atributos como átomos" do
      comp = CFDI.to_map(timbrado!())["cfdi:Comprobante"]

      assert is_map(comp["cfdi:Emisor"])
      assert comp["cfdi:Emisor"][:Rfc] == "SAGL901017EH9"
    end

    test "false — sin prefijo, llaves uniformes" do
      comp = CFDI.to_map(timbrado!(), ns: false)["Comprobante"]

      assert is_map(comp["Emisor"])
      assert comp["Emisor"]["Rfc"] == "SAGL901017EH9"
    end
  end

  describe "opción :keys (sólo con ns: false)" do
    test ":string (default) — todas las llaves son strings" do
      comp = CFDI.to_map(timbrado!(), ns: false)["Comprobante"]
      assert comp["Emisor"]["Rfc"] == "SAGL901017EH9"
    end

    test ":atom — todas las llaves son átomos" do
      map = CFDI.to_map(timbrado!(), ns: false, keys: :atom)
      assert map[:Comprobante][:Emisor][:Rfc] == "SAGL901017EH9"
    end
  end

  describe "opción :case (sólo con ns: false)" do
    test ":as_is (default) — PascalCase como el XSD" do
      comp = CFDI.to_map(timbrado!(), ns: false)["Comprobante"]
      assert Map.has_key?(comp["Emisor"], "RegimenFiscal")
    end

    test ":camel — primera letra en minúscula" do
      map = CFDI.to_map(timbrado!(), ns: false, case: :camel)
      emisor = map["comprobante"]["emisor"]

      assert emisor["rfc"] == "SAGL901017EH9"
      assert Map.has_key?(emisor, "regimenFiscal")
    end
  end

  describe "to_json hereda la limpieza" do
    test "el JSON no contiene xmlns ni schemaLocation" do
      json = CFDI.to_json(timbrado!())

      refute json =~ "xmlns"
      refute json =~ "schemaLocation"
      assert json =~ "SAGL901017EH9"
    end
  end
end
