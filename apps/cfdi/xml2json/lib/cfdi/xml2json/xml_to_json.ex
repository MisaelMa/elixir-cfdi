defmodule Cfdi.Xml2Json.XmlToJson do
  @moduledoc false

  @doc """
  Detecta si el argumento es ruta a archivo o XML en cadena y delega en
  `parse_file/1` o `parse_string/1`.
  """
  @spec parse(String.t()) :: {:ok, map()} | {:error, term()}
  def parse(path_or_xml) do
    if String.contains?(path_or_xml, "<") do
      parse_string(path_or_xml)
    else
      parse_file(path_or_xml)
    end
  end

  @doc """
  Parsea XML y devuelve un mapa con `name`, `attributes` y `children`.
  """
  @spec parse_string(String.t()) :: {:ok, map()} | {:error, term()}
  def parse_string(xml_string) when is_binary(xml_string) do
    case Saxy.SimpleForm.parse_string(xml_string) do
      {:ok, form} -> {:ok, node_to_map(form)}
      {:error, _} = e -> e
    end
  end

  @doc """
  Lee el archivo y aplica `parse_string/1`.
  """
  @spec parse_file(String.t()) :: {:ok, map()} | {:error, term()}
  def parse_file(path) do
    case File.read(path) do
      {:ok, bin} -> parse_string(bin)
      {:error, _} = e -> e
    end
  end

  defp node_to_map({name, attrs, children}) do
    %{
      "name" => to_string(name),
      "attributes" => attrs_to_map(attrs || []),
      "children" =>
        children
        |> List.wrap()
        |> Enum.map(fn
          {_, _, _} = el -> node_to_map(el)
          text when is_binary(text) -> %{"text" => text}
        end)
    }
  end

  defp attrs_to_map(attrs) do
    Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
  end
end
