defmodule Cfdi.Cleaner do
  @moduledoc """
  Sanitiza XML de CFDI aplicando limpiadores orientados al SAT: addendas,
  espacios de nombres ajenos, nodos externos y metadatos de esquema no SAT.
  """

  alias Cfdi.Cleaner.Cleaners.{
    CollapseWhitespace,
    RemoveAddenda,
    RemoveNonSatNamespaces,
    RemoveNonSatNodes,
    RemoveNonSatSchemaLocations,
    RemoveStylesheetAttributes
  }

  @doc """
  Aplica todos los limpiadores en secuencia y devuelve el XML resultante.
  """
  @spec clean(String.t()) :: {:ok, String.t()} | {:error, term()}
  def clean(xml_string) when is_binary(xml_string) do
    {:ok,
     xml_string
     |> RemoveStylesheetAttributes.clean()
     |> RemoveAddenda.clean()
     |> RemoveNonSatSchemaLocations.clean()
     |> RemoveNonSatNamespaces.clean()
     |> RemoveNonSatNodes.clean()
     |> CollapseWhitespace.clean()}
  end

  @doc """
  Lee `path`, aplica `clean/1` y devuelve el XML limpio.
  """
  @spec clean_file(String.t()) :: {:ok, String.t()} | {:error, term()}
  def clean_file(path) do
    case File.read(path) do
      {:ok, bin} -> clean(bin)
      {:error, _} = e -> e
    end
  end
end
