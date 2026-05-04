defmodule Cfdi.Complemento do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Complemento", accepts_children: true

  child :children, :list

  def to_element(nil), do: nil

  def to_element(c) when is_struct(c, __MODULE__) do
    kids = (c.children || []) |> Enum.reject(&is_nil/1)
    XmlBuilder.element({"cfdi:Complemento", %{}, kids})
  end
end
