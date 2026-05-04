defmodule Cfdi.Transform.XsltParserTest do
  @moduledoc """
  Port de [`xslt.test.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/transform/test/xslt.test.ts).
  """

  use ExUnit.Case, async: true

  alias Cfdi.Transform.XsltParser

  @files Path.expand("../../../files", __DIR__)
  @xslt_path Path.join(@files, "4.0/cadenaoriginal.xslt")

  describe "xslt parser" do
    test "should parse cadenaoriginal.xslt and extract templates" do
      {:ok, %{templates: templates}} = XsltParser.parse_file(@xslt_path)

      assert map_size(templates) > 0
      assert Map.has_key?(templates, "cfdi:Comprobante")
      assert Map.has_key?(templates, "cfdi:Emisor")
      assert Map.has_key?(templates, "cfdi:Receptor")
      assert Map.has_key?(templates, "cfdi:Concepto")
      assert Map.has_key?(templates, "cfdi:Impuestos")
      assert Map.has_key?(templates, "cfdi:Complemento")
    end

    test "should parse complemento templates" do
      {:ok, %{templates: templates}} = XsltParser.parse_file(@xslt_path)

      assert Map.has_key?(templates, "vehiculousado:VehiculoUsado")
      assert Map.has_key?(templates, "pago20:Pagos")
      assert Map.has_key?(templates, "nomina12:Nomina")
    end

    test "should extract correct attribute order for Comprobante" do
      {:ok, %{templates: templates}} = XsltParser.parse_file(@xslt_path)
      comprobante = templates["cfdi:Comprobante"]
      attr_rules = Enum.filter(comprobante.rules, &(&1.type == :attr))

      assert Enum.at(attr_rules, 0) == %{type: :attr, name: "Version", required: true}
      assert Enum.at(attr_rules, 1) == %{type: :attr, name: "Serie", required: false}
      assert Enum.at(attr_rules, 2) == %{type: :attr, name: "Folio", required: false}
      assert Enum.at(attr_rules, 3) == %{type: :attr, name: "Fecha", required: true}
    end

    test "should distinguish Requerido from Opcional" do
      {:ok, %{templates: templates}} = XsltParser.parse_file(@xslt_path)
      emisor = templates["cfdi:Emisor"]
      attr_rules = Enum.filter(emisor.rules, &(&1.type == :attr))

      assert Enum.at(attr_rules, 0) == %{type: :attr, name: "Rfc", required: true}
      assert Enum.at(attr_rules, 3) == %{type: :attr, name: "FacAtrAdquirente", required: false}
    end

    test "should extract namespaces from XSLT" do
      {:ok, %{namespaces: ns}} = XsltParser.parse_file(@xslt_path)

      assert ns["cfdi"] == "http://www.sat.gob.mx/cfd/4"
      assert ns["pago20"] == "http://www.sat.gob.mx/Pagos20"
      assert ns["nomina12"] == "http://www.sat.gob.mx/nomina12"
      assert ns["vehiculousado"] == "http://www.sat.gob.mx/vehiculousado"
    end
  end
end
