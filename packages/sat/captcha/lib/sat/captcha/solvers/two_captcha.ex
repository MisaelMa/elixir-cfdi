defmodule Sat.Captcha.Solvers.TwoCaptcha do
  @moduledoc """
  Captcha solver using the 2captcha.com service.
  """

  @behaviour Sat.Captcha.Solver

  alias Sat.Captcha.Types.{Challenge, Result}

  @api_url "https://2captcha.com/in.php"
  @result_url "https://2captcha.com/res.php"
  @poll_interval_ms 5_000

  defstruct [:api_key, timeout: 120_000]

  @type t :: %__MODULE__{api_key: String.t(), timeout: non_neg_integer()}

  @impl true
  def solve(%Challenge{} = challenge) do
    solver = get_solver()
    with {:ok, task_id} <- submit_task(solver, challenge) do
      wait_for_result(solver, task_id)
    end
  end

  @impl true
  def report(task_id, correct) do
    solver = get_solver()
    action = if correct, do: "reportgood", else: "reportbad"
    Req.get("#{@result_url}?key=#{solver.api_key}&action=#{action}&id=#{task_id}")
    :ok
  end

  def new(api_key, timeout \\ 120_000) do
    %__MODULE__{api_key: api_key, timeout: timeout}
  end

  defp get_solver do
    %__MODULE__{api_key: "", timeout: 120_000}
  end

  defp submit_task(solver, challenge) do
    params = build_params(solver, challenge)

    case Req.post(@api_url,
           form: params,
           headers: [{"content-type", "application/x-www-form-urlencoded"}]
         ) do
      {:ok, %{status: 200, body: %{"status" => 1, "request" => request}}} ->
        {:ok, request}

      {:ok, %{body: %{"request" => error}}} ->
        {:error, "Error al enviar captcha a 2captcha: #{error}"}

      {:error, reason} ->
        {:error, "Error de red: #{inspect(reason)}"}
    end
  end

  defp build_params(solver, challenge) do
    base = %{"key" => solver.api_key, "json" => "1"}

    cond do
      challenge.site_key && challenge.page_url ->
        Map.merge(base, %{
          "method" => "userrecaptcha",
          "googlekey" => challenge.site_key,
          "pageurl" => challenge.page_url
        })

      challenge.image_base64 ->
        Map.merge(base, %{"method" => "base64", "body" => challenge.image_base64})

      challenge.image_url ->
        case Req.get(challenge.image_url) do
          {:ok, %{body: body}} ->
            Map.merge(base, %{"method" => "base64", "body" => Base.encode64(body)})

          _ ->
            base
        end

      true ->
        raise "Se requiere imageBase64, imageUrl, o siteKey+pageUrl para resolver el captcha"
    end
  end

  defp wait_for_result(solver, task_id, start_time \\ nil) do
    start = start_time || System.monotonic_time(:millisecond)
    elapsed = System.monotonic_time(:millisecond) - start

    if elapsed >= solver.timeout do
      {:error, "Timeout: 2captcha no resolvió el captcha en #{div(solver.timeout, 1000)} segundos"}
    else
      Process.sleep(@poll_interval_ms)

      case Req.get("#{@result_url}?key=#{solver.api_key}&action=get&id=#{task_id}&json=1") do
        {:ok, %{body: %{"status" => 1, "request" => text}}} ->
          {:ok, %Result{text: text, task_id: task_id}}

        {:ok, %{body: %{"request" => "CAPCHA_NOT_READY"}}} ->
          wait_for_result(solver, task_id, start)

        {:ok, %{body: %{"request" => error}}} ->
          {:error, "Error de 2captcha: #{error}"}

        {:error, reason} ->
          {:error, "Error de red: #{inspect(reason)}"}
      end
    end
  end
end
