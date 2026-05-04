defmodule Cfdi.Elements.Complementos do
  @moduledoc """
  Tag name constants for CFDI complement elements.
  """

  @impuestos_locales "implocal:ImpuestosLocales"
  @cartaporte "cartaporte31:CartaPorte"
  @ubicacion "cartaporte31:Ubicacion"
  @mercancias "cartaporte31:Mercancias"
  @mercancia "cartaporte31:Mercancia"
  @autotransporte "cartaporte31:Autotransporte"
  @vehiculo_usado "vehiculousado:VehiculoUsado"

  def impuestos_locales, do: @impuestos_locales
  def cartaporte, do: @cartaporte
  def ubicacion, do: @ubicacion
  def mercancias, do: @mercancias
  def mercancia, do: @mercancia
  def autotransporte, do: @autotransporte
  def vehiculo_usado, do: @vehiculo_usado
end
