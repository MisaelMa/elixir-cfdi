defmodule SaxonHe.TransformTest do
  use ExUnit.Case

  describe "build_args/1" do
    test "includes -s, -xsl, -o when set" do
      args =
        SaxonHe.Transform.new()
        |> SaxonHe.Transform.source("in.xml")
        |> SaxonHe.Transform.xsl("t.xsl")
        |> SaxonHe.Transform.output("out.xml")
        |> SaxonHe.Transform.build_args()

      assert "-s:in.xml" in args
      assert "-xsl:t.xsl" in args
      assert "-o:out.xml" in args
    end

    test "appends extra_args from options" do
      t =
        SaxonHe.Transform.new()
        |> SaxonHe.Transform.source("a.xml")
        |> SaxonHe.Transform.xsl("b.xsl")
        |> SaxonHe.Transform.output("c.xml")
        |> Map.put(:options, extra_args: ["-t"])

      assert "-t" in SaxonHe.Transform.build_args(t)
    end
  end
end
