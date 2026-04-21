defmodule Cfdi.Catalogos.MetodoPago do
  @moduledoc """
  Catálogo de métodos de pago del SAT (c_MetodoPago).
  """

  @type t :: :pago_en_una_exhibicion | :pago_en_parcialidades_diferido

  @values %{
    pago_en_una_exhibicion: "PUE",
    pago_en_parcialidades_diferido: "PPD"
  }

  @spec value(t()) :: String.t()
  def value(key), do: Map.fetch!(@values, key)

  @spec list() :: [%{label: String.t(), value: String.t()}]
  def list do
    [
      %{label: "Pago en una sola exhibición", value: "PUE"},
      %{label: "Pago en parcialidades o diferido", value: "PPD"}
    ]
  end

  @spec valid?(String.t()) :: boolean()
  def valid?(code), do: code in Map.values(@values)

  @spec from_code(String.t()) :: {:ok, t()} | :error
  def from_code("PUE"), do: {:ok, :pago_en_una_exhibicion}
  def from_code("PPD"), do: {:ok, :pago_en_parcialidades_diferido}
  def from_code(_), do: :error
end
