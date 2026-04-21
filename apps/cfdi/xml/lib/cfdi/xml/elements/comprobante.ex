defmodule Cfdi.Xml.Elements.Comprobante do
  @moduledoc false

  alias XmlBuilder

  @cfdi_ns "http://www.sat.gob.mx/cfd/4"

  @spec to_element(Cfdi.Xml.Types.Comprobante.t(), iodata) :: tuple()
  def to_element(%Cfdi.Xml.Types.Comprobante{} = c, children \\ []) do
    attrs =
      c
      |> Map.from_struct()
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {Atom.to_string(k), to_string(v)} end)
      |> Map.put("xmlns:cfdi", @cfdi_ns)
      |> Map.put("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")

    XmlBuilder.element({"cfdi:Comprobante", attrs, List.wrap(children)})
  end
end
