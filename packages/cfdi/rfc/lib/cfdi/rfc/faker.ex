defmodule Cfdi.Rfc.Faker do
  @moduledoc """
  Generates random valid RFC strings for testing.
  """

  alias Cfdi.Rfc.{CheckDigit, Constants}

  @vowels ~c"AEIOU"
  @letters ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @homoclave_chars ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

  @spec persona() :: String.t()
  def persona do
    prefix = persona_fisica_prefix()
    date = random_date_str()
    homo2 = random_homoclave2()
    base = prefix <> date <> homo2
    digit = CheckDigit.check_digit(base <> "0")
    base <> digit
  end

  @spec moral() :: String.t()
  def moral do
    prefix = persona_moral_prefix()
    date = random_date_str()
    homo2 = random_homoclave2()
    base = prefix <> date <> homo2
    digit = CheckDigit.check_digit(base <> "0")
    base <> digit
  end

  defp persona_fisica_prefix do
    prefix =
      <<pick(@letters), pick(@vowels), pick(@letters), pick(@letters)>>

    if has_forbidden_prefix?(prefix),
      do: persona_fisica_prefix(),
      else: prefix
  end

  defp persona_moral_prefix do
    prefix = <<pick(@letters), pick(@letters), pick(@letters)>>

    if has_forbidden_prefix?(prefix <> "A"),
      do: persona_moral_prefix(),
      else: prefix
  end

  defp has_forbidden_prefix?(prefix) do
    p = prefix |> String.upcase() |> String.slice(0, 4)
    p in Constants.forbidden_words()
  end

  defp random_date_str do
    year = Enum.random(30..99)
    month = Enum.random(1..12)
    days_in_month = Date.days_in_month(Date.new!(1900 + year, month, 1))
    day = Enum.random(1..days_in_month)
    pad2(year) <> pad2(month) <> pad2(day)
  end

  defp random_homoclave2 do
    <<pick(@homoclave_chars), pick(@homoclave_chars)>>
  end

  defp pick(chars), do: Enum.random(chars)

  defp pad2(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")
end
