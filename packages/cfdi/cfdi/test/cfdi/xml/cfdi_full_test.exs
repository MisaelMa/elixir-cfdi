defmodule CFDIFullTest do
  @moduledoc """
  Integración: arma un CFDI 4.0 con todos los elementos soportados y
  verifica la proyección a mapa, JSON y XML.
  """

  use ExUnit.Case, async: true

  alias Cfdi.{Comprobante, Concepto, Emisor, Impuestos, InformacionGlobal, Receptor, Relacionado, Retencion, Traslado}
  alias Cfdi.Concepto.Parte

  defp build_comprobante do
    concepto =
      %Concepto{
        ClaveProdServ: "01010101",
        NoIdentificacion: "ID-1",
        Cantidad: "1",
        ClaveUnidad: "H87",
        Unidad: "Pieza",
        Descripcion: "Servicio educativo",
        ValorUnitario: "1000.00",
        Importe: "1000.00",
        Descuento: "0.00",
        ObjetoImp: "02"
      }
      |> Concepto.add_traslado(%Traslado{
        Base: "1000.00",
        Impuesto: "002",
        TipoFactor: "Tasa",
        TasaOCuota: "0.160000",
        Importe: "160.00"
      })
      |> Concepto.add_retencion(%Retencion{
        Base: "1000.00",
        Impuesto: "001",
        TipoFactor: "Tasa",
        TasaOCuota: "0.100000",
        Importe: "100.00"
      })
      |> Concepto.set_a_cuenta_terceros(%{
        RfcACuentaTerceros: "XAXX010101000",
        NombreACuentaTerceros: "Tercero SA",
        RegimenFiscalACuentaTerceros: "601",
        DomicilioFiscalACuentaTerceros: "06600"
      })
      |> Concepto.add_informacion_aduanera("15  48  0301 0001234")
      |> Concepto.set_cuenta_predial("CP-999")
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
      |> Concepto.add_parte(%Parte{
        ClaveProdServ: "01010101",
        NoIdentificacion: "P-1",
        Cantidad: "2",
        Unidad: "Pieza",
        Descripcion: "Parte A",
        ValorUnitario: "250.00",
        Importe: "500.00"
      })
      |> Concepto.add_parte_informacion_aduanera("10  24  3001 0007777")

    impuestos_globales =
      %Impuestos{TotalImpuestosTrasladados: "160.00", TotalImpuestosRetenidos: "100.00"}
      |> Impuestos.add_traslado(%{
        Base: "1000.00",
        Impuesto: "002",
        TipoFactor: "Tasa",
        TasaOCuota: "0.160000",
        Importe: "160.00"
      })
      |> Impuestos.add_retencion(%{
        Base: "1000.00",
        Impuesto: "001",
        TipoFactor: "Tasa",
        TasaOCuota: "0.100000",
        Importe: "100.00"
      })

    relacionados =
      %Relacionado{TipoRelacion: "04"}
      |> Relacionado.add_relation("11111111-1111-1111-1111-111111111111")
      |> Relacionado.add_relation("22222222-2222-2222-2222-222222222222")

    %Comprobante{
      Version: "4.0",
      Serie: "F",
      Folio: "100",
      Fecha: "2026-04-23T10:00:00",
      FormaPago: "01",
      CondicionesDePago: "Contado",
      SubTotal: "1000.00",
      Descuento: "0.00",
      Moneda: "MXN",
      Total: "1060.00",
      TipoDeComprobante: "I",
      Exportacion: "01",
      MetodoPago: "PUE",
      LugarExpedicion: "06600"
    }
    |> Comprobante.add_informacion_global(%InformacionGlobal{
      Periodicidad: "01",
      Meses: "01",
      Año: "2026"
    })
    |> Comprobante.add_relacionado(relacionados)
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
    |> Comprobante.add_impuesto(impuestos_globales)
  end

  # -- Expectativas -----------------------------------------------------------

  defp concepto_body(ns?) do
    k = &key/2

    %{
      :ClaveProdServ => "01010101",
      :NoIdentificacion => "ID-1",
      :Cantidad => "1",
      :ClaveUnidad => "H87",
      :Unidad => "Pieza",
      :Descripcion => "Servicio educativo",
      :ValorUnitario => "1000.00",
      :Importe => "1000.00",
      :Descuento => "0.00",
      :ObjetoImp => "02",
      k.("ACuentaTerceros", ns?) => %{
        RfcACuentaTerceros: "XAXX010101000",
        NombreACuentaTerceros: "Tercero SA",
        RegimenFiscalACuentaTerceros: "601",
        DomicilioFiscalACuentaTerceros: "06600"
      },
      k.("InformacionAduanera", ns?) => [%{NumeroPedimento: "15  48  0301 0001234"}],
      k.("CuentaPredial", ns?) => %{Numero: "CP-999"},
      k.("ComplementoConcepto", ns?) => %{
        "iedu:instEducativas" => %{
          version: "1.0",
          nombreAlumno: "Pedro Pérez",
          CURP: "PEPE900101HDFRRD09",
          nivelEducativo: "Preescolar",
          autRVOE: "AUT-001",
          rfcPago: "PEPE900101A11"
        }
      },
      k.("Impuestos", ns?) => %{
        k.("Traslados", ns?) => %{
          k.("Traslado", ns?) => [
            %{
              Base: "1000.00",
              Impuesto: "002",
              TipoFactor: "Tasa",
              TasaOCuota: "0.160000",
              Importe: "160.00"
            }
          ]
        },
        k.("Retenciones", ns?) => %{
          k.("Retencion", ns?) => [
            %{
              Base: "1000.00",
              Impuesto: "001",
              TipoFactor: "Tasa",
              TasaOCuota: "0.100000",
              Importe: "100.00"
            }
          ]
        }
      },
      k.("Parte", ns?) => [
        %{
          :ClaveProdServ => "01010101",
          :NoIdentificacion => "P-1",
          :Cantidad => "2",
          :Unidad => "Pieza",
          :Descripcion => "Parte A",
          :ValorUnitario => "250.00",
          :Importe => "500.00",
          k.("InformacionAduanera", ns?) => [%{NumeroPedimento: "10  24  3001 0007777"}]
        }
      ]
    }
  end

  defp expected_map(ns?) do
    k = &key/2

    %{
      k.("Comprobante", ns?) => %{
        :Version => "4.0",
        :Serie => "F",
        :Folio => "100",
        :Fecha => "2026-04-23T10:00:00",
        :FormaPago => "01",
        :CondicionesDePago => "Contado",
        :SubTotal => "1000.00",
        :Descuento => "0.00",
        :Moneda => "MXN",
        :Total => "1060.00",
        :TipoDeComprobante => "I",
        :Exportacion => "01",
        :MetodoPago => "PUE",
        :LugarExpedicion => "06600",
        k.("InformacionGlobal", ns?) => %{
          Periodicidad: "01",
          Meses: "01",
          Año: "2026"
        },
        k.("CfdiRelacionados", ns?) => [
          %{
            :TipoRelacion => "04",
            k.("CfdiRelacionado", ns?) => [
              %{UUID: "11111111-1111-1111-1111-111111111111"},
              %{UUID: "22222222-2222-2222-2222-222222222222"}
            ]
          }
        ],
        k.("Emisor", ns?) => %{
          Rfc: "EKU9003173C9",
          Nombre: "ESCUELA KEMPER URGATE",
          RegimenFiscal: "603"
        },
        k.("Receptor", ns?) => %{
          Rfc: "CACX7605101P8",
          Nombre: "XOCHILT CASAS CHAVEZ",
          UsoCFDI: "G03",
          DomicilioFiscalReceptor: "36257",
          RegimenFiscalReceptor: "612"
        },
        k.("Conceptos", ns?) => %{
          k.("Concepto", ns?) => [concepto_body(ns?)]
        },
        k.("Impuestos", ns?) => %{
          :TotalImpuestosTrasladados => "160.00",
          :TotalImpuestosRetenidos => "100.00",
          k.("Traslados", ns?) => %{
            k.("Traslado", ns?) => [
              %{
                Base: "1000.00",
                Impuesto: "002",
                TipoFactor: "Tasa",
                TasaOCuota: "0.160000",
                Importe: "160.00"
              }
            ]
          },
          k.("Retenciones", ns?) => %{
            k.("Retencion", ns?) => [
              %{
                Base: "1000.00",
                Impuesto: "001",
                TipoFactor: "Tasa",
                TasaOCuota: "0.100000",
                Importe: "100.00"
              }
            ]
          }
        }
      }
    }
  end

  defp key(name, true), do: "cfdi:" <> name
  defp key(name, false), do: name

  # -- Tests ------------------------------------------------------------------

  test "to_map/2 con ns: true reproduce el árbol canónico" do
    assert CFDI.to_map(CFDI.new(build_comprobante())) == expected_map(true)
  end

  test "to_map/2 con ns: false descarta el prefijo cfdi:" do
    assert CFDI.to_map(CFDI.new(build_comprobante()), ns: false) == expected_map(false)
  end

  test "to_json/2 coincide con la proyección a mapa decodificada" do
    cfdi = CFDI.new(build_comprobante())

    decoded_ns = Jason.decode!(CFDI.to_json(cfdi))
    decoded_flat = Jason.decode!(CFDI.to_json(cfdi, ns: false))

    assert decoded_ns == stringify_keys(expected_map(true))
    assert decoded_flat == stringify_keys(expected_map(false))
  end

  test "to_xml/2 produce el árbol XML canónico del CFDI" do
    xml = CFDI.to_xml(CFDI.new(build_comprobante()))

    {:ok, actual} = Saxy.SimpleForm.parse_string(xml)

    assert normalize(actual) == normalize(expected_xml_tree())
  end

  # -- Árbol XML esperado (Saxy SimpleForm) -----------------------------------

  defp expected_xml_tree do
    traslado = {"cfdi:Traslado",
                [
                  {"Base", "1000.00"},
                  {"Impuesto", "002"},
                  {"TipoFactor", "Tasa"},
                  {"TasaOCuota", "0.160000"},
                  {"Importe", "160.00"}
                ], []}

    retencion = {"cfdi:Retencion",
                 [
                   {"Base", "1000.00"},
                   {"Impuesto", "001"},
                   {"TipoFactor", "Tasa"},
                   {"TasaOCuota", "0.100000"},
                   {"Importe", "100.00"}
                 ], []}

    impuestos_concepto =
      {"cfdi:Impuestos", [],
       [
         {"cfdi:Retenciones", [], [retencion]},
         {"cfdi:Traslados", [], [traslado]}
       ]}

    parte =
      {"cfdi:Parte",
       [
         {"ClaveProdServ", "01010101"},
         {"NoIdentificacion", "P-1"},
         {"Cantidad", "2"},
         {"Unidad", "Pieza"},
         {"Descripcion", "Parte A"},
         {"ValorUnitario", "250.00"},
         {"Importe", "500.00"}
       ],
       [
         {"cfdi:InformacionAduanera",
          [{"NumeroPedimento", "10  24  3001 0007777"}], []}
       ]}

    concepto =
      {"cfdi:Concepto",
       [
         {"ClaveProdServ", "01010101"},
         {"NoIdentificacion", "ID-1"},
         {"Cantidad", "1"},
         {"ClaveUnidad", "H87"},
         {"Unidad", "Pieza"},
         {"Descripcion", "Servicio educativo"},
         {"ValorUnitario", "1000.00"},
         {"Importe", "1000.00"},
         {"Descuento", "0.00"},
         {"ObjetoImp", "02"}
       ],
       [
         impuestos_concepto,
         {"cfdi:ACuentaTerceros",
          [
            {"RfcACuentaTerceros", "XAXX010101000"},
            {"NombreACuentaTerceros", "Tercero SA"},
            {"RegimenFiscalACuentaTerceros", "601"},
            {"DomicilioFiscalACuentaTerceros", "06600"}
          ], []},
         {"cfdi:InformacionAduanera",
          [{"NumeroPedimento", "15  48  0301 0001234"}], []},
         {"cfdi:CuentaPredial", [{"Numero", "CP-999"}], []},
         {"cfdi:ComplementoConcepto", [],
          [
            {"iedu:instEducativas",
             [
               {"version", "1.0"},
               {"nombreAlumno", "Pedro Pérez"},
               {"CURP", "PEPE900101HDFRRD09"},
               {"nivelEducativo", "Preescolar"},
               {"autRVOE", "AUT-001"},
               {"rfcPago", "PEPE900101A11"}
             ], []}
          ]},
         parte
       ]}

    impuestos_globales =
      {"cfdi:Impuestos",
       [
         {"TotalImpuestosTrasladados", "160.00"},
         {"TotalImpuestosRetenidos", "100.00"}
       ],
       [
         {"cfdi:Retenciones", [], [retencion]},
         {"cfdi:Traslados", [], [traslado]}
       ]}

    {"cfdi:Comprobante",
     [
       {"Version", "4.0"},
       {"Serie", "F"},
       {"Folio", "100"},
       {"Fecha", "2026-04-23T10:00:00"},
       {"FormaPago", "01"},
       {"CondicionesDePago", "Contado"},
       {"SubTotal", "1000.00"},
       {"Descuento", "0.00"},
       {"Moneda", "MXN"},
       {"Total", "1060.00"},
       {"TipoDeComprobante", "I"},
       {"Exportacion", "01"},
       {"MetodoPago", "PUE"},
       {"LugarExpedicion", "06600"}
     ],
     [
       {"cfdi:InformacionGlobal",
        [{"Periodicidad", "01"}, {"Meses", "01"}, {"Año", "2026"}], []},
       {"cfdi:CfdiRelacionados", [{"TipoRelacion", "04"}],
        [
          {"cfdi:CfdiRelacionado",
           [{"UUID", "11111111-1111-1111-1111-111111111111"}], []},
          {"cfdi:CfdiRelacionado",
           [{"UUID", "22222222-2222-2222-2222-222222222222"}], []}
        ]},
       {"cfdi:Emisor",
        [
          {"Rfc", "EKU9003173C9"},
          {"Nombre", "ESCUELA KEMPER URGATE"},
          {"RegimenFiscal", "603"}
        ], []},
       {"cfdi:Receptor",
        [
          {"Rfc", "CACX7605101P8"},
          {"Nombre", "XOCHILT CASAS CHAVEZ"},
          {"UsoCFDI", "G03"},
          {"DomicilioFiscalReceptor", "36257"},
          {"RegimenFiscalReceptor", "612"}
        ], []},
       {"cfdi:Conceptos", [], [concepto]},
       impuestos_globales
     ]}
  end

  # -- Normalización ----------------------------------------------------------
  #
  # Saxy devuelve atributos en el orden del documento, y XmlBuilder emite los
  # atributos ordenados alfabéticamente. El orden de atributos es irrelevante
  # en XML, así que los ordenamos por nombre antes de comparar.
  #
  # El orden de elementos hijos SÍ importa (CFDI 4.0 exige un orden canónico),
  # por lo que la lista de children se preserva tal cual.

  defp normalize({tag, attrs, children}) do
    {tag, Enum.sort_by(attrs, &elem(&1, 0)), Enum.map(children, &normalize/1) |> Enum.reject(&ignorable?/1)}
  end

  defp normalize(text) when is_binary(text), do: text

  defp ignorable?(text) when is_binary(text), do: String.trim(text) == ""
  defp ignorable?(_), do: false

  # -- Helpers ---------------------------------------------------------------

  # Convierte recursivamente las llaves atom a string para comparar con el
  # resultado de Jason.decode!/1.
  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), stringify_keys(v)} end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(other), do: other
end
