defmodule Cfdi.Xml2Json.ConceptosToMapTest do
  use ExUnit.Case
  alias Cfdi.Xml2Json.XmlToJson

  @files_path Path.expand("../../../../../files/xml", __DIR__)

  @concepto_attrs_string %{
    "ClaveProdServ" => "86121500",
    "Cantidad" => "1",
    "ClaveUnidad" => "E48",
    "Unidad" => "Pieza",
    "Descripcion" => "Mensualidad - diciembre",
    "ValorUnitario" => "5000",
    "Importe" => "5000",
    "Descuento" => "0"
  }

  @concepto_attrs_atom %{
    ClaveProdServ: "86121500",
    Cantidad: "1",
    ClaveUnidad: "E48",
    Unidad: "Pieza",
    Descripcion: "Mensualidad - diciembre",
    ValorUnitario: "5000",
    Importe: "5000",
    Descuento: "0"
  }

  describe "a mapa con claves string" do
    test "un concepto" do
      xml = Path.join(@files_path, "un-concepto.xml")
      result = XmlToJson.parse(xml)

      assert result == %{
               "Comprobante" => %{
                 "Conceptos" => [@concepto_attrs_string]
               }
             }
    end

    test "dos conceptos" do
      xml = Path.join(@files_path, "dos-conceptos.xml")
      result = XmlToJson.parse(xml)

      assert result == %{
               "Comprobante" => %{
                 "Conceptos" => [@concepto_attrs_string, @concepto_attrs_string]
               }
             }
    end

    test "con complemento" do
      xml = Path.join(@files_path, "conceptos.xml")
      result = XmlToJson.parse(xml)

      assert result == %{
               "Comprobante" => %{
                 "Conceptos" => [
                   Map.merge(@concepto_attrs_string, %{
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
                   })
                 ]
               }
             }
    end
  end

  describe "a mapa con claves atómicas" do
    test "un concepto" do
      xml = Path.join(@files_path, "un-concepto.xml")
      result = XmlToJson.parse(xml, keys: :atom)

      assert result == %{
               Comprobante: %{
                 Conceptos: [@concepto_attrs_atom]
               }
             }
    end

    test "dos conceptos" do
      xml = Path.join(@files_path, "dos-conceptos.xml")
      result = XmlToJson.parse(xml, keys: :atom)

      assert result == %{
               Comprobante: %{
                 Conceptos: [@concepto_attrs_atom, @concepto_attrs_atom]
               }
             }
    end

    test "con complemento" do
      xml = Path.join(@files_path, "conceptos.xml")
      result = XmlToJson.parse(xml, keys: :atom)

      assert result == %{
               Comprobante: %{
                 Conceptos: [
                   Map.merge(@concepto_attrs_atom, %{
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
                   })
                 ]
               }
             }
    end
  end
end
