defmodule Renapo.Curp.Curp do
  @moduledoc false

  alias Renapo.Curp.Common.Constants
  alias Renapo.Curp.Utils.CheckDigit

  @spec parse_input(String.t()) :: map()
  def parse_input(raw) when is_binary(raw) do
    curp = raw |> String.trim() |> String.upcase() |> String.replace(~r/[^0-9A-ZÑ]/u, "")

    if String.length(curp) == 18 do
      %{
        curp: curp,
        birthdate: String.slice(curp, 4, 6),
        gender: String.at(curp, 10),
        state: String.slice(curp, 11, 2)
      }
    else
      %{curp: curp}
    end
  end

  @spec validate_local(String.t()) :: %{is_valid: boolean(), rfc: String.t(), errors: [term()]}
  def validate_local(value) when is_binary(value) do
    %{curp: curp} = parse_input(value)
    errors = []

    errors =
      if Regex.match?(Constants.curp_re(), curp) do
        errors
      else
        [Constants.error_invalid_format() | errors]
      end

    errors =
      if String.length(curp) >= 4 and MapSet.member?(Constants.forbidden_set(), String.slice(curp, 0, 4)) do
        [Constants.error_forbidden() | errors]
      else
        errors
      end

    %{is_valid: errors == [], rfc: curp, errors: Enum.reverse(errors)}
  end

  @spec validate(String.t()) :: %{is_valid: boolean(), rfc: String.t(), errors: [term()]}
  def validate(value) when is_binary(value) do
    local = validate_local(value)

    unless local[:is_valid] do
      local
    else
      %{curp: curp} = parse_input(value)

      errors =
        []
        |> then(fn e ->
          case Constants.parse_curp_birthdate(String.slice(curp, 4, 6)) do
            {:ok, _} -> e
            {:error, err} -> [err | e]
          end
        end)
        |> then(fn e ->
          st = String.slice(curp, 11, 2)
          if Map.has_key?(Constants.state_map(), st), do: e, else: [Constants.error_bad_state() | e]
        end)
        |> then(fn e ->
          expected = CheckDigit.check_digit(curp)
          actual = String.at(curp, 17)

          if expected == actual, do: e, else: [Constants.error_bad_check_digit() | e]
        end)

      %{is_valid: errors == [], rfc: curp, errors: Enum.reverse(errors)}
    end
  end

  @spec get_state(String.t()) :: String.t() | nil
  def get_state(curp) when is_binary(curp) and byte_size(curp) >= 13 do
    curp |> String.slice(11, 2) |> then(&Map.get(Constants.state_map(), &1))
  end

  def get_state(_), do: nil
end
