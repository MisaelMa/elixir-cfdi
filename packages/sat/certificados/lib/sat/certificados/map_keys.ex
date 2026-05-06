defmodule Sat.Certificados.MapKeys do
  @moduledoc false

  # Helper interno: transforma recursivamente las llaves de un mapa al tipo
  # elegido (`:atom`, `:string`, `:existing`).
  #
  # Comparte la semántica con `CFDI.to_map/2` para mantener coherencia entre
  # paquetes.
  #
  #   * `:atom`     — `String.to_atom/1`. Peligroso con keys arbitrarias
  #                   (la atom table no tiene GC).
  #   * `:string`   — siempre string.
  #   * `:existing` — `String.to_existing_atom/1`; fallback a string si el
  #                   átomo no existe en la VM. Seguro.

  @spec transform(map() | list() | term(), :atom | :string | :existing) :: term()
  def transform(value, mode), do: do_transform(value, key_fn(mode))

  defp do_transform(map, fun) when is_map(map) and not is_struct(map) do
    Map.new(map, fn {k, v} -> {fun.(k), do_transform(v, fun)} end)
  end

  defp do_transform(list, fun) when is_list(list), do: Enum.map(list, &do_transform(&1, fun))
  defp do_transform(other, _fun), do: other

  defp key_fn(:atom), do: &atomize/1
  defp key_fn(:string), do: &stringify/1
  defp key_fn(:existing), do: &existing_atom/1

  defp key_fn(other),
    do:
      raise(
        ArgumentError,
        "opción :keys inválida: #{inspect(other)}; usar :atom, :string o :existing"
      )

  defp atomize(k) when is_atom(k), do: k
  defp atomize(k) when is_binary(k), do: String.to_atom(k)

  defp stringify(k) when is_atom(k), do: Atom.to_string(k)
  defp stringify(k) when is_binary(k), do: k

  defp existing_atom(k) when is_atom(k), do: k

  defp existing_atom(k) when is_binary(k) do
    String.to_existing_atom(k)
  rescue
    ArgumentError -> k
  end
end
