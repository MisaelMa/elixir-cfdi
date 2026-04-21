defmodule Cfdi.Transform.XsltParserTest do
  use ExUnit.Case

  alias Cfdi.Transform.XsltParser

  @xsl ~S"""
  <?xml version="1.0" encoding="UTF-8"?>
  <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
      <xsl:attribute name="Version" use="required"/>
    </xsl:template>
  </xsl:stylesheet>
  """

  test "parse/1 extrae plantilla raíz" do
    assert {:ok, %{templates: t}} = XsltParser.parse(@xsl)
    assert Map.has_key?(t, "/")
    assert [%{type: :attr, name: "Version", required: true}] = t["/"].rules
  end
end
