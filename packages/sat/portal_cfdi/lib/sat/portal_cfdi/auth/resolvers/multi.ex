defmodule Sat.PortalCfdi.Auth.Resolvers.Multi do
  @moduledoc """
  Encadena varios resolvers; intenta uno por uno hasta que alguno retorne
  `{:ok, _}`. Si todos fallan, devuelve la lista de errores.

  Equivalente a `phpcfdi/image-captcha-resolver`'s `MultiResolver`.

  ## Uso

      captcha_resolver:
        {Multi,
         resolvers: [
           {BoxFacturaOnnx, model_path: "/models/sat.onnx"},
           {AntiCaptcha, api_key: "..."},
           Console
         ]}
  """

  @behaviour Sat.PortalCfdi.Auth.CaptchaResolver

  alias Sat.PortalCfdi.Auth.CaptchaResolver

  @impl true
  def resolve(image) when is_binary(image), do: {:error, :no_resolvers_configured}

  @impl true
  def resolve(image, opts) when is_binary(image) and is_list(opts) do
    resolvers = Keyword.get(opts, :resolvers, [])
    try_each(image, resolvers, [])
  end

  defp try_each(_image, [], errors), do: {:error, {:multi_failed, Enum.reverse(errors)}}

  defp try_each(image, [resolver | rest], errors) do
    case CaptchaResolver.dispatch(image, resolver) do
      {:ok, answer} -> {:ok, answer}
      {:error, reason} -> try_each(image, rest, [{resolver, reason} | errors])
    end
  end
end
