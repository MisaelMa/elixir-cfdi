defmodule Cfdi.Xml.JsonEncode do
  @moduledoc false

  @spec encode!(term()) :: String.t()
  def encode!(term), do: IO.iodata_to_binary(encode(term))

  defp encode(nil), do: "null"
  defp encode(true), do: "true"
  defp encode(false), do: "false"
  defp encode(n) when is_integer(n), do: Integer.to_string(n)
  defp encode(n) when is_float(n), do: :erlang.float_to_binary(n, [:compact, decimals: 20])

  defp encode(s) when is_binary(s) do
    [?", escape_string(s), ?"]
  end

  defp encode(a) when is_atom(a), do: encode(Atom.to_string(a))

  defp encode(m) when is_map(m) do
    m =
      if Map.has_key?(m, :__struct__) do
        Map.from_struct(m)
      else
        m
      end

    pairs =
      m
      |> Enum.map(fn {k, v} ->
        [encode(key_to_string(k)), ?:, encode(v)]
      end)
      |> Enum.intersperse(?,)

    [?{, pairs, ?}]
  end

  defp encode(l) when is_list(l) do
    inner = Enum.map(l, &encode/1) |> Enum.intersperse(?,)
    [?[, inner, ?]]
  end

  defp key_to_string(k) when is_atom(k), do: Atom.to_string(k)
  defp key_to_string(k) when is_binary(k), do: k
  defp key_to_string(k), do: to_string(k)

  defp escape_string(s) do
    s
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
    |> String.replace("\r", "\\r")
    |> String.replace("\t", "\\t")
  end
end
