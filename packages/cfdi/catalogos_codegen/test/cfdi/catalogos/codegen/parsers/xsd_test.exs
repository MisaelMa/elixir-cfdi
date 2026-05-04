defmodule Cfdi.Catalogos.Codegen.Parsers.XsdTest do
  use ExUnit.Case, async: true

  alias Cfdi.Catalogos.Codegen.Parsers.Xsd

  @valid_xsd_single """
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xs:simpleType name="c_X">
      <xs:restriction base="xs:string">
        <xs:enumeration value="01"/>
        <xs:enumeration value="02"/>
        <xs:enumeration value="03"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:schema>
  """

  @valid_xsd_multiple """
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xs:simpleType name="c_FormaPago">
      <xs:restriction base="xs:string">
        <xs:enumeration value="01"/>
        <xs:enumeration value="02"/>
      </xs:restriction>
    </xs:simpleType>
    <xs:simpleType name="c_MetodoPago">
      <xs:restriction base="xs:string">
        <xs:enumeration value="PUE"/>
        <xs:enumeration value="PPD"/>
        <xs:enumeration value="PUE2"/>
      </xs:restriction>
    </xs:simpleType>
  </xs:schema>
  """

  @empty_xsd """
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  </xs:schema>
  """

  @malformed_xsd """
  <?xml version="1.0" encoding="UTF-8"?>
  <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xs:simpleType name="c_X">
      <xs:restriction base="xs:string">
        <xs:enumeration value="01"/>
  """

  describe "parse_string/1" do
    test "extracts single simpleType with 3 enumerations" do
      assert {:ok, result} = Xsd.parse_string(@valid_xsd_single)
      assert result == %{"c_X" => ["01", "02", "03"]}
    end

    test "extracts multiple simpleTypes" do
      assert {:ok, result} = Xsd.parse_string(@valid_xsd_multiple)
      assert result == %{
        "c_FormaPago" => ["01", "02"],
        "c_MetodoPago" => ["PUE", "PPD", "PUE2"]
      }
    end

    test "returns empty map when no simpleTypes present" do
      assert {:ok, result} = Xsd.parse_string(@empty_xsd)
      assert result == %{}
    end

    test "returns error for malformed (truncated) XSD" do
      assert {:error, _reason} = Xsd.parse_string(@malformed_xsd)
    end
  end

  describe "parse/1" do
    test "parses tiny.xsd fixture and returns both simpleTypes" do
      path =
        Path.join([
          __DIR__,
          "..",
          "..",
          "..",
          "..",
          "fixtures",
          "tiny.xsd"
        ])
        |> Path.expand()

      assert {:ok, result} = Xsd.parse(path)
      assert result == %{"c_A" => ["01", "02", "03"], "c_B" => ["X", "Y"]}
    end

    test "parses a real XSD file" do
      path = "/Users/amir/Documents/proyectos/recreando/sat/elixir-cfdi/packages/files/4.0/catCFDI.xsd"

      if File.exists?(path) do
        assert {:ok, result} = Xsd.parse(path)
        assert is_map(result)
        assert Map.has_key?(result, "c_FormaPago")
        assert is_list(result["c_FormaPago"])
        assert length(result["c_FormaPago"]) > 0
      else
        :skip
      end
    end

    test "returns error for missing file" do
      assert {:error, :enoent} = Xsd.parse("/nonexistent/path/file.xsd")
    end
  end
end
