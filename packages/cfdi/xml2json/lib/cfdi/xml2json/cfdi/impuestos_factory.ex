defmodule Cfdi.Xml2Json.Cfdi.ImpuestosFactory do
  @moduledoc """
  Factory para construir un `Cfdi.Xml2Json.Cfdi.Impuestos` desde el mapa de
  datos. Espejo de `TaxesFactory` del paquete TypeScript.
  """

  alias Cfdi.Xml2Json.Cfdi.Impuestos

  defstruct [:data]

  @type t :: %__MODULE__{data: map()}

  @spec new(map()) :: t()
  def new(data) when is_map(data), do: %__MODULE__{data: data}

  @spec build(t() | map()) :: Impuestos.t()
  def build(%__MODULE__{data: data}), do: Impuestos.new(data)
  def build(data) when is_map(data), do: Impuestos.new(data)
end
