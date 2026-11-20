defmodule Cfdi.Transform.XsltParserTest do
  @moduledoc """
  Port de [`xslt.test.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/transform/test/xslt.test.ts).
  """

  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

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

  describe "xsl:include remotos (#4)" do
    setup do
      dir = Path.join(System.tmp_dir!(), "xslt_remote_#{System.unique_integer([:positive])}")
      File.mkdir_p!(dir)
      on_exit(fn -> File.rm_rf!(dir) end)

      main = Path.join(dir, "main.xslt")

      File.write!(main, """
      <?xml version="1.0" encoding="UTF-8"?>
      <xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:foo="http://example.com/foo">
        <xsl:include href="http://www.sat.gob.mx/sitio_internet/cfd/donat/donat11.xslt"/>
        <xsl:template match="foo:Bar">
          <xsl:call-template name="Requerido">
            <xsl:with-param name="valor" select="./@A"/>
          </xsl:call-template>
        </xsl:template>
      </xsl:stylesheet>
      """)

      {:ok, main: main}
    end

    test "por defecto avisa con Logger.warning el href ignorado", %{main: main} do
      log =
        capture_log([level: :warning], fn ->
          assert {:ok, %{templates: %{"foo:Bar" => _}}} = XsltParser.parse_file(main)
        end)

      assert log =~ "http://www.sat.gob.mx/sitio_internet/cfd/donat/donat11.xslt"
    end

    test "con strict: true devuelve {:error, {:remote_include, href}}", %{main: main} do
      assert {:error,
              {:remote_include, "http://www.sat.gob.mx/sitio_internet/cfd/donat/donat11.xslt"}} =
               XsltParser.parse_file(main, strict: true)
    end

    test "un XSLT sin includes remotos no emite warning" do
      log =
        capture_log([level: :warning], fn ->
          assert {:ok, _} = XsltParser.parse_file(@xslt_path)
        end)

      refute log =~ "include"
    end
  end

  describe "xsl:if aplica a todas las reglas internas (#5)" do
    @xslt """
    <?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:vv="http://www.sat.gob.mx/ventavehiculos">
      <xsl:template match="vv:VentaVehiculos">
        <xsl:call-template name="Requerido"><xsl:with-param name="valor" select="./@version"/></xsl:call-template>
        <xsl:if test="./@version='1.1'">
          <xsl:call-template name="Requerido"><xsl:with-param name="valor" select="./@Niv"/></xsl:call-template>
        </xsl:if>
      </xsl:template>
    </xsl:stylesheet>
    """

    test "las reglas :attr dentro de xsl:if reciben :condition" do
      {:ok, %{templates: t}} = XsltParser.parse(@xslt)
      [version, niv] = t["vv:VentaVehiculos"].rules

      refute Map.has_key?(version, :condition)
      assert %{type: :attr, name: "Niv", condition: "@version='1.1'"} = niv
    end

    test "ventavehiculos11.xslt real: Niv condicionado a version" do
      {:ok, %{templates: t}} = XsltParser.parse_file(@xslt_path)
      niv = Enum.find(t["ventavehiculos:VentaVehiculos"].rules, &(&1[:name] == "Niv"))
      assert niv.condition == "@version='1.1'"
    end
  end
end
