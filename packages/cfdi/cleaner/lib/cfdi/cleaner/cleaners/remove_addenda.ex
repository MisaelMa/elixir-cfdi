defmodule Cfdi.Cleaner.Cleaners.RemoveAddenda do
  @moduledoc false

  @doc """
  Elimina el nodo `cfdi:Addenda` y su contenido.
  """
  @spec clean(String.t()) :: String.t()
  def clean(xml) when is_binary(xml) do
    Regex.replace(
      ~r/<cfdi:Addenda\b[^>]*>[\s\S]*?<\/cfdi:Addenda>/i,
      xml,
      ""
    )
  end
end
