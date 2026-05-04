defmodule CFDITest do
  use ExUnit.Case, async: true

  alias Cfdi.{Comprobante, Emisor, Receptor}

  test "to_map/1 proyecta emisor y receptor bajo cfdi:Comprobante" do
    comprobante =
      %Comprobante{}
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

    cfdi = CFDI.new(comprobante)
    IO.inspect(CFDI.to_map(cfdi, ns: false))
    IO.inspect(CFDI.to_map(cfdi, ns: true))
    IO.puts("\n=== to_json compact ===")
    IO.puts(CFDI.to_json(cfdi, ns: false, pretty: true))
    IO.puts("\n=== to_json pretty ===")
    IO.puts(CFDI.to_json(cfdi, pretty: true))
    IO.puts("\n=== to_xml pretty ===")
    IO.puts(CFDI.to_xml(cfdi, pretty: true))
    IO.puts("\n=== to_xml compact ===")
    IO.puts(CFDI.to_xml(cfdi))
    assert CFDI.to_map(cfdi) == %{
             "cfdi:Comprobante" => %{
               "cfdi:Emisor" => %{
                 Nombre: "ESCUELA KEMPER URGATE",
                 RegimenFiscal: "603",
                 Rfc: "EKU9003173C9"
               },
               "cfdi:Receptor" => %{
                 DomicilioFiscalReceptor: "36257",
                 Nombre: "XOCHILT CASAS CHAVEZ",
                 RegimenFiscalReceptor: "612",
                 Rfc: "CACX7605101P8",
                 UsoCFDI: "G03"
               }
             }
           }
  end
end
