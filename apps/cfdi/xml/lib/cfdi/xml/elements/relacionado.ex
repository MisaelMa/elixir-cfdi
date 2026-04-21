defmodule Cfdi.Xml.Elements.Relacionado do
  @moduledoc false

  alias XmlBuilder

  @spec to_element(Cfdi.Xml.Types.Relacionado.t() | map()) :: tuple()
  def to_element(%Cfdi.Xml.Types.Relacionado{} = r) do
    r |> Map.from_struct() |> to_element()
  end

  def to_element(data) when is_map(data) do
    attrs =
      data
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)

    XmlBuilder.element({"cfdi:CfdiRelacionado", attrs, nil})
  end

  @spec relacionados_block(list(map())) :: tuple() | nil
  def relacionados_block([]), do: nil

  def relacionados_block(items) when is_list(items) do
    kids = Enum.map(items, &to_element/1)
    XmlBuilder.element({"cfdi:CfdiRelacionados", %{}, kids})
  end
end
