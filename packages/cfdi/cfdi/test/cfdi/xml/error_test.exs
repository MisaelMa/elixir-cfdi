defmodule Cfdi.Xml.ErrorTest do
  use ExUnit.Case, async: true

  alias Cfdi.Xml.Error

  test "build/2 envuelve una excepción nativa" do
    err = Error.build(%RuntimeError{message: "boom"}, name: "@cfdi/xml", method: "sellar")
    assert %Error{code: "error", name: "@cfdi/xml", method: "sellar", message: "boom"} = err
    assert Error.message(err) == "@cfdi/xml: boom sellar"
  end

  test "build/2 acepta strings y los usa como mensaje" do
    err = Error.build("algo falló", name: "ctx")
    assert %Error{message: "algo falló", name: "ctx"} = err
  end

  test "build/2 reutiliza un Cfdi.Xml.Error existente actualizando nombre/método" do
    base = Error.exception(message: "x", code: "E1", name: "orig", method: "m1")
    updated = Error.build(base, name: "nuevo", method: "m2")
    assert %Error{message: "x", code: "E1", name: "nuevo", method: "m2"} = updated
  end
end
