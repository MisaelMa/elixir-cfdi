defmodule Cfdi.Catalogos.TipoComprobante do
  @moduledoc """
  Catálogo de tipos de comprobante del SAT (c_TipoDeComprobante).
  """

  @type t :: :ingreso | :egreso | :traslado | :pago | :nomina

  @values %{
    ingreso: "I",
    egreso: "E",
    traslado: "T",
    pago: "P",
    nomina: "N"
  }

  @spec value(t()) :: String.t()
  def value(key), do: Map.fetch!(@values, key)

  @spec list() :: [%{label: String.t(), value: String.t()}]
  def list do
    [
      %{label: "Ingreso", value: "I"},
      %{label: "Egreso", value: "E"},
      %{label: "Translado", value: "T"},
      %{label: "Nómina", value: "N"},
      %{label: "Pago", value: "P"}
    ]
  end

  @spec valid?(String.t()) :: boolean()
  def valid?(code), do: code in Map.values(@values)

  @spec from_code(String.t()) :: {:ok, t()} | :error
  def from_code("I"), do: {:ok, :ingreso}
  def from_code("E"), do: {:ok, :egreso}
  def from_code("T"), do: {:ok, :traslado}
  def from_code("P"), do: {:ok, :pago}
  def from_code("N"), do: {:ok, :nomina}
  def from_code(_), do: :error
end
