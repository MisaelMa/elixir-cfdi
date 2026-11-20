defmodule Cfdi.Transform.XsltLocalizerTest do
  use ExUnit.Case, async: true

  alias Cfdi.Transform.XsltLocalizer

  @main_url "http://www.sat.gob.mx/sitio_internet/cfd/4/cadenaoriginal_4_0/cadenaoriginal_4_0.xslt"

  @main """
  <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:include href="http://www.sat.gob.mx/sitio_internet/cfd/2/cadenaoriginal_2_0/utilerias.xslt"/>
  <xsl:include href="http://www.sat.gob.mx/sitio_internet/cfd/nomina/nomina12.xslt"/>
  <xsl:include href="./ya_local.xslt"/>
  </xsl:stylesheet>
  """

  test "remote_includes/1 lista solo los href http(s)" do
    assert XsltLocalizer.remote_includes(@main) == [
             "http://www.sat.gob.mx/sitio_internet/cfd/2/cadenaoriginal_2_0/utilerias.xslt",
             "http://www.sat.gob.mx/sitio_internet/cfd/nomina/nomina12.xslt"
           ]
  end

  test "localize/2 reescribe los href remotos a rutas relativas y deja los locales" do
    {out, mapping} = XsltLocalizer.localize(@main, "./complementos")

    assert out =~ ~s(href="./complementos/utilerias.xslt")
    assert out =~ ~s(href="./complementos/nomina12.xslt")
    assert out =~ ~s(href="./ya_local.xslt")
    refute out =~ "http://www.sat.gob.mx"

    assert mapping == [
             {"http://www.sat.gob.mx/sitio_internet/cfd/2/cadenaoriginal_2_0/utilerias.xslt",
              "utilerias.xslt"},
             {"http://www.sat.gob.mx/sitio_internet/cfd/nomina/nomina12.xslt", "nomina12.xslt"}
           ]
  end

  test "update/3 descarga el principal y los complementos y deja un arbol localizado" do
    dir = Path.join(System.tmp_dir!(), "localizer_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)

    fetch = fn
      @main_url -> {:ok, @main}
      "http://www.sat.gob.mx/" <> _ -> {:ok, "<xsl:stylesheet/>"}
    end

    assert {:ok, files} = XsltLocalizer.update(dir, fetch, url: @main_url)

    assert File.exists?(Path.join(dir, "cadenaoriginal_4_0.xslt"))
    assert File.exists?(Path.join(dir, "complementos/utilerias.xslt"))
    assert File.exists?(Path.join(dir, "complementos/nomina12.xslt"))
    assert length(files) == 3

    refute File.read!(Path.join(dir, "cadenaoriginal_4_0.xslt")) =~ ~s(href="http)
  end

  test "update/3 propaga el error de descarga sin escribir nada a medias" do
    dir = Path.join(System.tmp_dir!(), "localizer_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)

    fetch = fn
      @main_url -> {:ok, @main}
      _ -> {:error, :timeout}
    end

    assert {:error, {:download_failed, _url, :timeout}} =
             XsltLocalizer.update(dir, fetch, url: @main_url)

    refute File.exists?(Path.join(dir, "cadenaoriginal_4_0.xslt"))
  end

  test "bundled_xslt/0 apunta al XSLT 4.0 incluido en priv" do
    path = Cfdi.Transform.bundled_xslt()
    assert File.exists?(path)
    assert {:ok, %{templates: t}} = Cfdi.Transform.XsltParser.parse_file(path, strict: true)
    assert Map.has_key?(t, "pago20:Pagos")
    assert Map.has_key?(t, "nomina12:Nomina")
  end
end
