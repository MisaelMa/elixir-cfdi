defmodule Cfdi.Xml2Json.ImpuestosToMapTest do
  use ExUnit.Case
  alias Cfdi.Xml2Json.XmlToJson

  @files_path Path.expand("../../../../../files/xml", __DIR__)

  describe "impuestos a mapa con claves string" do
    test "traslados" do
      xml = Path.join(@files_path, "un-impuesto.xml")
      result = XmlToJson.parse(xml)

      assert result == %{
               "Comprobante" => %{
                 "Impuestos" => %{
                   "TotalImpuestosTrasladados" => "31.72",
                   "Traslados" => [
                     %{
                       "Impuesto" => "002",
                       "TipoFactor" => "Tasa",
                       "TasaOCuota" => "0.160000",
                       "Importe" => "31.72"
                     }
                   ],
                   "Retenciones" => [
                     %{"Importe" => "2.00", "Impuesto" => "004"}
                   ]
                 }
               }
             }
    end

    test "dos traslados" do
      xml = Path.join(@files_path, "dos-impuestos.xml")
      result = XmlToJson.parse(xml)

      traslado = %{
        "Impuesto" => "002",
        "TipoFactor" => "Tasa",
        "TasaOCuota" => "0.160000",
        "Importe" => "31.72"
      }

      retencion = %{"Impuesto" => "002", "Importe" => "1.00"}

      assert result == %{
               "Comprobante" => %{
                 "Impuestos" => %{
                   "TotalImpuestosTrasladados" => "31.72",
                   "Traslados" => [traslado, traslado],
                   "Retenciones" => [retencion, retencion]
                 }
               }
             }
    end
  end

  describe "impuestos a mapa con claves atómicas" do
    test "traslados" do
      xml = Path.join(@files_path, "un-impuesto.xml")
      result = XmlToJson.parse(xml, keys: :atom)

      assert result == %{
               Comprobante: %{
                 Impuestos: %{
                   TotalImpuestosTrasladados: "31.72",
                   Traslados: [
                     %{
                       Impuesto: "002",
                       TipoFactor: "Tasa",
                       TasaOCuota: "0.160000",
                       Importe: "31.72"
                     }
                   ],
                   Retenciones: [
                     %{Importe: "2.00", Impuesto: "004"}
                   ]
                 }
               }
             }
    end

    test "dos traslados" do
      xml = Path.join(@files_path, "dos-impuestos.xml")
      result = XmlToJson.parse(xml, keys: :atom)

      traslado = %{
        Impuesto: "002",
        TipoFactor: "Tasa",
        TasaOCuota: "0.160000",
        Importe: "31.72"
      }

      retencion = %{Impuesto: "002", Importe: "1.00"}

      assert result == %{
               Comprobante: %{
                 Impuestos: %{
                   TotalImpuestosTrasladados: "31.72",
                   Traslados: [traslado, traslado],
                   Retenciones: [retencion, retencion]
                 }
               }
             }
    end
  end
end
