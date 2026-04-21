defmodule Cfdi.Validador.Parser do
  @moduledoc false

  alias Cfdi.Validador.Types.CfdiData

  @doc """
  Parsea XML CFDI a `CfdiData` usando Saxy (forma simple).
  """
  @spec parse(String.t()) :: {:ok, CfdiData.t()} | {:error, term()}
  def parse(xml_string) when is_binary(xml_string) do
    case Saxy.SimpleForm.parse_string(xml_string) do
      {:ok, form} -> {:ok, %CfdiData{document: normalize(form)}}
      {:error, _} = e -> e
    end
  end

  defp normalize({name, attrs, children}) do
    {to_string(name), attrs || [], Enum.map(children || [], &normalize_child/1)}
  end

  defp normalize_child({n, a, c}), do: {:element, to_string(n), a || [], Enum.map(c || [], &normalize_child/1)}
  defp normalize_child(text) when is_binary(text), do: {:text, text}
  defp normalize_child(other), do: {:text, to_string(other)}
end
