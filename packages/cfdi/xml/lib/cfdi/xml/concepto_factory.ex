defmodule Cfdi.Xml.ConceptoFactory do
  @moduledoc """
  Factory para construir un `Cfdi.Xml.Concepto` desde un mapa de
  atributos. Espejo de `ConceptFactory` del paquete TypeScript.
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
