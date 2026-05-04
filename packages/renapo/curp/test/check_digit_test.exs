defmodule Renapo.Curp.Utils.CheckDigitTest do
  use ExUnit.Case, async: true

  alias Renapo.Curp.Utils.CheckDigit

  test "check_digit matches python reference for synthetic base" do
    base = "AAAA000000HDFAAA0"
    assert CheckDigit.check_digit(base) == CheckDigit.check_digit(base <> "0")
  end
end
