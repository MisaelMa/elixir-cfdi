defmodule Cfdi.Catalogos.Codegen.Overrides do
  @moduledoc """
  Cargador de archivos de overrides para cfdi_catalogos_codegen.

  Los archivos de override son `.exs` que evalúan a un mapa con la forma:
      %{
        enum_names: %{code => atom},
        descriptions: %{code => string}
      }

  Si el archivo no existe, se retorna el mapa vacío por defecto.
  """

  @empty %{enum_names: %{}, descriptions: %{}}

  @doc """
  Carga un archivo de override desde la ruta dada.

  - Si el archivo no existe: `{:ok, %{enum_names: %{}, descriptions: %{}}}`
  - Si el archivo es válido: `{:ok, map_with_both_keys}`
  - Si el archivo evalúa a no-mapa: `{:error, reason}`
  - Si el archivo lanza durante eval: `{:error, reason}`
  """
  @spec load(Path.t()) ::
          {:ok, %{enum_names: %{String.t() => atom()}, descriptions: %{String.t() => String.t()}}}
          | {:error, term()}
  def load(path) when is_binary(path) do
    if File.exists?(path) do
      eval_override(path)
    else
      {:ok, @empty}
    end
  end

  defp eval_override(path) do
    try do
      {result, _bindings} = Code.eval_file(path)
      validate_override(result)
    rescue
      e -> {:error, {:eval_error, Exception.message(e)}}
    catch
      kind, reason -> {:error, {:eval_error, {kind, reason}}}
    end
  end

  defp validate_override(result) when is_map(result) do
    enum_names = Map.get(result, :enum_names, %{})
    descriptions = Map.get(result, :descriptions, %{})

    {:ok, %{enum_names: enum_names, descriptions: descriptions}}
  end

  defp validate_override(result) do
    {:error, {:invalid_override, "expected a map, got: #{inspect(result)}"}}
  end
end
