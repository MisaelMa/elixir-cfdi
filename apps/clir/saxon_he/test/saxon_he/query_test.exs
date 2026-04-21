defmodule SaxonHe.QueryTest do
  use ExUnit.Case

  describe "build_args/1" do
    test "includes -q and -s when set" do
      args =
        SaxonHe.Query.new()
        |> SaxonHe.Query.query_file("q.xq")
        |> SaxonHe.Query.source("in.xml")
        |> SaxonHe.Query.build_args()

      assert "-q:q.xq" in args
      assert "-s:in.xml" in args
    end
  end
end
