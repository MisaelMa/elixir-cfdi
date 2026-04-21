defmodule Cfdi.Xml.Elements.Receptor do
  @moduledoc false

  alias XmlBuilder

  @spec to_element(Cfdi.Xml.Types.Receptor.t() | nil) :: tuple() | nil
  def to_element(nil), do: nil

  def to_element(%Cfdi.Xml.Types.Receptor{} = r) do
    attrs =
      r
      |> Map.from_struct()
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {Atom.to_string(k), to_string(v)} end)

    XmlBuilder.element({"cfdi:Receptor", attrs, nil})
  end
end
