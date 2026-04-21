defmodule Cfdi.Xsd.SchemaTest do
  use ExUnit.Case

  alias Cfdi.Xsd.Schema

  test "cfdi/1 carga esquema embebido" do
    assert {:ok, schema} = Schema.cfdi(Schema.of())
    assert schema != nil
  end

  test "concepto/1 carga esquema embebido" do
    assert {:ok, schema} = Schema.concepto(Schema.of())
    assert schema != nil
  end

  test "set_config/1 construye loader con opciones" do
    s = Schema.set_config(schema_root: Path.join(:code.priv_dir(:cfdi_xsd), "schemas"))
    assert {:ok, _} = Schema.cfdi(s)
  end
end
