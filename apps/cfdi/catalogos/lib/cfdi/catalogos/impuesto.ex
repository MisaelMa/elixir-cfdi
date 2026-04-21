defmodule Cfdi.Catalogos.Impuesto do
  @moduledoc """
  Catálogo de impuestos del SAT (c_Impuesto).
  """

  @type t :: :isr | :iva | :ieps

  @values %{
    isr: "001",
    iva: "002",
    ieps: "003"
  }

  @spec value(t()) :: String.t()
  def value(key), do: Map.fetch!(@values, key)

  @spec list() :: [%{label: String.t(), value: String.t()}]
  def list do
    [
      %{label: "ISR", value: "001"},
      %{label: "IVA", value: "002"},
      %{label: "IEPS", value: "003"}
    ]
  end

  @spec valid?(String.t()) :: boolean()
  def valid?(code), do: code in Map.values(@values)

  @spec from_code(String.t()) :: {:ok, t()} | :error
  def from_code("001"), do: {:ok, :isr}
  def from_code("002"), do: {:ok, :iva}
  def from_code("003"), do: {:ok, :ieps}
  def from_code(_), do: :error
end
