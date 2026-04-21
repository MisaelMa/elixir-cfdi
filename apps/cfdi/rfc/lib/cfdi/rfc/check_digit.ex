defmodule Cfdi.Rfc.CheckDigit do
  @moduledoc false

  @values_map %{
    ?0 => 0, ?1 => 1, ?2 => 2, ?3 => 3, ?4 => 4,
    ?5 => 5, ?6 => 6, ?7 => 7, ?8 => 8, ?9 => 9,
    ?A => 10, ?B => 11, ?C => 12, ?D => 13, ?E => 14,
    ?F => 15, ?G => 16, ?H => 17, ?I => 18, ?J => 19,
    ?K => 20, ?L => 21, ?M => 22, ?N => 23, ?& => 24,
    ?O => 25, ?P => 26, ?Q => 27, ?R => 28, ?S => 29,
    ?T => 30, ?U => 31, ?V => 32, ?W => 33, ?X => 34,
    ?Y => 35, ?Z => 36, ?\s => 37, ?Ñ => 38
  }

  @spec check_digit(String.t()) :: String.t()
  def check_digit(input) do
    rfc = if byte_size(input) == 12, do: " " <> input, else: input
    base = String.slice(rfc, 0..-2//1)
    score = get_score(base)
    mod = rem(11000 - score, 11)

    cond do
      mod == 11 -> "0"
      mod == 10 -> "A"
      true -> Integer.to_string(mod)
    end
  end

  defp get_score(string) do
    string
    |> String.to_charlist()
    |> Enum.reverse()
    |> Enum.with_index(2)
    |> Enum.reduce(0, fn {char, index}, sum ->
      value = Map.get(@values_map, char, 0)
      sum + value * index
    end)
  end
end
