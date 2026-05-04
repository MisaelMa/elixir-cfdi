defmodule Cfdi.Xml.UtilsTest do
  use ExUnit.Case, async: true

  alias Cfdi.Xml.Utils

  test "sort_object/2 respeta el orden dado y preserva llaves extra al final" do
    map = %{Total: 10, Version: "4.0", Serie: "A", Folio: "1"}
    order = [:Version, :Serie, :Folio, :Total]

    assert Utils.sort_object(map, order) ==
             [{:Version, "4.0"}, {:Serie, "A"}, {:Folio, "1"}, {:Total, 10}]
  end

  test "sort_object/2 ignora llaves listadas que no existen" do
    map = %{A: 1, B: 2}
    assert Utils.sort_object(map, [:Z, :A, :B, :Y]) == [{:A, 1}, {:B, 2}]
  end

  test "schema_build/1 une URIs con espacio y elimina vacíos/duplicados" do
    assert Utils.schema_build([
             "http://www.sat.gob.mx/cfd/4",
             "http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd",
             "",
             "http://www.sat.gob.mx/cfd/4"
           ]) ==
             "http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd"
  end
end
