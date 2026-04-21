defmodule Cfdi.TypesTest do
  use ExUnit.Case

  alias Cfdi.Types.{
    Complemento,
    Comprobante,
    Concepto,
    Config,
    Emisor,
    Impuestos,
    Receptor,
    Retencion,
    Traslado
  }

  describe "Comprobante" do
    test "construye struct con atributos CFDI" do
      c = %Comprobante{
        Version: "4.0",
        Serie: "A",
        Folio: "1",
        Moneda: "MXN",
        Total: "100.00"
      }

      assert Map.get(c, :Version) == "4.0"
      assert Map.get(c, :Moneda) == "MXN"
    end
  end

  describe "Emisor y Receptor" do
    test "acepta RFC y régimen" do
      e = %Emisor{Rfc: "AAA010101AAA", RegimenFiscal: "601"}
      r = %Receptor{Rfc: "BBB010101BBB", UsoCFDI: "G03"}

      assert Map.get(e, :Rfc) == "AAA010101AAA"
      assert Map.get(r, :UsoCFDI) == "G03"
    end
  end

  describe "Concepto" do
    test "admite listas anidadas" do
      c = %Concepto{
        ClaveProdServ: "01010101",
        Cantidad: "1",
        impuestos: [],
        parte: []
      }

      assert Map.get(c, :ClaveProdServ) == "01010101"
      assert c.impuestos == []
    end
  end

  describe "Impuestos, Traslado y Retencion" do
    test "compone totales y detalle" do
      t = %Traslado{Impuesto: "002", Importe: "16.00"}
      imp = %Impuestos{traslados: [t], retenciones: []}

      assert Map.get(hd(imp.traslados), :Importe) == "16.00"
      assert Map.get(%Retencion{Base: "100"}, :Base) == "100"
    end
  end

  describe "Config" do
    test "admite rutas y hojas XSLT" do
      cfg = %Config{
        schema_path: "/xsd",
        debug: true,
        saxon_path: "/saxon",
        xslt_sheets: %{"tfd" => "/cadenaoriginal.xslt"}
      }

      assert cfg.debug == true
      assert cfg.xslt_sheets["tfd"] == "/cadenaoriginal.xslt"
    end
  end

  describe "Complemento" do
    test "get_complement/1 arma schema_location y xmlns_key" do
      comp = %Complemento{
        key: "pago20:Pagos",
        xmlns: "http://www.sat.gob.mx/Pagos20",
        xsd: "http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd",
        data: %{totales: %{}}
      }

      m = Complemento.get_complement(comp)

      assert m.xmlns_key == "pago20"
      assert m.key == "pago20:Pagos"
      assert m.complement == %{totales: %{}}
      assert String.starts_with?(m.schema_location, "http://www.sat.gob.mx/Pagos20")
    end
  end
end
