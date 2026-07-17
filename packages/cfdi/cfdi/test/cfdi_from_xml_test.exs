defmodule CFDIFromXmlTest do
  use ExUnit.Case, async: true

  alias Cfdi.Comprobante
  alias Cfdi.Complementos.{Iedu, Tfd}

  @xml_dir Path.expand("../../../files/xml", __DIR__)

  defp fixture(name), do: Path.join(@xml_dir, name)
  defp read(name), do: name |> fixture() |> File.read!()

  defp completo!() do
    {:ok, cfdi} = CFDI.from_xml(read("cfdi-completo.xml"))
    cfdi
  end

  describe "from_xml/2 — atributos del comprobante" do
    test "reconstruye los atributos declarados en el DSL" do
      {:ok, cfdi} = CFDI.from_xml(read("535BBAC7-85BB-45B0-B067-C8198CD5A52B.xml"))
      comp = cfdi.comprobante

      assert %Comprobante{} = comp
      assert comp."Version" == "4.0"
      assert comp."Fecha" == "2026-03-03T09:50:20"
      assert comp."FormaPago" == "03"
      assert comp."NoCertificado" == "00001000000710961860"
    end

    test "preserva el schemaLocation y los namespaces declarados" do
      {:ok, cfdi} = CFDI.from_xml(read("535BBAC7-85BB-45B0-B067-C8198CD5A52B.xml"))

      assert cfdi.comprobante.schema_location =~ "cfdv40.xsd"
    end
  end

  describe "from_xml/2 — emisor y receptor" do
    test "los reconstruye como structs tipados" do
      comp = completo!().comprobante

      emisor = Map.get(comp, :"cfdi:Emisor")
      receptor = Map.get(comp, :"cfdi:Receptor")

      assert %Cfdi.Emisor{} = emisor
      assert emisor."Rfc" == "EKU9003173C9"
      assert emisor."Nombre" == "ESCUELA KEMPER URGATE"
      assert emisor."RegimenFiscal" == "603"

      assert %Cfdi.Receptor{} = receptor
      assert receptor."Rfc" == "CACX7605101P8"
      assert receptor."UsoCFDI" == "G03"
      assert receptor."RegimenFiscalReceptor" == "612"
    end
  end

  describe "from_xml/2 — conceptos" do
    test "reconstruye la lista de conceptos con sus atributos" do
      comp = completo!().comprobante
      conceptos = Map.get(comp, :"cfdi:Conceptos")

      assert [%Cfdi.Concepto{} = concepto] = conceptos
      assert concepto."ClaveProdServ" == "86121500"
      assert concepto."Descripcion" == "Mensualidad - diciembre"
      assert concepto."ValorUnitario" == "5000"
    end

    test "desanida Impuestos/Traslados/Traslado del concepto a la lista traslados" do
      comp = completo!().comprobante
      [concepto] = Map.get(comp, :"cfdi:Conceptos")

      assert [%Cfdi.Traslado{} = t] = concepto.traslados
      assert t."Base" == "1"
      assert t."Impuesto" == "002"
      assert t."TipoFactor" == "Exento"
      assert concepto.retenciones in [nil, []]
    end

    test "un concepto sin impuestos no inventa listas" do
      {:ok, cfdi} = CFDI.from_xml(read("emisor-receptor.xml"))
      conceptos = Map.get(cfdi.comprobante, :"cfdi:Conceptos")

      assert conceptos in [nil, []]
    end
  end

  describe "from_xml/2 — impuestos globales" do
    test "reconstruye el bloque Impuestos del comprobante" do
      comp = completo!().comprobante
      impuestos = Map.get(comp, :"cfdi:Impuestos")

      assert %Cfdi.Impuestos{} = impuestos
      assert impuestos."TotalImpuestosTrasladados" == "0.16"
      assert [%Cfdi.Traslado{} = t] = impuestos.traslados
      assert t."TasaOCuota" == "0.160000"
      assert t."Importe" == "0.16"
    end
  end

  describe "from_xml/2 — complementos" do
    test "resuelve tfd:TimbreFiscalDigital al módulo Tfd via Registry" do
      comp = completo!().comprobante
      [%Cfdi.Complemento{children: children}] = Map.get(comp, :"cfdi:Complementos")

      assert [%Tfd{} = tfd] = children
      assert tfd.data[:UUID] == "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9"
      assert tfd.data[:Version] == "1.1"
      assert tfd.data[:NoCertificadoSAT] == "30001000000400002495"
    end

    test "resuelve el complemento de concepto iedu:instEducativas" do
      comp = completo!().comprobante
      [concepto] = Map.get(comp, :"cfdi:Conceptos")

      assert %Cfdi.Concepto.Complemento{complementos: [%Iedu{} = iedu]} = concepto.complemento
      assert iedu.data[:nombreAlumno] == "RUBINHO LOPEZ ADILENE"
      assert iedu.data[:autRVOE] == "118141"
      assert iedu.data[:version] == "1.0"
    end

    test "resuelve por URI del namespace, no por el prefijo del emisor" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0">
        <cfdi:Complemento>
          <zzz:TimbreFiscalDigital xmlns:zzz="http://www.sat.gob.mx/TimbreFiscalDigital" UUID="abc"/>
        </cfdi:Complemento>
      </cfdi:Comprobante>
      """

      {:ok, cfdi} = CFDI.from_xml(xml)
      [%Cfdi.Complemento{children: [child]}] = Map.get(cfdi.comprobante, :"cfdi:Complementos")

      assert %Tfd{} = child
      assert child.data[:UUID] == "abc"
    end

    test "un complemento desconocido no revienta el parseo" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0">
        <cfdi:Complemento>
          <foo:Bar xmlns:foo="http://ejemplo.com/foo" Baz="1"/>
        </cfdi:Complemento>
      </cfdi:Comprobante>
      """

      assert {:ok, cfdi} = CFDI.from_xml(xml)
      assert %Comprobante{} = cfdi.comprobante
    end
  end

  describe "from_xml/2 — CFDI relacionados" do
    test "reconstruye los grupos con sus UUIDs" do
      xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0">
        <cfdi:CfdiRelacionados TipoRelacion="04">
          <cfdi:CfdiRelacionado UUID="11111111-1111-1111-1111-111111111111"/>
          <cfdi:CfdiRelacionado UUID="22222222-2222-2222-2222-222222222222"/>
        </cfdi:CfdiRelacionados>
      </cfdi:Comprobante>
      """

      {:ok, cfdi} = CFDI.from_xml(xml)
      [grupo] = Map.get(cfdi.comprobante, :"cfdi:CfdiRelacionados")

      assert grupo."TipoRelacion" == "04"
      uuids = Map.get(grupo, :"cfdi:CfdiRelacionado") |> Enum.map(& &1."UUID")
      assert uuids == [
               "11111111-1111-1111-1111-111111111111",
               "22222222-2222-2222-2222-222222222222"
             ]
    end
  end

  describe "from_xml/2 — errores" do
    test "XML malformado devuelve error" do
      assert {:error, _} = CFDI.from_xml("<cfdi:Comprobante")
    end

    test "raíz que no es Comprobante devuelve error" do
      assert {:error, {:unexpected_root, "otra:Cosa"}} =
               CFDI.from_xml(~s(<otra:Cosa xmlns:otra="http://x"/>))
    end
  end

  describe "from_file/2" do
    test "lee y parsea desde disco" do
      assert {:ok, cfdi} = CFDI.from_file(fixture("cfdi-completo.xml"))
      assert %Comprobante{} = cfdi.comprobante
    end

    test "archivo inexistente devuelve error" do
      assert {:error, {:file_error, :enoent}} = CFDI.from_file(fixture("no-existe.xml"))
    end
  end

  describe "from_xml!/2" do
    test "devuelve el CFDI directo" do
      assert %CFDI{} = CFDI.from_xml!(read("cfdi-completo.xml"))
    end

    test "levanta excepción en XML inválido" do
      assert_raise ArgumentError, fn -> CFDI.from_xml!("<roto") end
    end
  end

  describe "roundtrip from_xml |> to_xml" do
    # El orden de atributos y el whitespace entre elementos no son
    # significativos en XML; el contenido sí. Normalizamos ambos árboles y
    # comparamos estructura contra estructura.
    defp norm({name, attrs, children}) do
      kids =
        children
        |> Enum.reject(&(is_binary(&1) and String.trim(&1) == ""))
        |> Enum.map(&norm/1)

      {name, Enum.sort(attrs), kids}
    end

    defp norm(text) when is_binary(text), do: String.trim(text)

    defp tree!(xml) do
      {:ok, parsed} = Saxy.SimpleForm.parse_string(xml)
      norm(parsed)
    end

    defp assert_roundtrip(name) do
      original = read(name)
      {:ok, cfdi} = CFDI.from_xml(original)

      assert tree!(CFDI.to_xml(cfdi)) == tree!(original)
    end

    test "cfdi-completo.xml — complementos que declaran su propio xmlns" do
      assert_roundtrip("cfdi-completo.xml")
    end

    test "CFDI timbrado real — xmlns y schemaLocation en la raíz" do
      assert_roundtrip("535BBAC7-85BB-45B0-B067-C8198CD5A52B.xml")
    end

    test "vehiculo_usado.xml — xmlns del complemento heredado desde la raíz" do
      assert_roundtrip("vehiculo_usado.xml")
    end

    test "preserva el Sello intacto — no se re-sella al decodificar" do
      original = read("535BBAC7-85BB-45B0-B067-C8198CD5A52B.xml")
      {:ok, cfdi} = CFDI.from_xml(original)

      assert cfdi.comprobante."Sello" =~ "N4gSjcC28x4yaCCIBZ55Ozw"
      assert CFDI.to_xml(cfdi) =~ cfdi.comprobante."Sello"
    end
  end

  describe "marca de timbrado" do
    test "un CFDI timbrado se marca como tal" do
      {:ok, cfdi} = CFDI.from_xml(read("cfdi-completo.xml"))

      assert CFDI.timbrado?(cfdi)
      assert CFDI.uuid(cfdi) == "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9"
    end

    test "un CFDI sin TFD no se marca como timbrado" do
      {:ok, cfdi} = CFDI.from_xml(read("emisor-receptor.xml"))

      refute CFDI.timbrado?(cfdi)
      assert CFDI.uuid(cfdi) == nil
    end

    test "un CFDI armado con new/1 no está timbrado" do
      refute CFDI.new(%Comprobante{}) |> CFDI.timbrado?()
    end
  end
end
