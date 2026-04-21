defmodule Cfdi.Catalogos.Exportacion do
  @moduledoc """
  Catálogo de exportación del SAT.
  """

  @type t :: :no_aplica | :definitiva | :temporal

  @values %{
    no_aplica: "01",
    definitiva: "02",
    temporal: "03"
  }

  @spec value(t()) :: String.t()
  def value(key), do: Map.fetch!(@values, key)

  @spec list() :: [%{descripcion: String.t(), value: String.t()}]
  def list do
    [
      %{descripcion: "No aplica", value: "01"},
      %{descripcion: "Definitiva", value: "02"},
      %{descripcion: "Temporal", value: "03"}
    ]
  end

  @spec valid?(String.t()) :: boolean()
  def valid?(code), do: code in Map.values(@values)
end
