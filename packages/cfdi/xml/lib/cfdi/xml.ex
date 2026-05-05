defmodule Cfdi.Xml do
  @moduledoc """
  Utilidades para convertir comprobantes CFDI en XML a mapas anidados.

  La conversión principal está en `Cfdi.Xml.Parser`, expuesta aquí
  como `parse/2` por conveniencia.
  """

  alias Cfdi.Xml.Parser

  @doc """
  Atajo de `Cfdi.Xml.Parser.parse/2`.
  """
  defdelegate parse(path_or_xml, opts \\ []), to: Parser
end
