defmodule Cfdi.Xml2Json.CfdiCompletoTest do
  use ExUnit.Case
  alias Cfdi.Xml2Json.Cfdi

  @files_path Path.expand("../../../../../files/xml", __DIR__)

  @xml Path.expand("cfdi-completo.xml", @files_path)

  @concepto_attrs %{
    "ClaveProdServ" => "86121500",
    "Cantidad" => "1",
    "ClaveUnidad" => "E48",
    "Unidad" => "Pieza",
    "Descripcion" => "Mensualidad - diciembre",
    "ValorUnitario" => "5000",
    "Importe" => "5000",
    "Descuento" => "0"
  }

  @concepto_impuestos %{
    "Impuestos" => %{
      "Traslados" => [
        %{"Base" => "1", "Impuesto" => "002", "TipoFactor" => "Exento"}
      ]
    }
  }

  @concepto_complemento %{
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

  @top_impuestos %{
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
  }

  @complemento %{
    "TimbreFiscalDigital" => %{
      "meta" => %{"tfd" => "http://www.sat.gob.mx/TimbreFiscalDigital"},
      "Version" => "1.1",
      "UUID" => "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9",
      "FechaTimbrado" => "2021-02-17T14:13:10",
      "RfcProvCertif" => "SPR190613I52",
      "NoCertificadoSAT" => "30001000000400002495"
    }
  }

  test "cfdi.comprobante completo con claves string (=>) - todas las propiedades" do
    cfdi = Cfdi.new(@xml)

    assert cfdi.comprobante == %{
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
               @concepto_attrs |> Map.merge(@concepto_impuestos) |> Map.merge(@concepto_complemento)
             ],
             "Impuestos" => @top_impuestos,
             "Complemento" => @complemento
           }
  end

  test "cfdi.comprobante completo con claves atómicas - todas las propiedades" do
    cfdi = Cfdi.new(@xml, keys: :atom)

    assert cfdi.comprobante == %{
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
  end

  test "case: :lower con claves string baja todos los nombres a minúsculas" do
    cfdi = Cfdi.new(@xml, case: :lower)

    assert cfdi.comprobante == %{
             "emisor" => %{
               "rfc" => "EKU9003173C9",
               "nombre" => "ESCUELA KEMPER URGATE",
               "regimenfiscal" => "603"
             },
             "receptor" => %{
               "rfc" => "CACX7605101P8",
               "nombre" => "XOCHILT CASAS CHAVEZ",
               "domiciliofiscalreceptor" => "36257",
               "regimenfiscalreceptor" => "612",
               "usocfdi" => "G03"
             },
             "conceptos" => [
               %{
                 "claveprodserv" => "86121500",
                 "cantidad" => "1",
                 "claveunidad" => "E48",
                 "unidad" => "Pieza",
                 "descripcion" => "Mensualidad - diciembre",
                 "valorunitario" => "5000",
                 "importe" => "5000",
                 "descuento" => "0",
                 "impuestos" => %{
                   "traslados" => [
                     %{"base" => "1", "impuesto" => "002", "tipofactor" => "Exento"}
                   ]
                 },
                 "complementoconcepto" => %{
                   "insteducativas" => %{
                     "meta" => %{"iedu" => "http://www.sat.gob.mx/iedu"},
                     "rfcpago" => "CACX7605101P8",
                     "autrvoe" => "118141",
                     "niveleducativo" => "Primaria",
                     "curp" => "XEXX010101HNEXXXA4",
                     "nombrealumno" => "RUBINHO LOPEZ ADILENE",
                     "version" => "1.0"
                   }
                 }
               }
             ],
             "impuestos" => %{
               "totalimpuestostrasladados" => "0.16",
               "traslados" => [
                 %{
                   "base" => "1",
                   "impuesto" => "002",
                   "tipofactor" => "Tasa",
                   "tasaocuota" => "0.160000",
                   "importe" => "0.16"
                 }
               ]
             },
             "complemento" => %{
               "timbrefiscaldigital" => %{
                 "meta" => %{"tfd" => "http://www.sat.gob.mx/TimbreFiscalDigital"},
                 "version" => "1.1",
                 "uuid" => "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9",
                 "fechatimbrado" => "2021-02-17T14:13:10",
                 "rfcprovcertif" => "SPR190613I52",
                 "nocertificadosat" => "30001000000400002495"
               }
             }
           }
  end

  test "case: :lower con claves atómicas combina átomos y minúsculas" do
    cfdi = Cfdi.new(@xml, keys: :atom, case: :lower)

    assert cfdi.comprobante[:emisor][:rfc] == "EKU9003173C9"
    assert cfdi.comprobante[:receptor][:nombre] == "XOCHILT CASAS CHAVEZ"

    [concepto] = cfdi.comprobante[:conceptos]
    assert concepto[:claveprodserv] == "86121500"
    assert concepto[:impuestos][:traslados] == [
             %{base: "1", impuesto: "002", tipofactor: "Exento"}
           ]

    assert cfdi.comprobante[:impuestos][:totalimpuestostrasladados] == "0.16"
    assert cfdi.comprobante[:complemento][:timbrefiscaldigital][:uuid] ==
             "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9"
  end
end
