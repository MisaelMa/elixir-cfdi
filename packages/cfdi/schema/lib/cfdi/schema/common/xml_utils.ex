defmodule Cfdi.Schema.Common.XmlUtils do
  @moduledoc false

  @spec escape(String.t()) :: String.t()
  def escape(nil), do: ""

  def escape(str) when is_binary(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
