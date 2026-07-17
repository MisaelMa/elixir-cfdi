defmodule Cfdi.Complementos.Registry do
  @moduledoc """
  Índice inverso de los complementos: dado lo que aparece en un XML,
  resuelve el módulo que lo maneja.

  Es la pieza que permite decodificar (`CFDI.from_xml/2`): al serializar,
  cada complemento sabe su propia `key`; al deserializar hace falta el
  camino contrario, `"http://www.sat.gob.mx/Pagos20"` →
  `Cfdi.Complementos.Pago20`.

  ## Descubrimiento

  Los módulos NO se listan a mano: se descubren en runtime recorriendo los
  módulos de la aplicación `:cfdi_complementos` y quedándose con los que
  exponen `__complemento__/0` (marca que agrega
  `use Cfdi.Complementos.Complemento`). Agregar un complemento nuevo lo
  registra solo — no hay lista que se desincronice.

  El índice se construye una vez y se cachea en `:persistent_term`.

  ## Resolver por namespace, no por prefijo

  `by_xmlns/1` es la vía correcta al decodificar XML: la URI del namespace
  es el identificador autoritativo. El prefijo es convención y un emisor
  puede usar el que quiera. Ver `Cfdi.Complementos.Complemento`.
  """

  @app :cfdi_complementos

  @doc """
  Todos los módulos de complemento conocidos.
  """
  @spec all() :: [module()]
  def all(), do: table().modules

  @doc """
  Resuelve el módulo por la URI de su namespace. Vía preferida al decodificar.

      iex> Cfdi.Complementos.Registry.by_xmlns("http://www.sat.gob.mx/Pagos20")
      Cfdi.Complementos.Pago20
  """
  @spec by_xmlns(String.t()) :: module() | nil
  def by_xmlns(uri) when is_binary(uri), do: Map.get(table().by_xmlns, uri)

  @doc """
  Resuelve el módulo por su key canónica (con prefijo del SAT).

  Sólo sirve cuando la key ya viene en la convención oficial; para XML de
  terceros usar `by_xmlns/1`.
  """
  @spec by_key(String.t()) :: module() | nil
  def by_key(key) when is_binary(key), do: Map.get(table().by_key, key)

  @doc """
  Descarta el índice cacheado. Útil tras recompilar en desarrollo.
  """
  @spec refresh() :: :ok
  def refresh() do
    :persistent_term.erase(__MODULE__)
    :ok
  end

  defp table() do
    case :persistent_term.get(__MODULE__, nil) do
      nil ->
        built = build()
        :persistent_term.put(__MODULE__, built)
        built

      cached ->
        cached
    end
  end

  defp build() do
    modules = discover()

    %{
      modules: modules,
      by_xmlns: index_by(modules, :xmlns),
      by_key: index_by(modules, :key)
    }
  end

  defp discover() do
    _ = Application.load(@app)

    case :application.get_key(@app, :modules) do
      {:ok, modules} -> Enum.filter(modules, &complemento?/1)
      _ -> []
    end
  end

  defp complemento?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__complemento__, 0)
  end

  # Un choque de xmlns o key entre dos complementos es un bug de programación
  # (dos módulos peleando por el mismo elemento del SAT): reventamos fuerte en
  # vez de dejar que uno pise al otro silenciosamente.
  defp index_by(modules, fun) do
    modules
    |> Enum.group_by(&apply(&1, fun, []))
    |> Map.new(fn
      {value, [module]} ->
        {value, module}

      {value, colliding} ->
        raise ArgumentError,
              "complementos con #{fun} duplicado #{inspect(value)}: #{inspect(colliding)}"
    end)
  end
end
