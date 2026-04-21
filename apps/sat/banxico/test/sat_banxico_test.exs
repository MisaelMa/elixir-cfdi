defmodule Sat.BanxicoTest do
  use ExUnit.Case, async: true

  alias Sat.Banxico.Types

  test "resolve_serie returns correct series for USD" do
    assert {:ok, "SF43718"} = Types.resolve_serie(:USD)
  end

  test "resolve_serie returns error for unknown currency" do
    assert {:error, _} = Types.resolve_serie(:XXX)
  end

  test "serie_banxico has all currencies" do
    series = Types.serie_banxico()
    assert Map.has_key?(series, :USD)
    assert Map.has_key?(series, :EUR)
    assert Map.has_key?(series, :GBP)
    assert Map.has_key?(series, :JPY)
    assert Map.has_key?(series, :CAD)
  end
end
