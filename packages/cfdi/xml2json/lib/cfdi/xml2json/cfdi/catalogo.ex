defmodule Cfdi.Xml2Json.Cfdi.Catalogo do
  @moduledoc """
  Wrapper minimal para valores de catálogo SAT, espejo de la clase
  `Catalogo<T>` del paquete TypeScript.
  """

  defstruct value: nil, label: ""

  @type t :: %__MODULE__{value: any(), label: String.t()}

  @spec new(any()) :: t()
  def new(value), do: %__MODULE__{value: value, label: ""}

  @spec label(t()) :: String.t()
  def label(%__MODULE__{label: label}), do: label

  @spec value(t()) :: any()
  def value(%__MODULE__{value: value}), do: value
end
