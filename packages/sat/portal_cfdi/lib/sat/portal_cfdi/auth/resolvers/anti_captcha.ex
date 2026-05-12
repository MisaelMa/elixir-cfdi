defmodule Sat.PortalCfdi.Auth.Resolvers.AntiCaptcha do
  @moduledoc """
  Resolver via servicio https://anti-captcha.com.

  Flujo (segun la API oficial):
    1. POST `/createTask` con la imagen base64 → retorna `taskId`
    2. POST `/getTaskResult` cada N segundos hasta que el status sea
       `ready` (max `timeout`s) → retorna `solution.text`

  ## Opciones

    * `:api_key` (requerido) — `clientKey` de anti-captcha
    * `:base_url` — default `"https://api.anti-captcha.com"`
    * `:initial_wait_seconds` — espera antes del primer poll (default 5s)
    * `:timeout_seconds` — tiempo maximo total (default 60s)
    * `:retry_interval_ms` — entre polls (default 500ms)
    * `:case_sensitive` — `true`/`false` (default `false`)
  """

  @behaviour Sat.PortalCfdi.Auth.CaptchaResolver

  @default_base_url "https://api.anti-captcha.com"
  @default_initial_wait 5
  @default_timeout 60
  @default_retry_interval 500

  @impl true
  def resolve(image) when is_binary(image), do: {:error, :api_key_required}

  @impl true
  def resolve(image, opts) when is_binary(image) and is_list(opts) do
    with {:ok, key} <- Keyword.fetch(opts, :api_key) |> normalize_key(),
         {:ok, task_id} <- create_task(image, key, opts),
         _ = sleep_seconds(Keyword.get(opts, :initial_wait_seconds, @default_initial_wait)),
         {:ok, answer} <- poll_result(task_id, key, opts) do
      {:ok, answer}
    end
  end

  defp normalize_key({:ok, key}) when is_binary(key) and key != "", do: {:ok, key}
  defp normalize_key(_), do: {:error, :api_key_required}

  defp create_task(image, key, opts) do
    base = Keyword.get(opts, :base_url, @default_base_url)
    body = %{
      "clientKey" => key,
      "task" => %{
        "type" => "ImageToTextTask",
        "body" => Base.encode64(image),
        "case" => Keyword.get(opts, :case_sensitive, false)
      }
    }

    case Req.post(base <> "/createTask", json: body, retry: false) do
      {:ok, %Req.Response{status: 200, body: %{"errorId" => 0, "taskId" => task_id}}} ->
        {:ok, task_id}

      {:ok, %Req.Response{body: %{"errorCode" => code, "errorDescription" => desc}}} ->
        {:error, {:anti_captcha, code, desc}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  defp poll_result(task_id, key, opts) do
    base = Keyword.get(opts, :base_url, @default_base_url)
    timeout = Keyword.get(opts, :timeout_seconds, @default_timeout)
    interval = Keyword.get(opts, :retry_interval_ms, @default_retry_interval)
    deadline = System.system_time(:millisecond) + timeout * 1000

    body = %{"clientKey" => key, "taskId" => task_id}
    poll(base, body, interval, deadline)
  end

  defp poll(base, body, interval, deadline) do
    case Req.post(base <> "/getTaskResult", json: body, retry: false) do
      {:ok, %Req.Response{status: 200, body: %{"status" => "ready", "solution" => %{"text" => text}}}} ->
        {:ok, text}

      {:ok, %Req.Response{status: 200, body: %{"status" => "processing"}}} ->
        if System.system_time(:millisecond) < deadline do
          Process.sleep(interval)
          poll(base, body, interval, deadline)
        else
          {:error, :timeout}
        end

      {:ok, %Req.Response{body: %{"errorCode" => code, "errorDescription" => desc}}} ->
        {:error, {:anti_captcha, code, desc}}

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
