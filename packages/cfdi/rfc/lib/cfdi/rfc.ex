defmodule Cfdi.Rfc do
  @moduledoc """
  Validación de RFC del SAT.
  """

  alias Cfdi.Rfc.{Constants, CheckDigit}

  @spec get_type(String.t()) :: String.t() | nil
  def get_type(rfc) do
    case Map.get(Constants.special_cases(), rfc) do
      nil -> Map.get(Constants.rfc_type_for_length(), byte_size(rfc))
      type -> type
    end
  end

  @spec has_forbidden_words?(String.t()) :: boolean()
  def has_forbidden_words?(rfc) do
    prefix = String.slice(rfc || "", 0, 4)
    prefix in Constants.forbidden_words()
  end

  @spec validate(String.t()) :: %{is_valid: boolean(), type: String.t(), rfc: String.t()}
  def validate(input) do
    cleaned = parse_input(input)

    result = %{is_valid: false, type: "", rfc: cleaned}

    has_valid_format = Regex.match?(Constants.rfc_regexp(), cleaned)

    if has_valid_format && validate_date(cleaned) && validate_verification_digit(cleaned) &&
         !has_forbidden_words?(cleaned) do
      %{result | is_valid: true, type: get_type(cleaned) || ""}
    else
      result
    end
  end

  defp parse_input(input) do
    input
    |> to_string()
    |> String.trim()
    |> String.upcase()
    |> String.replace(~r/[^0-9A-ZÑ&]/, "")
  end

  defp validate_date(rfc) do
    date_str = rfc |> String.slice(0..-4//1) |> String.slice(-6, 6)
    year = String.slice(date_str, 0, 2)
    month = String.slice(date_str, 2, 2)
    day = String.slice(date_str, 4, 2)

    case Date.new(String.to_integer("20" <> year), String.to_integer(month), String.to_integer(day)) do
      {:ok, _} -> true
      _ -> false
    end
  rescue
    _ -> false
  end

  defp validate_verification_digit(rfc) do
    digit = String.last(rfc)
    expected = CheckDigit.check_digit(rfc)
    expected == digit
  end
end
