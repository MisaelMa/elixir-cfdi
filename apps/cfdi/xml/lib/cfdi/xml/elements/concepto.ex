defmodule Cfdi.Xml.Elements.Concepto do
  @moduledoc false

  alias XmlBuilder

  @spec to_element(Cfdi.Xml.Types.Concepto.t()) :: tuple()
  def to_element(%Cfdi.Xml.Types.Concepto{} = c) do
    skip = [:impuestos, :informacion_aduanera, :cuenta_predial, :parte]

    attrs =
      c
      |> Map.from_struct()
      |> Enum.reject(fn {k, v} -> k in skip or is_nil(v) end)
      |> Map.new(fn {k, v} -> {Atom.to_string(k), to_string(v)} end)

    XmlBuilder.element({"cfdi:Concepto", attrs, nil})
  end

  @spec conceptos_block(list(Cfdi.Xml.Types.Concepto.t())) :: tuple() | nil
  def conceptos_block([]), do: nil

  def conceptos_block(conceptos) when is_list(conceptos) do
    kids = Enum.map(conceptos, &to_element/1)
    XmlBuilder.element({"cfdi:Conceptos", %{}, kids})
  end
end
