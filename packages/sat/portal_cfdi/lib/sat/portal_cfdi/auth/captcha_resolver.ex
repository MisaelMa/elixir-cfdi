defmodule Sat.PortalCfdi.Auth.CaptchaResolver do
  @moduledoc """
  Behaviour para resolvers de captcha del portal SAT.

  Equivalente Elixir de `phpcfdi/image-captcha-resolver`. Cualquier modulo
  que implemente este behaviour se puede pasar a `Sat.PortalCfdi.Auth.Ciec.login/2`
  como `:captcha_resolver`.

  ## Resolvers incluidos

  | Modulo | Para que sirve | Requiere |
  |---|---|---|
  | `Resolvers.Console` | Pruebas manuales (lee stdin) | nada |
  | `Resolvers.Mock` | Tests unitarios | respuestas predefinidas |
  | `Resolvers.Multi` | Encadena varios resolvers con fallback | lista de resolvers |
  | `Resolvers.AntiCaptcha` | Servicio anti-captcha.com | API key |
  | `Resolvers.TwoCaptcha` | Servicio 2captcha.com | API key |
  | `Resolvers.CommandLine` | Shell out (Tesseract, etc.) | comando del SO |
  | `Resolvers.BoxFacturaOnnx` | Modelo ONNX entrenado para SAT | dep `:ortex` opcional |

  ## Como pasar el resolver a Ciec.login/2

  El parametro `:captcha_resolver` acepta tres formas:

      # 1. Funcion (lo mas simple)
      captcha_resolver: fn image -> {:ok, "ABC123"} end

      # 2. Modulo (usa configuracion default)
      captcha_resolver: Sat.PortalCfdi.Auth.Resolvers.Console

      # 3. {Modulo, opts} (modulo configurado)
      captcha_resolver: {Sat.PortalCfdi.Auth.Resolvers.AntiCaptcha, api_key: "..."}
  """

  @type image :: binary()
  @type answer :: String.t()
  @type error :: {:error, term()}
  @type result :: {:ok, answer()} | error()

  @doc """
  Resuelve un captcha. Recibe los bytes crudos de la imagen (PNG/JPEG) y
  retorna el texto detectado.
  """
  @callback resolve(image()) :: result()

  @doc """
  Variante con opciones (la usa el dispatcher cuando el llamador pasa
  `{Modulo, opts}`). Implementacion por default delega a `resolve/1`.
  """
  @callback resolve(image(), keyword()) :: result()

  @optional_callbacks resolve: 2

  @doc """
  Despacha la resolucion del captcha a la forma correcta segun el tipo
  de resolver pasado por el usuario.
  """
  @spec dispatch(image(), term()) :: result()
  def dispatch(image, resolver) when is_binary(image) do
    cond do
      is_function(resolver, 1) ->
        resolver.(image)

      is_atom(resolver) and module_exports?(resolver, :resolve, 1) ->
        resolver.resolve(image)

      match?({mod, opts} when is_atom(mod) and is_list(opts), resolver) ->
        {mod, opts} = resolver
        cond do
          module_exports?(mod, :resolve, 2) -> mod.resolve(image, opts)
          module_exports?(mod, :resolve, 1) -> mod.resolve(image)
          true -> {:error, {:invalid_resolver, mod, "no exporta resolve/1 ni resolve/2"}}
        end

      true ->
        {:error, {:invalid_resolver, resolver, "esperado: funcion/1, modulo, o {modulo, opts}"}}
    end
  end

  defp module_exports?(mod, fun, arity) when is_atom(mod) do
    Code.ensure_loaded?(mod) and function_exported?(mod, fun, arity)
  end
end
