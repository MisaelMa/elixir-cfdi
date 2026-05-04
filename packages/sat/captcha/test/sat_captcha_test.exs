defmodule Sat.CaptchaTest do
  use ExUnit.Case, async: true

  alias Sat.Captcha.Types.{Challenge, Result}
  alias Sat.Captcha.Solvers.Manual

  test "Manual solver with prompt_fn" do
    challenge = %Challenge{image_base64: "test"}
    {:ok, result} = Manual.solve(challenge, fn _c -> "abc123" end)
    assert result.text == "abc123"
  end

  test "Manual solver with empty response" do
    challenge = %Challenge{image_base64: "test"}
    {:error, _} = Manual.solve(challenge, fn _c -> "" end)
  end
end
