defmodule Cfdi.Xml.HidrocarburosTest do
  use ExUnit.Case
  alias Cfdi.Xml.Parser

  @files_path Path.expand("../../../../../files/xml", __DIR__)
  @xml Path.expand("hidrocarburos.xml", @files_path)

  test "ComplementoConcepto Hidrocarburo10 - claves string (=>)" do
    result = Parser.parse(@xml)

    assert result == %{
             "Comprobante" => %{
               "meta" => %{"cfdi" => "http://www.sat.gob.mx/cfd/4"},
               "Emisor" => %{
                 "Rfc" => "EKU9003173C9",
                 "Nombre" => "GASOLINERA EJEMPLO SA DE CV",
                 "RegimenFiscal" => "601"
               },
               "Receptor" => %{
                 "Rfc" => "XAXX010101000",
                 "Nombre" => "PUBLICO EN GENERAL",
                 "DomicilioFiscalReceptor" => "01000",
                 "RegimenFiscalReceptor" => "616",
                 "UsoCFDI" => "S01"
               },
               "Conceptos" => [
                 %{
                   "ClaveProdServ" => "15101514",
                   "Cantidad" => "50.000",
                   "ClaveUnidad" => "LTR",
                   "Unidad" => "Litro",
                   "Descripcion" => "Gasolina Magna",
                   "ValorUnitario" => "22.50",
                   "Importe" => "1125.00",
                   "ObjetoImp" => "02",
                   "ComplementoConcepto" => %{
                     "Hidrocarburo10" => %{
                       "meta" => %{"hidrocarburo10" => "http://www.sat.gob.mx/Hidrocarburos10"},
                       "Version" => "1.0",
                       "ClaveTipoCombustible" => "GA01",
                       "ImporteTipoCombustible" => "1125.00",
                       "Descripcion" => "Gasolina menor a 92 octanos",
                       "DocumentosRelacionados" => [
                         %{
                           "FolioFiscalOriginal" => "11111111-2222-3333-4444-555555555555",
                           "FechaFolioFiscalOriginal" => "2025-01-15",
                           "ClaveTipoMedidor" => "01",
                           "UnidadMedida" => "LTR",
                           "Cantidad" => "50.000"
                         },
                         %{
                           "FolioFiscalOriginal" => "22222222-3333-4444-5555-666666666666",
                           "FechaFolioFiscalOriginal" => "2025-01-16",
                           "ClaveTipoMedidor" => "01",
                           "UnidadMedida" => "LTR",
                           "Cantidad" => "30.000"
                         }
                       ]
                     }
                   }
                 }
               ]
             }
           }
  end

  test "ComplementoConcepto Hidrocarburo10 - claves atómicas" do
    result = Parser.parse(@xml, keys: :atom)

    assert result == %{
             Comprobante: %{
               meta: %{cfdi: "http://www.sat.gob.mx/cfd/4"},
               Emisor: %{
                 Rfc: "EKU9003173C9",
                 Nombre: "GASOLINERA EJEMPLO SA DE CV",
                 RegimenFiscal: "601"
               },
               Receptor: %{
                 Rfc: "XAXX010101000",
                 Nombre: "PUBLICO EN GENERAL",
                 DomicilioFiscalReceptor: "01000",
                 RegimenFiscalReceptor: "616",
                 UsoCFDI: "S01"
               },
               Conceptos: [
                 %{
                   ClaveProdServ: "15101514",
                   Cantidad: "50.000",
                   ClaveUnidad: "LTR",
                   Unidad: "Litro",
                   Descripcion: "Gasolina Magna",
                   ValorUnitario: "22.50",
                   Importe: "1125.00",
                   ObjetoImp: "02",
                   ComplementoConcepto: %{
                     Hidrocarburo10: %{
                       meta: %{hidrocarburo10: "http://www.sat.gob.mx/Hidrocarburos10"},
                       Version: "1.0",
                       ClaveTipoCombustible: "GA01",
                       ImporteTipoCombustible: "1125.00",
                       Descripcion: "Gasolina menor a 92 octanos",
                       DocumentosRelacionados: [
                         %{
                           FolioFiscalOriginal: "11111111-2222-3333-4444-555555555555",
                           FechaFolioFiscalOriginal: "2025-01-15",
                           ClaveTipoMedidor: "01",
                           UnidadMedida: "LTR",
                           Cantidad: "50.000"
                         },
                         %{
                           FolioFiscalOriginal: "22222222-3333-4444-5555-666666666666",
                           FechaFolioFiscalOriginal: "2025-01-16",
                           ClaveTipoMedidor: "01",
                           UnidadMedida: "LTR",
                           Cantidad: "30.000"
                         }
                       ]
                     }
                   }
                 }
               ]
             }
           }
  end

  test "ComplementoConcepto Hidrocarburo10 - claves string en minúsculas" do
    result = Parser.parse(@xml, case: :lower)

    assert result == %{
             "comprobante" => %{
               "meta" => %{"cfdi" => "http://www.sat.gob.mx/cfd/4"},
               "emisor" => %{
                 "rfc" => "EKU9003173C9",
                 "nombre" => "GASOLINERA EJEMPLO SA DE CV",
                 "regimenfiscal" => "601"
               },
               "receptor" => %{
                 "rfc" => "XAXX010101000",
                 "nombre" => "PUBLICO EN GENERAL",
                 "domiciliofiscalreceptor" => "01000",
                 "regimenfiscalreceptor" => "616",
                 "usocfdi" => "S01"
               },
               "conceptos" => [
                 %{
                   "claveprodserv" => "15101514",
                   "cantidad" => "50.000",
                   "claveunidad" => "LTR",
                   "unidad" => "Litro",
                   "descripcion" => "Gasolina Magna",
                   "valorunitario" => "22.50",
                   "importe" => "1125.00",
                   "objetoimp" => "02",
                   "complementoconcepto" => %{
                     "hidrocarburo10" => %{
                       "meta" => %{"hidrocarburo10" => "http://www.sat.gob.mx/Hidrocarburos10"},
                       "version" => "1.0",
                       "clavetipocombustible" => "GA01",
                       "importetipocombustible" => "1125.00",
                       "descripcion" => "Gasolina menor a 92 octanos",
                       "documentosrelacionados" => [
                         %{
                           "foliofiscaloriginal" => "11111111-2222-3333-4444-555555555555",
                           "fechafoliofiscaloriginal" => "2025-01-15",
                           "clavetipomedidor" => "01",
                           "unidadmedida" => "LTR",
                           "cantidad" => "50.000"
                         },
                         %{
                           "foliofiscaloriginal" => "22222222-3333-4444-5555-666666666666",
                           "fechafoliofiscaloriginal" => "2025-01-16",
                           "clavetipomedidor" => "01",
                           "unidadmedida" => "LTR",
                           "cantidad" => "30.000"
                         }
                       ]
                     }
                   }
                 }
               ]
             }
           }
  end

  test "ComplementoConcepto Hidrocarburo10 - claves atómicas en minúsculas" do
    result = Parser.parse(@xml, keys: :atom, case: :lower)

    assert result == %{
             comprobante: %{
               meta: %{cfdi: "http://www.sat.gob.mx/cfd/4"},
               emisor: %{
                 rfc: "EKU9003173C9",
                 nombre: "GASOLINERA EJEMPLO SA DE CV",
                 regimenfiscal: "601"
               },
               receptor: %{
                 rfc: "XAXX010101000",
                 nombre: "PUBLICO EN GENERAL",
                 domiciliofiscalreceptor: "01000",
                 regimenfiscalreceptor: "616",
                 usocfdi: "S01"
               },
               conceptos: [
                 %{
                   claveprodserv: "15101514",
                   cantidad: "50.000",
                   claveunidad: "LTR",
                   unidad: "Litro",
                   descripcion: "Gasolina Magna",
                   valorunitario: "22.50",
                   importe: "1125.00",
                   objetoimp: "02",
                   complementoconcepto: %{
                     hidrocarburo10: %{
                       meta: %{hidrocarburo10: "http://www.sat.gob.mx/Hidrocarburos10"},
                       version: "1.0",
                       clavetipocombustible: "GA01",
                       importetipocombustible: "1125.00",
                       descripcion: "Gasolina menor a 92 octanos",
                       documentosrelacionados: [
                         %{
                           foliofiscaloriginal: "11111111-2222-3333-4444-555555555555",
                           fechafoliofiscaloriginal: "2025-01-15",
                           clavetipomedidor: "01",
                           unidadmedida: "LTR",
                           cantidad: "50.000"
                         },
                         %{
                           foliofiscaloriginal: "22222222-3333-4444-5555-666666666666",
                           fechafoliofiscaloriginal: "2025-01-16",
                           clavetipomedidor: "01",
                           unidadmedida: "LTR",
                           cantidad: "30.000"
                         }
                       ]
                     }
                   }
                 }
               ]
             }
           }
  end
end
