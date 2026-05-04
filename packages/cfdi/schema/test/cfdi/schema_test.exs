defmodule Cfdi.SchemaTest do
  use ExUnit.Case

  @sample_xsd ~S"""
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified"/>
  """

  test "load/2 parsea XSD desde disco" do
    dir = System.tmp_dir!()
    path = Path.join(dir, "sample_cfdi_schema_test.xsd")
    File.write!(path, @sample_xsd)

    loader = Cfdi.Schema.new(root: dir)
    assert {:ok, {"xs:schema", _attrs, _kids}} = Cfdi.Schema.load(loader, "sample_cfdi_schema_test.xsd")
  end

  test "load/2 error si falta archivo" do
    loader = Cfdi.Schema.new(root: System.tmp_dir!())
    assert {:error, {:missing_schema, _}} = Cfdi.Schema.load(loader, "no_existe.xsd")
  end
end