defmodule Cfdi.Xml2Json do
  @moduledoc """
  Utilidades para convertir comprobantes CFDI en XML a mapas anidados.

  La conversión principal está en `Cfdi.Xml2Json.XmlToJson`, expuesta aquí
  como `parse/2` por conveniencia.
  """

  alias Cfdi.Xml2Json.XmlToJson

  @doc """
  Atajo de `Cfdi.Xml2Json.XmlToJson.parse/2`.
  """
  defdelegate parse(path_or_xml, opts \\ []), to: XmlToJson
end
