defmodule Cfdi.Xml.Elements.Impuestos do
  @moduledoc false

  alias XmlBuilder

  @spec to_element(map() | nil) :: tuple() | nil
  def to_element(nil), do: nil

  def to_element(data) when is_map(data) do
    attrs =
      data
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)

    XmlBuilder.element({"cfdi:Impuestos", attrs, nil})
  end
end
