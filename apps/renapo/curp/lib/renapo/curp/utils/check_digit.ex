defmodule Renapo.Curp.Utils.CheckDigit do
  @moduledoc false

  @values %{
    "0" => 0,
    "1" => 1,
    "2" => 2,
    "3" => 3,
    "4" => 4,
    "5" => 5,
    "6" => 6,
    "7" => 7,
    "8" => 8,
    "9" => 9,
    "A" => 10,
    "B" => 11,
    "C" => 12,
    "D" => 13,
    "E" => 14,
    "F" => 15,
    "G" => 16,
    "H" => 17,
    "I" => 18,
    "J" => 19,
    "K" => 20,
    "L" => 21,
    "M" => 22,
    "N" => 23,
    "Ñ" => 24,
    "O" => 25,
    "P" => 26,
    "Q" => 27,
    "R" => 28,
    "S" => 29,
    "T" => 30,
    "U" => 31,
    "V" => 32,
    "W" => 33,
    "X" => 34,
    "Y" => 35,
    "Z" => 36
  }

  @doc """
  Returns the expected 18th CURP character (check digit) for a 17-char base (or full 18-char CURP).
  """
  @spec check_digit(String.t()) :: String.t()
  def check_digit(curp) when is_binary(curp) do
    base = String.slice(curp, 0, 17)
    score = score_base(base)
    mod = rem(score, 10)

    if mod == 0 do
      "0"
    else
      Integer.to_string(10 - mod)
    end
  end

  defp score_base(base) do
    base
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce(0, fn {ch, i}, acc ->
      weight = 18 - i
      val = Map.get(@values, ch, 0)
      acc + val * weight
    end)
  end
end
