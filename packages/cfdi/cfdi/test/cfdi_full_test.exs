defmodule CFDIFullTest do
  @moduledoc """
  Integración: arma un CFDI 4.0 con todos los elementos soportados y
  verifica la proyección a mapa, JSON y XML.
  """

  use ExUnit.Case, async: true

  alias Cfdi.{
    Comprobante,
    Concepto,
    Emisor,
    Impuestos,
    InformacionGlobal,
    Receptor,
    Relacionado,
    Retencion,
    Traslado
  }

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

  test "to_map/2 con ns: false descarta el prefijo cfdi: y uniforma todas las llaves a string" do
    # `ns: false` proyecta una vista plana sin namespaces — los atributos
    # también pasan de átomos a strings para que el mapa sea uniforme.
    assert CFDI.to_map(CFDI.new(build_comprobante()), ns: false) ==
             stringify_keys(expected_map(false))
  end

  test "to_map/2 con ns: false, keys: :atom — pattern match con átomos PascalCase" do
    map = CFDI.to_map(CFDI.new(build_comprobante()), ns: false, keys: :atom)

    assert %{
             Comprobante: %{
               Version: "4.0",
               FormaPago: "01",
               TipoDeComprobante: "I",
               LugarExpedicion: "06600",
               Emisor: %{
                 Rfc: "EKU9003173C9",
                 Nombre: "ESCUELA KEMPER URGATE",
                 RegimenFiscal: "603"
               },
               Receptor: %{
                 Rfc: "CACX7605101P8",
                 Nombre: "XOCHILT CASAS CHAVEZ",
                 UsoCFDI: "G03",
                 DomicilioFiscalReceptor: "36257",
                 RegimenFiscalReceptor: "612"
               },
               Impuestos: %{
                 TotalImpuestosTrasladados: "160.00",
                 TotalImpuestosRetenidos: "100.00",
                 Traslados: %{
                   Traslado: [
                     %{
                       Base: "1000.00",
                       Impuesto: "002",
                       TipoFactor: "Tasa",
                       TasaOCuota: "0.160000",
                       Importe: "160.00"
                     }
                   ]
                 },
                 Retenciones: %{
                   Retencion: [
                     %{Base: "1000.00", Impuesto: "001", Importe: "100.00"}
                   ]
                 }
               }
             }
           } = map
  end

  test "to_map/2 con ns: false, keys: :existing usa átomos solo si ya existen" do
    # Las structs ya los crearon al compilar, así que `:Comprobante`,
    # `:Emisor`, `:Rfc`, etc. existen como átomos en la VM.
    map = CFDI.to_map(CFDI.new(build_comprobante()), ns: false, keys: :existing)

    assert %{
             Comprobante: %{
               Version: "4.0",
               Emisor: %{Rfc: "EKU9003173C9", RegimenFiscal: "603"},
               Receptor: %{Rfc: "CACX7605101P8", UsoCFDI: "G03"}
             }
           } = map
  end

  test "to_map/2 con keys inválido lanza ArgumentError" do
    assert_raise ArgumentError, ~r/:keys inválida/, fn ->
      CFDI.to_map(CFDI.new(build_comprobante()), ns: false, keys: :foo)
    end
  end

  test "to_map/2 con case: :camel — pattern match con strings camelCase" do
    map = CFDI.to_map(CFDI.new(build_comprobante()), ns: false, case: :camel)

    assert %{
             "comprobante" => %{
               "version" => "4.0",
               "formaPago" => "01",
               "tipoDeComprobante" => "I",
               "lugarExpedicion" => "06600",
               "emisor" => %{
                 "rfc" => "EKU9003173C9",
                 "nombre" => "ESCUELA KEMPER URGATE",
                 "regimenFiscal" => "603"
               },
               "receptor" => %{
                 "rfc" => "CACX7605101P8",
                 "nombre" => "XOCHILT CASAS CHAVEZ",
                 # Acrónimo final preservado.
                 "usoCFDI" => "G03",
                 "domicilioFiscalReceptor" => "36257",
                 "regimenFiscalReceptor" => "612"
               },
               "impuestos" => %{
                 "totalImpuestosTrasladados" => "160.00",
                 "traslados" => %{
                   "traslado" => [
                     %{"tipoFactor" => "Tasa", "importe" => "160.00"}
                   ]
                 }
               }
             }
           } = map
  end

  test "to_map/2 con keys: :atom + case: :camel — pattern match con átomos camelCase" do
    map = CFDI.to_map(CFDI.new(build_comprobante()), ns: false, keys: :atom, case: :camel)

    assert %{
             comprobante: %{
               version: "4.0",
               formaPago: "01",
               tipoDeComprobante: "I",
               lugarExpedicion: "06600",
               emisor: %{
                 rfc: "EKU9003173C9",
                 nombre: "ESCUELA KEMPER URGATE",
                 regimenFiscal: "603"
               },
               receptor: %{
                 rfc: "CACX7605101P8",
                 # Acrónimo final preservado en la conversión :camel.
                 usoCFDI: "G03",
                 domicilioFiscalReceptor: "36257",
                 regimenFiscalReceptor: "612"
               },
               impuestos: %{
                 traslados: %{
                   traslado: [
                     %{tipoFactor: "Tasa", importe: "160.00"}
                   ]
                 }
               }
             }
           } = map
  end

  test "to_json/2 con case: :camel — pattern match sobre el JSON decodificado" do
    json = CFDI.to_json(CFDI.new(build_comprobante()), ns: false, case: :camel)
    decoded = Jason.decode!(json)

    # Jason siempre decodifica con string keys → pattern match con strings.
    assert %{
             "comprobante" => %{
               "version" => "4.0",
               "formaPago" => "01",
               "tipoDeComprobante" => "I",
               "emisor" => %{
                 "rfc" => "EKU9003173C9",
                 "regimenFiscal" => "603"
               },
               "receptor" => %{
                 "rfc" => "CACX7605101P8",
                 "usoCFDI" => "G03"
               }
             }
           } = decoded
  end

  test "to_map/2 con case inválido lanza ArgumentError" do
    assert_raise ArgumentError, ~r/:case inválida/, fn ->
      CFDI.to_map(CFDI.new(build_comprobante()), ns: false, case: :snake)
    end
  end

  # ── Invariantes de regresión ──────────────────────────────────────────────
  # Estos tests garantizan que las nuevas opciones (`:keys`, `:case`) no
  # rompan los flujos críticos en el futuro.

  test "to_xml/2 ignora :keys y :case (las opciones de proyección no afectan el XML)" do
    cfdi = CFDI.new(build_comprobante())

    # `to_xml` debe ser invariante a `:keys` y `:case` — esas opciones solo
    # aplican al output de `to_map` público. Para cada valor de `:ns`,
    # cualquier combinación de `:keys`/`:case` debe dar el mismo XML.

    base_ns_true = CFDI.to_xml(cfdi, ns: true)

    for opts <- [
          [ns: true, keys: :atom],
          [ns: true, keys: :existing],
          [ns: true, case: :camel],
          [ns: true, keys: :atom, case: :camel]
        ] do
      assert CFDI.to_xml(cfdi, opts) == base_ns_true,
             "to_xml(ns: true, ...) cambió con opts=#{inspect(opts)}"
    end

    base_ns_false = CFDI.to_xml(cfdi, ns: false)

    for opts <- [
          [ns: false, keys: :atom],
          [ns: false, keys: :existing],
          [ns: false, case: :camel],
          [ns: false, keys: :atom, case: :camel]
        ] do
      assert CFDI.to_xml(cfdi, opts) == base_ns_false,
             "to_xml(ns: false, ...) cambió con opts=#{inspect(opts)}"
    end
  end

  test "to_map/2 con ns: true ignora :keys y :case" do
    cfdi = CFDI.new(build_comprobante())
    base = CFDI.to_map(cfdi, ns: true)

    # `:keys` y `:case` solo aplican con `ns: false`.
    for opts <- [
          [ns: true, keys: :atom],
          [ns: true, keys: :existing],
          [ns: true, case: :camel],
          [ns: true, keys: :atom, case: :camel]
        ] do
      assert CFDI.to_map(cfdi, opts) == base,
             "to_map(ns: true, ...) cambió con opts=#{inspect(opts)}"
    end
  end

  test "to_map/2 con ns: false nunca contiene el prefijo cfdi: en ninguna llave" do
    cfdi = CFDI.new(build_comprobante())

    for opts <- [
          [ns: false],
          [ns: false, keys: :atom],
          [ns: false, keys: :existing],
          [ns: false, case: :camel],
          [ns: false, keys: :atom, case: :camel]
        ] do
      map = CFDI.to_map(cfdi, opts)
      refute deep_has_prefix?(map, "cfdi:"), "encontré 'cfdi:' con opts=#{inspect(opts)}"
    end
  end

  test "to_map/2 con keys: :existing cae a string si el átomo no existe" do
    # Sanity check del fallback: un átomo que nunca existió no debe
    # crearse implícitamente.
    fake_key = "ZzNoExisteEsteAtomoEnElVMxyz_#{System.unique_integer([:positive])}"
    assert_raise ArgumentError, fn -> String.to_existing_atom(fake_key) end

    # Las llaves del schema oficial SÍ existen como átomos (las structs los
    # crearon al compilar) → deben resolver a átomo. Pattern match completo.
    map = CFDI.to_map(CFDI.new(build_comprobante()), ns: false, keys: :existing)

    assert %{
             Comprobante: %{
               Version: "4.0",
               Emisor: %{Rfc: "EKU9003173C9"},
               Receptor: %{Rfc: "CACX7605101P8"}
             }
           } = map
  end

  test "to_json/2 produce JSON parseable con todas las combinaciones de opts" do
    cfdi = CFDI.new(build_comprobante())

    for opts <- [
          [],
          [ns: false],
          [ns: false, keys: :atom],
          [ns: false, keys: :existing],
          [ns: false, case: :camel],
          [ns: false, keys: :atom, case: :camel],
          [pretty: true],
          [ns: false, case: :camel, pretty: true]
        ] do
      json = CFDI.to_json(cfdi, opts)
      assert is_binary(json)
      assert {:ok, _} = Jason.decode(json), "JSON inválido con opts=#{inspect(opts)}"
    end
  end

  test "to_map/2 con case: :camel es idempotente para palabras ya en minúscula" do
    # `camel_case_key` solo baja la primera letra; si ya está en minúscula
    # debe quedar intacto. Pattern match: la llave camelCase está,
    # la PascalCase NO.
    cfdi = CFDI.new(build_comprobante())
    map = CFDI.to_map(cfdi, ns: false, case: :camel)

    assert %{"comprobante" => %{"version" => "4.0"}} = map
    refute match?(%{"Comprobante" => _}, map)
    refute match?(%{"comprobante" => %{"Version" => _}}, map)
  end

  test "to_map/2 con keys: :atom + case: :camel produce JSON serializable" do
    # Verifica que la combinación más exótica (átomos camelCase) produce
    # un mapa que Jason puede serializar sin perder información.
    cfdi = CFDI.new(build_comprobante())
    map = CFDI.to_map(cfdi, ns: false, keys: :atom, case: :camel)

    # Las llaves son átomos: chequeo directo con átomos.
    assert is_atom(hd(Map.keys(map)))

    # Roundtrip a JSON y back a mapa con strings: debe coincidir con la
    # versión :string + :camel.
    json = Jason.encode!(map)
    decoded = Jason.decode!(json)

    expected_strings = CFDI.to_map(cfdi, ns: false, keys: :string, case: :camel)
    assert decoded == expected_strings
  end

  # Helper: recorre recursivamente y reporta si alguna llave contiene `prefix`.
  defp deep_has_prefix?(map, prefix) when is_map(map) do
    Enum.any?(map, fn {k, v} ->
      key_str = to_string(k)
      String.starts_with?(key_str, prefix) or deep_has_prefix?(v, prefix)
    end)
  end

  defp deep_has_prefix?(list, prefix) when is_list(list),
    do: Enum.any?(list, &deep_has_prefix?(&1, prefix))

  defp deep_has_prefix?(_other, _prefix), do: false

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
    traslado =
      {"cfdi:Traslado",
       [
         {"Base", "1000.00"},
         {"Impuesto", "002"},
         {"TipoFactor", "Tasa"},
         {"TasaOCuota", "0.160000"},
         {"Importe", "160.00"}
       ], []}

    retencion =
      {"cfdi:Retencion",
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
         {"cfdi:InformacionAduanera", [{"NumeroPedimento", "10  24  3001 0007777"}], []}
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
         {"cfdi:InformacionAduanera", [{"NumeroPedimento", "15  48  0301 0001234"}], []},
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
       {"cfdi:InformacionGlobal", [{"Periodicidad", "01"}, {"Meses", "01"}, {"Año", "2026"}], []},
       {"cfdi:CfdiRelacionados", [{"TipoRelacion", "04"}],
        [
          {"cfdi:CfdiRelacionado", [{"UUID", "11111111-1111-1111-1111-111111111111"}], []},
          {"cfdi:CfdiRelacionado", [{"UUID", "22222222-2222-2222-2222-222222222222"}], []}
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
    {tag, Enum.sort_by(attrs, &elem(&1, 0)),
     Enum.map(children, &normalize/1) |> Enum.reject(&ignorable?/1)}
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
