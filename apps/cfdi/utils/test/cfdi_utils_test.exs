defmodule Cfdi.UtilsTest do
  use ExUnit.Case, async: true

  alias Cfdi.Utils.NumeroALetras
  alias Cfdi.Utils.File, as: FileUtil

  test "NumeroALetras converts zero" do
    assert NumeroALetras.convert(0) =~ "CERO"
  end

  test "NumeroALetras converts one" do
    result = NumeroALetras.convert(1)
    assert result =~ "UN"
    assert result =~ "PESO"
  end

  test "NumeroALetras converts thousands" do
    result = NumeroALetras.convert(1500.50)
    assert result =~ "UN MIL QUINIENTOS"
    assert result =~ "50/100 M.N"
  end

  test "NumeroALetras converts millions" do
    result = NumeroALetras.convert(2_000_000)
    assert result =~ "DOS MILLONES"
  end

  test "is_path? detects paths" do
    assert FileUtil.is_path?("/some/path")
    assert FileUtil.is_path?("file.txt")
    refute FileUtil.is_path?("hello")
  end
end
