defmodule Sat.Captcha.Solvers.Manual do
  @moduledoc """
  Manual captcha solver that delegates to a user-provided callback.
  """

  @behaviour Sat.Captcha.Solver

  alias Sat.Captcha.Types.{Challenge, Result}

  @impl true
  def solve(%Challenge{} = _challenge) do
    {:error, "ManualCaptchaSolver requires a prompt_fn - use solve/2 instead"}
  end

  @spec solve(Challenge.t(), (Challenge.t() -> String.t())) :: {:ok, Result.t()} | {:error, String.t()}
  def solve(%Challenge{} = challenge, prompt_fn) when is_function(prompt_fn, 1) do
    case prompt_fn.(challenge) do
      text when is_binary(text) and text != "" ->
        {:ok, %Result{text: text}}

      _ ->
        {:error, "No se proporcionó respuesta al captcha"}
    end
  end
end
