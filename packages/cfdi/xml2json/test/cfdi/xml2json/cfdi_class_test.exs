defmodule Cfdi.Xml2Json.CfdiClassTest do
  use ExUnit.Case
  alias Cfdi.Xml2Json.Cfdi

  @files_path Path.expand("../../../../../files/xml", __DIR__)

  test "cfdi.comprobante completo - emisor-receptor con claves string" do
    xml = Path.join(@files_path, "emisor-receptor.xml")
    cfdi = Cfdi.new(xml)

    assert %Cfdi{} = cfdi

    assert cfdi.comprobante == %{
             "Emisor" => %{
               "Nombre" => "ESCUELA KEMPER URGATE",
               "RegimenFiscal" => "603",
               "Rfc" => "EKU9003173C9"
             },
             "Receptor" => %{
               "DomicilioFiscalReceptor" => "36257",
               "Nombre" => "XOCHILT CASAS CHAVEZ",
               "RegimenFiscalReceptor" => "612",
               "Rfc" => "CACX7605101P8",
               "UsoCFDI" => "G03"
             }
           }
  end

  test "cfdi.comprobante completo - emisor-receptor con claves atómicas" do
    xml = Path.join(@files_path, "emisor-receptor.xml")
    cfdi = Cfdi.new(xml, keys: :atom)

    assert cfdi.comprobante == %{
             Emisor: %{
               Nombre: "ESCUELA KEMPER URGATE",
               RegimenFiscal: "603",
               Rfc: "EKU9003173C9"
             },
             Receptor: %{
               DomicilioFiscalReceptor: "36257",
               Nombre: "XOCHILT CASAS CHAVEZ",
               RegimenFiscalReceptor: "612",
               Rfc: "CACX7605101P8",
               UsoCFDI: "G03"
             }
           }
  end

  test "cfdi.comprobante completo - conceptos.xml con claves string" do
    xml = Path.join(@files_path, "conceptos.xml")
    cfdi = Cfdi.new(xml)

    assert cfdi.comprobante == %{
             "Conceptos" => [
               %{
                 "ClaveProdServ" => "86121500",
                 "Cantidad" => "1",
                 "ClaveUnidad" => "E48",
                 "Unidad" => "Pieza",
                 "Descripcion" => "Mensualidad - diciembre",
                 "ValorUnitario" => "5000",
                 "Importe" => "5000",
                 "Descuento" => "0",
                 "Impuestos" => %{
                   "Traslados" => [
                     %{"Base" => "1", "Impuesto" => "002", "TipoFactor" => "Exento"}
                   ]
                 },
                 "ComplementoConcepto" => %{
                   "instEducativas" => %{
                     "meta" => %{"iedu" => "http://www.sat.gob.mx/iedu"},
                     "rfcPago" => "CACX7605101P8",
                     "autRVOE" => "118141",
                     "nivelEducativo" => "Primaria",
                     "CURP" => "XEXX010101HNEXXXA4",
                     "nombreAlumno" => "RUBINHO LOPEZ ADILENE",
                     "version" => "1.0"
                   }
                 }
               }
             ]
           }
  end

  test "cfdi.comprobante completo - conceptos.xml con claves atómicas" do
    xml = Path.join(@files_path, "conceptos.xml")
    cfdi = Cfdi.new(xml, keys: :atom)

    assert cfdi.comprobante == %{
             Conceptos: [
               %{
                 ClaveProdServ: "86121500",
                 Cantidad: "1",
                 ClaveUnidad: "E48",
                 Unidad: "Pieza",
                 Descripcion: "Mensualidad - diciembre",
                 ValorUnitario: "5000",
                 Importe: "5000",
                 Descuento: "0",
                 Impuestos: %{
                   Traslados: [
                     %{Base: "1", Impuesto: "002", TipoFactor: "Exento"}
                   ]
                 },
                 ComplementoConcepto: %{
                   instEducativas: %{
                     meta: %{iedu: "http://www.sat.gob.mx/iedu"},
                     rfcPago: "CACX7605101P8",
                     autRVOE: "118141",
                     nivelEducativo: "Primaria",
                     CURP: "XEXX010101HNEXXXA4",
                     nombreAlumno: "RUBINHO LOPEZ ADILENE",
                     version: "1.0"
                   }
                 }
               }
             ]
           }
  end

  test "cfdi.json contiene el árbol completo y cfdi.comprobante el sub-árbol raíz" do
    xml = Path.join(@files_path, "emisor-receptor.xml")
    cfdi = Cfdi.new(xml)

    assert is_map(cfdi.json)
    assert cfdi.json["Comprobante"] == cfdi.comprobante
  end
end
