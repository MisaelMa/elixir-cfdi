defmodule Cfdi.Xml.Utils do
  @moduledoc """
  Helpers puntuales para la construcción de XML CFDI.

  Mirror de `packages/cfdi/xml/src/utils/*` en el ecosistema Node.
  """

  @doc """
  Ordena un mapa dado un listado de llaves. Las llaves no listadas preservan
  su orden relativo al final.
  """
  @spec sort_object(map(), [atom() | String.t()]) :: [{atom() | String.t(), any()}]
  def sort_object(map, order) when is_map(map) and is_list(order) do
    ordered =
      Enum.reduce(order, [], fn key, acc ->
        case Map.fetch(map, key) do
          {:ok, v} -> [{key, v} | acc]
          :error -> acc
        end
      end)
      |> Enum.reverse()

    rest =
      map
      |> Enum.reject(fn {k, _} -> k in order end)

    ordered ++ rest
  end

  @doc """
  Une un listado de URIs en el formato requerido por `xsi:schemaLocation`
  (separados por espacio).
  """
  @spec schema_build([String.t()]) :: String.t()
  def schema_build(locations) when is_list(locations) do
    locations
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.join(" ")
  end
end
