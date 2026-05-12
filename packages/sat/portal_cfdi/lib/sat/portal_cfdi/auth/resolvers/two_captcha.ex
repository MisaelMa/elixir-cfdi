defmodule Sat.PortalCfdi.Auth.Resolvers.TwoCaptcha do
  @moduledoc """
  Resolver via servicio https://2captcha.com.

  Flujo (segun la API oficial):
    1. POST `in.php` con `method=base64`, `body=<image_b64>`, `key=<api_key>`
       → retorna `OK|<captcha_id>`
    2. GET `res.php?key=<api_key>&action=get&id=<captcha_id>` cada N seg
       → cuando responda `OK|<text>`, retorna el texto.

  ## Opciones

    * `:api_key` (requerido)
    * `:base_url` — default `"https://2captcha.com"`
    * `:initial_wait_seconds` — default 10
    * `:timeout_seconds` — default 120
    * `:retry_interval_ms` — default 5000
  """

  @behaviour Sat.PortalCfdi.Auth.CaptchaResolver

  @default_base_url "https://2captcha.com"
  @default_initial_wait 10
  @default_timeout 120
  @default_retry_interval 5000

  @impl true
  def resolve(image) when is_binary(image), do: {:error, :api_key_required}

  @impl true
  def resolve(image, opts) when is_binary(image) and is_list(opts) do
    with {:ok, key} <- Keyword.fetch(opts, :api_key) |> normalize_key(),
         {:ok, captcha_id} <- submit(image, key, opts),
         _ = sleep_seconds(Keyword.get(opts, :initial_wait_seconds, @default_initial_wait)),
         {:ok, answer} <- poll_result(captcha_id, key, opts) do
      {:ok, answer}
    end
  end

  defp normalize_key({:ok, key}) when is_binary(key) and key != "", do: {:ok, key}
  defp normalize_key(_), do: {:error, :api_key_required}

  defp submit(image, key, opts) do
    base = Keyword.get(opts, :base_url, @default_base_url)

    form =
      URI.encode_query(%{
        "key" => key,
        "method" => "base64",
        "body" => Base.encode64(image),
        "json" => "1"
      })

    case Req.post(base <> "/in.php",
           body: form,
           headers: [{"content-type", "application/x-www-form-urlencoded"}],
           retry: false
         ) do
      {:ok, %Req.Response{status: 200, body: %{"status" => 1, "request" => id}}} ->
        {:ok, id}

      {:ok, %Req.Response{status: 200, body: %{"status" => 0, "request" => err}}} ->
        {:error, {:two_captcha, err}}

      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        # Modo no-json
        case String.split(body, "|", parts: 2) do
          ["OK", id] -> {:ok, id}
          ["ERROR_" <> _ = err | _] -> {:error, {:two_captcha, err}}
          _ -> {:error, {:two_captcha, body}}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  defp poll_result(captcha_id, key, opts) do
    base = Keyword.get(opts, :base_url, @default_base_url)
    timeout = Keyword.get(opts, :timeout_seconds, @default_timeout)
    interval = Keyword.get(opts, :retry_interval_ms, @default_retry_interval)
    deadline = System.system_time(:millisecond) + timeout * 1000

    poll(base, key, captcha_id, interval, deadline)
  end

  defp poll(base, key, captcha_id, interval, deadline) do
    url =
      base <>
        "/res.php?" <>
        URI.encode_query(%{
          "key" => key,
          "action" => "get",
          "id" => captcha_id,
          "json" => "1"
        })

    case Req.get(url, retry: false) do
      {:ok, %Req.Response{status: 200, body: %{"status" => 1, "request" => text}}} ->
        {:ok, text}

      {:ok, %Req.Response{status: 200, body: %{"status" => 0, "request" => "CAPCHA_NOT_READY"}}} ->
        if System.system_time(:millisecond) < deadline do
          Process.sleep(interval)
          poll(base, key, captcha_id, interval, deadline)
        else
          {:error, :timeout}
        end

      {:ok, %Req.Response{status: 200, body: %{"status" => 0, "request" => err}}} ->
        {:error, {:two_captcha, err}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  defp sleep_seconds(0), do: :ok
  defp sleep_seconds(n) when is_integer(n) and n > 0, do: Process.sleep(n * 1000)
  defp sleep_seconds(_), do: :ok
end
