defmodule Cfdi.Xml.CfdiFactory do
  @moduledoc """
  Factory que construye un `Cfdi.Xml.Concepto` a partir de los
  datos crudos del XML. Espejo de `CFDIFactory` del paquete TypeScript.
  """

  alias Cfdi.Xml.Concepto

  defstruct [:data]

  @type t :: %__MODULE__{data: map()}

  @spec new(map()) :: t()
  def new(data) when is_map(data), do: %__MODULE__{data: data}

  @spec build(t() | map()) :: Concepto.t()
  def build(%__MODULE__{data: data}), do: Concepto.new(data)
  def build(data) when is_map(data), do: Concepto.new(data)
end
