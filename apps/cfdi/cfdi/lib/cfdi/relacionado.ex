defmodule Cfdi.Relacionado do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:CfdiRelacionado"

  attribute :UUID, :string
  attribute :TipoRelacion, :string

  # Legacy bridge: original `to_element/1` accepted a plain map.
  def to_element(data) when is_map(data) and not is_struct(data, __MODULE__) do
    attrs =
      data
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)

    XmlBuilder.element({"cfdi:CfdiRelacionado", attrs, nil})
  end

  @spec relacionados_block([t() | map()]) :: tuple() | nil
  def relacionados_block([]), do: nil

  def relacionados_block(items) when is_list(items) do
    kids = Enum.map(items, &to_element/1)
    XmlBuilder.element({"cfdi:CfdiRelacionados", %{}, kids})
  end
end
