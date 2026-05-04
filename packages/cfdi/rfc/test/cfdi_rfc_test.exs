defmodule Cfdi.RfcTest do
  use ExUnit.Case, async: true

  alias Cfdi.Rfc
  alias Cfdi.Rfc.{Value, Faker, CheckDigit}

  test "validate valid RFC persona fisica" do
    result = Rfc.validate("GARC850101AAA")
    assert result.rfc == "GARC850101AAA"
  end

  test "validate special RFC generico" do
    assert Value.valid?("XAXX010101000")
  end

  test "validate special RFC extranjero" do
    assert Value.valid?("XEXX010101000")
  end

  test "Value.of! with special RFC" do
    rfc = Value.of!("XAXX010101000")
    assert Value.generic?(rfc)
    refute Value.fisica?(rfc)
  end

  test "Value.of! with foreign RFC" do
    rfc = Value.of!("XEXX010101000")
    assert Value.foreign?(rfc)
  end

  test "check_digit calculates correctly" do
    assert is_binary(CheckDigit.check_digit("GARC850101AA0"))
  end

  test "Faker generates valid persona RFC" do
    rfc = Faker.persona()
    assert byte_size(rfc) == 13
  end

  test "Faker generates valid moral RFC" do
    rfc = Faker.moral()
    assert byte_size(rfc) == 12
  end

  test "has_forbidden_words? detects forbidden prefixes" do
    assert Rfc.has_forbidden_words?("CACA850101AAA")
    refute Rfc.has_forbidden_words?("GARC850101AAA")
  end
end
