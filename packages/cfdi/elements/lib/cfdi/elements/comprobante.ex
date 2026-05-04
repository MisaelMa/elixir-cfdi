defmodule Cfdi.Elements.Comprobante do
  @moduledoc """
  Tag name constants for CFDI Comprobante elements.
  """

  @comprobante "cfdi:Comprobante"
  @emisor "cfdi:Emisor"
  @receptor "cfdi:Receptor"
  @conceptos "cfdi:Conceptos"
  @concepto "cfdi:Concepto"
  @impuestos "cfdi:Impuestos"
  @traslados "cfdi:Traslados"
  @traslado "cfdi:Traslado"
  @complemento "cfdi:Complemento"

  def comprobante, do: @comprobante
  def emisor, do: @emisor
  def receptor, do: @receptor
  def conceptos, do: @conceptos
  def concepto, do: @concepto
  def impuestos, do: @impuestos
  def traslados, do: @traslados
  def traslado, do: @traslado
  def complemento, do: @complemento
end
