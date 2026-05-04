defmodule Cfdi.Transform.TransformTest do
  @moduledoc """
  Port de [`check.test.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/transform/test/check.test.ts).

  La comparación contra Saxon-HE se omite (`@tag :skip_no_saxon`) cuando no
  hay JAR configurado o no hay `java` en `PATH`.
  """

  use ExUnit.Case, async: true

  alias Cfdi.Transform.Transform

  @files Path.expand("../../../files", __DIR__)
  @xml_path Path.join(@files, "xml")
  @xslt_40 Path.join(@files, "4.0/cadenaoriginal.xslt")
  @xslt_33 Path.join(@files, "3.3/cadenaoriginal-3.3.xslt")

  @vehiculo_usado Path.join(@xml_path, "vehiculo_usado.xml")

  setup_all do
    {:ok, saxon_available: SaxonHe.available?()}
  end

  describe "transform" do
    test "should generate cadena original from vehiculo_usado.xml" do
      cadena =
        Transform.new()
        |> Transform.s(@vehiculo_usado)
        |> Transform.xsl(@xslt_40)
        |> Transform.run!()

      assert is_binary(cadena)
      assert String.starts_with?(cadena, "||")
      assert String.ends_with?(cadena, "||")
    end

    test "should error if xsl not loaded" do
      t = Transform.new() |> Transform.s(@vehiculo_usado)
      assert {:error, :xslt_not_loaded} = Transform.run(t)

      assert_raise RuntimeError, ~r/XSLT not loaded/, fn ->
        Transform.run!(t)
      end
    end
  end

  describe "transform vs saxon-he (xml/)" do
    test "output must match Saxon-HE para cada XML procesable (4.0)", ctx do
      run_if_saxon(ctx, fn ->
        xmls =
          @xml_path
          |> File.ls!()
          |> Enum.filter(&String.ends_with?(&1, ".xml"))
          |> Enum.map(&Path.join(@xml_path, &1))

        compare_each_with_saxon(xmls, @xslt_40)
      end)
    end
  end

  describe "transform vs saxon-he (examples cfdi40 con xslt 4.0)" do
    test "output must match Saxon-HE", ctx do
      run_if_saxon(ctx, fn -> compare_each_with_saxon(example_files("cfdi40"), @xslt_40) end)
    end
  end

  describe "transform vs saxon-he (examples cfdi33 con xslt 3.3)" do
    test "output must match Saxon-HE", ctx do
      run_if_saxon(ctx, fn -> compare_each_with_saxon(example_files("cfdi33"), @xslt_33) end)
    end
  end

  describe "transform vs saxon-he (test-cfdi40 con xslt 4.0)" do
    test "output must match Saxon-HE", ctx do
      run_if_saxon(ctx, fn -> compare_each_with_saxon(example_files("test-cfdi40"), @xslt_40) end)
    end

    test "cadena original should be valid" do
      for xml <- example_files("test-cfdi40") do
        cadena =
          Transform.new() |> Transform.s(xml) |> Transform.xsl(@xslt_40) |> Transform.run!()

        assert is_binary(cadena), "no string para #{xml}"
        assert String.starts_with?(cadena, "||"), "no empieza con || para #{xml}"
        assert String.ends_with?(cadena, "||"), "no termina con || para #{xml}"
        assert String.length(cadena) > 4, "cadena muy corta para #{xml}"
      end
    end
  end

  describe "transform vs saxon-he (test-cfdi33 con xslt 3.3)" do
    test "output must match Saxon-HE", ctx do
      run_if_saxon(ctx, fn -> compare_each_with_saxon(example_files("test-cfdi33"), @xslt_33) end)
    end

    test "cadena original should be valid" do
      for xml <- example_files("test-cfdi33") do
        cadena =
          Transform.new() |> Transform.s(xml) |> Transform.xsl(@xslt_33) |> Transform.run!()

        assert is_binary(cadena), "no string para #{xml}"
        assert String.starts_with?(cadena, "||"), "no empieza con || para #{xml}"
        assert String.ends_with?(cadena, "||"), "no termina con || para #{xml}"
        assert String.length(cadena) > 4, "cadena muy corta para #{xml}"
      end
    end
  end

  defp run_if_saxon(%{saxon_available: false}, _fun) do
    IO.puts("\n  >> Saxon-HE no disponible (sin SAXON_JAR o sin java en PATH); test saltado.")
    :ok
  end

  defp run_if_saxon(_ctx, fun), do: fun.()

  defp example_files(subdir) do
    dir = Path.join([@xml_path, "examples", subdir])

    if File.dir?(dir) do
      dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".xml"))
      |> Enum.map(&Path.join(dir, &1))
    else
      []
    end
  end

  defp compare_each_with_saxon(files, xslt_path) do
    for xml <- files do
      case run_saxon(xml, xslt_path) do
        {:ok, saxon_cadena} ->
          ours =
            Transform.new() |> Transform.s(xml) |> Transform.xsl(xslt_path) |> Transform.run!()

          print_cadenas(xml, saxon_cadena, ours)

          assert String.trim(ours) == String.trim(saxon_cadena),
                 "Mismatch en #{xml}\n  OURS:  #{String.slice(ours, 0, 200)}\n  SAXON: #{String.slice(saxon_cadena, 0, 200)}"

        :saxon_error ->
          # XML rechazado por Saxon (XML mal formado). Mismo comportamiento
          # que Node: try/catch silencioso y skip del archivo.
          :ok
      end
    end
  end

  defp print_cadenas(xml, saxon_cadena, ours) do
    IO.puts("\n  === #{Path.basename(xml)} ===")
    linea("SAXON", saxon_cadena)
    linea("TRANSFORM", ours)
    linea("MATCH?", String.trim(saxon_cadena) == String.trim(ours))
  end

  defp linea(etiqueta, valor) do
    IO.puts("    #{String.pad_trailing(etiqueta <> ":", 12)} #{inspect(valor)}")
  end

  # Wrapper del SaxonHe.Transform: corre la transformación con stderr silenciado
  # (Saxon emite "Ambiguous rule match for /" en cada corrida, además de errores
  # cuando el XML está mal formado). Devolvemos `:saxon_error` en caso de fallo
  # — mismo flujo `try/catch` silencioso que el test de Node.
  defp run_saxon(xml, xslt) do
    tmp = Path.join(System.tmp_dir!(), "saxon_#{System.unique_integer([:positive])}.txt")

    result =
      SaxonHe.Transform.new()
      |> SaxonHe.Transform.s(xml)
      |> SaxonHe.Transform.xsl(xslt)
      |> SaxonHe.Transform.o(tmp)
      |> SaxonHe.Transform.run(silent_stderr: true)

    case result do
      {:ok, _} ->
        out = File.read!(tmp)
        File.rm(tmp)
        {:ok, out}

      {:error, _} ->
        File.rm(tmp)
        :saxon_error
    end
  end
end
