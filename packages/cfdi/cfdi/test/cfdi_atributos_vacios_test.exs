defmodule CFDIAtributosVaciosTest do
  use ExUnit.Case, async: true

  alias Cfdi.{Comprobante, Concepto, Emisor, Receptor}

  # Un atributo opcional sin valor debe OMITIRSE del XML: `attr=""` no valida
  # contra los patrones del XSD (p. ej. iedu:tRFC en `rfcPago`).
  defp cfdi_con_iedu(iedu_attrs) do
    concepto =
      %Concepto{
        ClaveProdServ: "86121500",
        Cantidad: "1",
        ClaveUnidad: "E48",
        Descripcion: "Colegiatura",
        ValorUnitario: "1000",
        Importe: "1000",
        ObjetoImp: "02"
      }
      |> Concepto.add_complemento(
        Cfdi.Complementos.Iedu.new(
          Map.merge(
            %{version: "1.0", nombreAlumno: "Pedro Pérez", CURP: "PEPE900101HDFRRD09"},
            iedu_attrs
          )
        )
      )

    %Comprobante{
      Version: "4.0",
      Fecha: "2026-07-31T10:00:00",
      SubTotal: "1000.00",
      Moneda: "MXN",
      Total: "1000.00",
      TipoDeComprobante: "I",
      Exportacion: "01",
      LugarExpedicion: "06600"
    }
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
    |> CFDI.new()
  end

  test "un complemento con atributo nil no emite ese atributo" do
    xml = cfdi_con_iedu(%{rfcPago: nil, autRVOE: nil}) |> CFDI.to_xml()

    assert xml =~ ~s(nombreAlumno="Pedro Pérez")
    refute xml =~ "rfcPago"
    refute xml =~ "autRVOE"
  end

  test "con valor presente el atributo se emite" do
    xml = cfdi_con_iedu(%{rfcPago: "PEPE900101A11"}) |> CFDI.to_xml()
    assert xml =~ ~s(rfcPago="PEPE900101A11")
  end

  test "ningun atributo nil llega al XML (regresion general)" do
    xml = cfdi_con_iedu(%{rfcPago: nil}) |> CFDI.to_xml()
    refute xml =~ ~s(="")
  end

  test "un atributo con cadena vacia explicita se conserva (roundtrip de addendas)" do
    xml =
      ~s(<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0">) <>
        ~s(<cfdi:Addenda><x:Foo xmlns:x="urn:x" opcional=""/></cfdi:Addenda></cfdi:Comprobante>)

    {:ok, cfdi} = CFDI.from_xml(xml)
    assert CFDI.to_xml(cfdi) =~ ~s(opcional="")
  end

  test "la cadena original coincide con xsltproc cuando un opcional es nil" do
    cfdi = cfdi_con_iedu(%{rfcPago: nil, nivelEducativo: "Preescolar", autRVOE: "AUT-001"})
    xslt = Path.expand("fixtures/cadena_iedu.xslt", __DIR__)

    {:ok, cadena} = CFDI.generar_cadena_original(cfdi, xslt: xslt)

    # `rfcPago` (Opcional) ausente: no aporta ni un campo vacio extra.
    assert cadena == "||1.0|Pedro Pérez|PEPE900101HDFRRD09|Preescolar|AUT-001||"

    if System.find_executable("xsltproc") do
      tmp = Path.join(System.tmp_dir!(), "cfdi_iedu_#{System.unique_integer([:positive])}.xml")
      File.write!(tmp, CFDI.to_xml(cfdi))
      {salida, 0} = System.cmd("xsltproc", [xslt, tmp])
      File.rm(tmp)
      assert String.trim(salida) == cadena
    end
  end
end
