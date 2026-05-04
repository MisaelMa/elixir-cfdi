defmodule Sat.Captcha.Solver do
  @moduledoc """
  Behaviour that any captcha solver must implement.
  """

  alias Sat.Captcha.Types.{Challenge, Result}

  @callback solve(Challenge.t()) :: {:ok, Result.t()} | {:error, String.t()}
  @callback report(String.t(), boolean()) :: :ok | {:error, String.t()}

  @optional_callbacks [report: 2]
end
