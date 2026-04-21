defmodule Cfdi.Cleaner.Cleaners.CollapseWhitespace do
  @moduledoc false

  @doc """
  Compacta espacios en blanco entre etiquetas y normaliza saltos de línea.
  """
  @spec clean(String.t()) :: String.t()
  def clean(xml) when is_binary(xml) do
    xml
    |> String.replace(~r/>\s+</, "><")
    |> String.trim()
  end
end
