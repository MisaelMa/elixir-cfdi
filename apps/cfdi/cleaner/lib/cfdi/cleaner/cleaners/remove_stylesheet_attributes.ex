defmodule Cfdi.Cleaner.Cleaners.RemoveStylesheetAttributes do
  @moduledoc false

  @doc """
  Elimina instrucciones de procesamiento `xml-stylesheet`.
  """
  @spec clean(String.t()) :: String.t()
  def clean(xml) when is_binary(xml) do
    Regex.replace(~r/<\?xml-stylesheet[^?]*\?>\s*/i, xml, "")
  end
end
