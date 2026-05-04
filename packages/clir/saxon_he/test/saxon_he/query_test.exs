defmodule SaxonHe.QueryTest do
  use ExUnit.Case, async: true

  alias SaxonHe.Query

  describe "build_args/1" do
    test "incluye -q y -s cuando se setean" do
      tmp_xml = touch_temp("in.xml")

      args =
        Query.new()
        |> Query.q("q.xq")
        |> Query.s(tmp_xml)
        |> Query.build_args()

      assert "-q:q.xq" in args
      assert "-s:#{tmp_xml}" in args
    end

    test "incluye los flags query-específicos" do
      args =
        Query.new()
        |> Query.qs("doc('a.xml')//*")
        |> Query.projection("on")
        |> Query.stream("off")
        |> Query.update("on")
        |> Query.wrap()
        |> Query.backup("off")
        |> Query.build_args()

      assert "-qs:doc('a.xml')//*" in args
      assert "-projection:on" in args
      assert "-stream:off" in args
      assert "-update:on" in args
      assert "-wrap" in args
      assert "-a:off" in args
    end

    test "incluye flags compartidos" do
      args =
        Query.new()
        |> Query.catalog("cat.xml")
        |> Query.dtd("recover")
        |> Query.outval("recover")
        |> Query.build_args()

      assert "-catalog:cat.xml" in args
      assert "-dtd:recover" in args
      assert "-outval:recover" in args
    end
  end

  describe "constructor" do
    test "binary por defecto es 'query'" do
      assert Query.new().binary == "query"
    end
  end

  defp touch_temp(name) do
    path = Path.join(System.tmp_dir!(), "saxon_he_q_test_#{System.unique_integer([:positive])}_#{name}")
    File.write!(path, "")
    on_exit(fn -> File.rm(path) end)
    path
  end
end
