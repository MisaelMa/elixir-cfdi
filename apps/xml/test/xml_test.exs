defmodule XmlTest do
  import XmlBuilder
  import Sat.Cfdi.Comprobante

  use ExUnit.Case
  doctest Xml

  test "greets the world" do
    XmlBuilder.document(
      "cfdi:Comprobante",
      %{
        "xmlns" => "http://www.sat.gob.mx/cfd/3",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" =>
          "http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd",
        Confirmacion: nil
      },
      [
        element("cfdi:Emisor", %{
          Rfc: "AAA010101AAA",
          Nombre: "ACME S.A. de C.V.",
          RegimenFiscal: "601",
          FacAtrAdquirente: "No"
        })
      ]
    )
    |> XmlBuilder.generate(encoding: "ISO-8859-1", version: "1.1", format: :pretty)
    |> IO.puts()

    IO.inspect(~c"Hello, world!")

    document(:oldschoo, %{title: "Hello, world!", encoding: "utf-8"}, [])
    |> XmlBuilder.generate(encoding: "utf-8")

    ## |> IO.puts()

    assert Xml.hello() == :world

    comprobante = %Sat.Cfdi.Comprobante{
      xsi: %{
        xmlns: nil,
        schemaLocation: []
      },
      Version: "3.2",
      Serie: "A",
      Folio: "123456",
      Fecha: "2016-12-01T12:00:00",
      FormaPago: "01",
      CondicionesDePago: "Contado",
      SubTotal: "100.00",
      Descuento: "0.00",
      Moneda: "MXN",
      TipoCambio: "1.00",
      Total: "116.00",
      TipoDeComprobante: "I",
      Exportacion: "NO",
      MetodoPago: "PUE",
      LugarExpedicion: "64000"
    }

    IO.inspect(comprobante)
  end
end
