defmodule SaxonHe.TransformTest do
  use ExUnit.Case, async: true

  alias SaxonHe.Transform

  describe "build_args/1" do
    test "incluye -s, -xsl, -o cuando se setean" do
      tmp_xml = touch_temp("in.xml")
      tmp_xsl = touch_temp("t.xsl")

      args =
        Transform.new()
        |> Transform.s(tmp_xml)
        |> Transform.xsl(tmp_xsl)
        |> Transform.o("out.xml")
        |> Transform.build_args()

      assert "-s:#{tmp_xml}" in args
      assert "-xsl:#{tmp_xsl}" in args
      assert "-o:out.xml" in args
    end

    test "incluye los flags transform-específicos" do
      args =
        Transform.new()
        |> Transform.warnings("silent")
        |> Transform.target("HE")
        |> Transform.threads(4)
        |> Transform.jit("on")
        |> Transform.it("main")
        |> Transform.im("mode1")
        |> Transform.nogo()
        |> Transform.export("export.json")
        |> Transform.build_args()

      assert "-warnings:silent" in args
      assert "-target:HE" in args
      assert "-threads:4" in args
      assert "-jit:on" in args
      assert "-it:main" in args
      assert "-im:mode1" in args
      assert "-nogo" in args
      assert "-export:export.json" in args
    end

    test "incluye flags compartidos de CliShare (catalog/dtd/expand/...)" do
      args =
        Transform.new()
        |> Transform.catalog("cat.xml")
        |> Transform.dtd("off")
        |> Transform.expand("on")
        |> Transform.ext("off")
        |> Transform.l("on")
        |> Transform.t()
        |> Transform.tree("tiny")
        |> Transform.xi("on")
        |> Transform.xmlversion("1.1")
        |> Transform.feature("http://saxon.sf.net/feature/x=true")
        |> Transform.build_args()

      assert "-catalog:cat.xml" in args
      assert "-dtd:off" in args
      assert "-expand:on" in args
      assert "-ext:off" in args
      assert "-l:on" in args
      assert "-t" in args
      assert "-tree:tiny" in args
      assert "-xi:on" in args
      assert "-xmlversion:1.1" in args
      assert "--feature:http://saxon.sf.net/feature/x=true" in args
    end

    test "preserva el orden de inserción" do
      tmp_xml = touch_temp("a.xml")
      tmp_xsl = touch_temp("b.xsl")

      args =
        Transform.new()
        |> Transform.s(tmp_xml)
        |> Transform.xsl(tmp_xsl)
        |> Transform.o("c.xml")
        |> Transform.build_args()

      assert args == ["-s:#{tmp_xml}", "-xsl:#{tmp_xsl}", "-o:c.xml"]
    end
  end

  describe "validaciones" do
    test "s/2 lanza si el XML no existe" do
      assert_raise ArgumentError, ~r/No se puede encontrar el xml/, fn ->
        Transform.new() |> Transform.s("/nope/no-existe.xml")
      end
    end

    test "xsl/2 lanza si el XSLT no existe" do
      assert_raise ArgumentError, ~r/No se puede encontrar el archivo XSLT/, fn ->
        Transform.new() |> Transform.xsl("/nope/no-existe.xslt")
      end
    end
  end

  describe "constructor" do
    test "binary por defecto es 'transform'" do
      assert Transform.new().binary == "transform"
    end

    test "acepta :binary custom" do
      assert Transform.new(binary: "xslt3").binary == "xslt3"
    end
  end

  defp touch_temp(name) do
    path = Path.join(System.tmp_dir!(), "saxon_he_test_#{System.unique_integer([:positive])}_#{name}")
    File.write!(path, "")
    on_exit(fn -> File.rm(path) end)
    path
  end
end
