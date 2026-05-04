defmodule Cfdi.RelacionadoTest do
  use ExUnit.Case, async: true

  alias Cfdi.Relacionado
  alias Cfdi.Relacionado.CfdiRelacionado

  defp xml_fragment(element) do
    element
    |> XmlBuilder.generate(format: :none)
    |> IO.iodata_to_binary()
  end

  test "wrapper agrupa múltiples UUIDs bajo un TipoRelacion" do
    r =
      %Relacionado{TipoRelacion: "04"}
      |> Relacionado.add_relation("123e4567-e89b-12d3-a456-426614174000")
      |> Relacionado.add_relation("123e4567-e89b-12d3-a456-426614174001")

    uuids = Map.get(r, :"cfdi:CfdiRelacionado")
    assert [%CfdiRelacionado{UUID: "123e4567-e89b-12d3-a456-426614174000"},
            %CfdiRelacionado{UUID: "123e4567-e89b-12d3-a456-426614174001"}] = uuids
  end

  test "to_element/1 genera <cfdi:CfdiRelacionados> con hijos <cfdi:CfdiRelacionado>" do
    xml =
      %Relacionado{TipoRelacion: "01"}
      |> Relacionado.add_relation("UUID-1")
      |> Relacionado.add_relation("UUID-2")
      |> Relacionado.to_element()
      |> xml_fragment()

    assert xml =~ ~s(<cfdi:CfdiRelacionados TipoRelacion="01">)
    assert xml =~ ~s(<cfdi:CfdiRelacionado UUID="UUID-1"/>)
    assert xml =~ ~s(<cfdi:CfdiRelacionado UUID="UUID-2"/>)
    assert xml =~ ~s(</cfdi:CfdiRelacionados>)
  end

  test "legacy bridge: mapa plano %{UUID, TipoRelacion}" do
    xml =
      Relacionado.to_element(%{UUID: "UUID-X", TipoRelacion: "03"})
      |> xml_fragment()

    assert xml =~ ~s(<cfdi:CfdiRelacionados TipoRelacion="03">)
    assert xml =~ ~s(<cfdi:CfdiRelacionado UUID="UUID-X"/>)
  end
end
