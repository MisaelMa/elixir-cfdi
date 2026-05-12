defmodule Sat.PortalCfdi.Auth.Resolvers.Mock do
  @moduledoc """
  Resolver para tests unitarios. Devuelve una respuesta predefinida o lanza
  un error configurado.

  Equivalente a `phpcfdi/image-captcha-resolver`'s `MockResolver`.

  ## Uso

      # respuesta fija
      captcha_resolver: {Mock, answer: "ABC123"}

      # error
      captcha_resolver: {Mock, error: :timeout}

      # cola de respuestas (para reintentos)
      captcha_resolver: {Mock, queue: ["WRONG", "WRONG", "RIGHT"]}
  """

  @behaviour Sat.PortalCfdi.Auth.CaptchaResolver

  @impl true
  def resolve(image) when is_binary(image) do
    resolve(image, answer: "MOCK_DEFAULT")
  end

  @impl true
  def resolve(_image, opts) when is_list(opts) do
    cond do
      err = Keyword.get(opts, :error) ->
        {:error, err}

      queue = Keyword.get(opts, :queue) ->
        case queue do
          [head | _] -> {:ok, head}
          _ -> {:error, :empty_queue}
        end

      ans = Keyword.get(opts, :answer) ->
        {:ok, ans}

      true ->
        {:ok, "MOCK_DEFAULT"}
    end
  end
end
