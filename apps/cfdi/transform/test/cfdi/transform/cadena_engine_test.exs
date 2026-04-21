defmodule Cfdi.Transform.CadenaEngineTest do
  use ExUnit.Case

  alias Cfdi.Transform.CadenaEngine

  test "normalize_space/1 colapsa espacios" do
    assert CadenaEngine.normalize_space("  a  \n b  ") == "a b"
  end

  test "requerido/1 y opcional/1" do
    assert CadenaEngine.requerido("x") == "|x"
    assert CadenaEngine.opcional(nil) == ""
    assert CadenaEngine.opcional("y") == "|y"
  end
end
