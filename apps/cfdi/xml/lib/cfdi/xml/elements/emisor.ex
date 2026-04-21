defmodule Cfdi.Xml.Elements.Emisor do
  @moduledoc false

  alias XmlBuilder

  @spec to_element(Cfdi.Xml.Types.Emisor.t() | nil) :: tuple() | nil
  def to_element(nil), do: nil

  def to_element(%Cfdi.Xml.Types.Emisor{} = e) do
    attrs =
      e
      |> Map.from_struct()
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {Atom.to_string(k), to_string(v)} end)

    XmlBuilder.element({"cfdi:Emisor", attrs, nil})
  end
end
