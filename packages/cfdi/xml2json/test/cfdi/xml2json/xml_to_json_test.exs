defmodule Cfdi.Xml2Json.XmlToJsonTest do
  use ExUnit.Case
  alias Cfdi.Xml2Json.XmlToJson

  @files_path Path.expand("../../../../../files/xml", __DIR__)

  describe "CFDI" do
    test "parsea el XML completo (claves string)" do
      xml = Path.join(@files_path, "5E2D6AFF-2DD7-43D1-83D3-14C1ACA396D9.xml")
      result = XmlToJson.parse(xml, original: false)

      assert is_map(result)
      assert Map.has_key?(result, "Comprobante")
    end

    test "Emisor & Receptor con claves string" do
      xml = Path.join(@files_path, "emisor-receptor.xml")
      result = XmlToJson.parse(xml, original: false, keys: :string)

      assert result == %{
               "Comprobante" => %{
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
             }
    end

    test "Emisor & Receptor con claves atómicas" do
      xml = Path.join(@files_path, "emisor-receptor.xml")
      result = XmlToJson.parse(xml, original: false, keys: :atom)

      assert result == %{
               Comprobante: %{
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
             }
    end

    test "acepta XML como cadena (no solo ruta)" do
      xml =
        ~s(<cfdi:Comprobante><cfdi:Emisor Rfc="EKU9003173C9" Nombre="X" RegimenFiscal="603"/></cfdi:Comprobante>)

      result = XmlToJson.parse(xml)

      assert result == %{
               "Comprobante" => %{
                 "Emisor" => %{
                   "Nombre" => "X",
                   "Rfc" => "EKU9003173C9",
                   "RegimenFiscal" => "603"
                 }
               }
             }
    end

    test "con :original mantiene los prefijos de namespace" do
      xml = Path.join(@files_path, "emisor-receptor.xml")
      result = XmlToJson.parse(xml, original: true)

      assert %{"cfdi:Comprobante" => comprobante} = result
      assert %{"cfdi:Emisor" => _, "cfdi:Receptor" => _} = comprobante
    end
  end

  describe "XML completo (cfdi-completo.xml)" do
    @xml_completo Path.expand("cfdi-completo.xml", @files_path)

    test "parsea todo el árbol con claves string (=>)" do
      result = XmlToJson.parse(@xml_completo)

      assert result == %{
               "Comprobante" => %{
                 "Emisor" => %{
                   "Rfc" => "EKU9003173C9",
                   "Nombre" => "ESCUELA KEMPER URGATE",
                   "RegimenFiscal" => "603"
                 },
                 "Receptor" => %{
                   "Rfc" => "CACX7605101P8",
                   "Nombre" => "XOCHILT CASAS CHAVEZ",
                   "DomicilioFiscalReceptor" => "36257",
                   "RegimenFiscalReceptor" => "612",
                   "UsoCFDI" => "G03"
                 },
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
                 ],
                 "Impuestos" => %{
                   "TotalImpuestosTrasladados" => "0.16",
                   "Traslados" => [
                     %{
                       "Base" => "1",
                       "Impuesto" => "002",
                       "TipoFactor" => "Tasa",
                       "TasaOCuota" => "0.160000",
                       "Importe" => "0.16"
                     }
                   ]
                 },
                 "Complemento" => %{
                   "TimbreFiscalDigital" => %{
                     "meta" => %{"tfd" => "http://www.sat.gob.mx/TimbreFiscalDigital"},
                     "Version" => "1.1",
                     "UUID" => "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9",
                     "FechaTimbrado" => "2021-02-17T14:13:10",
                     "RfcProvCertif" => "SPR190613I52",
                     "NoCertificadoSAT" => "30001000000400002495"
                   }
                 }
               }
             }
    end

    test "parsea todo el árbol con claves atómicas" do
      result = XmlToJson.parse(@xml_completo, keys: :atom)

      assert result == %{
               Comprobante: %{
                 Emisor: %{
                   Rfc: "EKU9003173C9",
                   Nombre: "ESCUELA KEMPER URGATE",
                   RegimenFiscal: "603"
                 },
                 Receptor: %{
                   Rfc: "CACX7605101P8",
                   Nombre: "XOCHILT CASAS CHAVEZ",
                   DomicilioFiscalReceptor: "36257",
                   RegimenFiscalReceptor: "612",
                   UsoCFDI: "G03"
                 },
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
                 ],
                 Impuestos: %{
                   TotalImpuestosTrasladados: "0.16",
                   Traslados: [
                     %{
                       Base: "1",
                       Impuesto: "002",
                       TipoFactor: "Tasa",
                       TasaOCuota: "0.160000",
                       Importe: "0.16"
                     }
                   ]
                 },
                 Complemento: %{
                   TimbreFiscalDigital: %{
                     meta: %{tfd: "http://www.sat.gob.mx/TimbreFiscalDigital"},
                     Version: "1.1",
                     UUID: "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9",
                     FechaTimbrado: "2021-02-17T14:13:10",
                     RfcProvCertif: "SPR190613I52",
                     NoCertificadoSAT: "30001000000400002495"
                   }
                 }
               }
             }
    end
  end
end
