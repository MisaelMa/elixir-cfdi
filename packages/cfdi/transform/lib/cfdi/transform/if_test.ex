defmodule Cfdi.Transform.IfTest do
  @moduledoc """
  Parser del subconjunto de XPath que soporta `xsl:if test="..."`.

  Gramatica (precedencia XPath: `or` < `and` < `not`):

      expr  := and ( "or" and )*
      and   := unary ( "and" unary )*
      unary := "not(" expr ")" | "(" expr ")" | atom
      atom  := @attr ( "=" | "!=" ) 'literal'  |  @attr  |  ruta/de/hijos

  Todo lo demas (`contains()`, `count()`, `>`, `[...]`, ...) devuelve
  `{:error, :unsupported}`. Se usa en tiempo de parseo del XSLT (para avisar o
  fallar con `strict: true`) y en `Cfdi.Transform.CadenaEngine` para evaluar.
  """

  @type ast ::
          {:or, [ast]}
          | {:and, [ast]}
          | {:not, ast}
          | {:attr_eq, String.t(), String.t()}
          | {:attr_ne, String.t(), String.t()}
          | {:attr, String.t()}
          | {:path, String.t()}

  @spec parse(String.t()) :: {:ok, ast} | {:error, :unsupported}
  def parse(test) when is_binary(test) do
    case parse_expr(String.trim(test)) do
      {:ok, _} = ok -> ok
      _ -> {:error, :unsupported}
    end
  end

  @spec supported?(String.t()) :: boolean()
  def supported?(test), do: match?({:ok, _}, parse(test))

  defp parse_expr(""), do: :error

  defp parse_expr(s) do
    with {:ok, parts} <- parse_all(split_top(s, "or"), &parse_and/1) do
      {:ok, one_or({:or, parts}, parts)}
    end
  end

  defp parse_and(s) do
    with {:ok, parts} <- parse_all(split_top(s, "and"), &parse_unary/1) do
      {:ok, one_or({:and, parts}, parts)}
    end
  end

  defp parse_unary(s) do
    s = String.trim(s)

    cond do
      m = Regex.run(~r/^not\s*\((.*)\)$/s, s) ->
        with true <- balanced_wrapper?(s, elem(:binary.match(s, "("), 0)),
             {:ok, inner} <- parse_expr(String.trim(Enum.at(m, 1))) do
          {:ok, {:not, inner}}
        else
          _ -> :error
        end

      String.starts_with?(s, "(") and String.ends_with?(s, ")") and balanced_wrapper?(s, 0) ->
        parse_expr(String.trim(binary_part(s, 1, byte_size(s) - 2)))

      true ->
        parse_atom(s)
    end
  end

  defp parse_atom(s) do
    s = s |> String.trim() |> String.replace(~r/^\.\//, "")

    cond do
      m = Regex.run(~r/^@([\w:.\-]+)\s*(!?=)\s*(?:'([^'()]*)'|"([^"()]*)")$/, s) ->
        [_, name, op | vals] = m
        value = vals |> Enum.reject(&(&1 == "")) |> List.first() || ""
        {:ok, if(op == "=", do: {:attr_eq, name, value}, else: {:attr_ne, name, value})}

      m = Regex.run(~r/^@([\w:.\-]+)$/, s) ->
        {:ok, {:attr, Enum.at(m, 1)}}

      Regex.match?(~r/^[\w:.\-*]+(\/[\w:.\-*]+)*$/, s) ->
        {:ok, {:path, s}}

      true ->
        :error
    end
  end

  defp one_or(_multi, [single]), do: single
  defp one_or(multi, _), do: multi

  defp parse_all(parts, fun) do
    Enum.reduce_while(parts, {:ok, []}, fn p, {:ok, acc} ->
      case fun.(p) do
        {:ok, ast} -> {:cont, {:ok, acc ++ [ast]}}
        _ -> {:halt, :error}
      end
    end)
  end

  # Parte `s` por la palabra `kw` (` and ` / ` or `) solo en el nivel superior:
  # ignora lo que esta entre parentesis o entre comillas.
  defp split_top(s, kw) do
    s
    |> String.graphemes()
    |> do_split(kw, 0, nil, "", [])
  end

  defp do_split([], _kw, _d, _q, cur, acc), do: Enum.reverse([cur | acc])

  defp do_split([c | rest], kw, d, q, cur, acc) when q != nil do
    do_split(rest, kw, d, if(c == q, do: nil, else: q), cur <> c, acc)
  end

  defp do_split([c | rest], kw, d, nil, cur, acc) when c in ["'", "\""],
    do: do_split(rest, kw, d, c, cur <> c, acc)

  defp do_split(["(" | rest], kw, d, nil, cur, acc),
    do: do_split(rest, kw, d + 1, nil, cur <> "(", acc)

  defp do_split([")" | rest], kw, d, nil, cur, acc),
    do: do_split(rest, kw, d - 1, nil, cur <> ")", acc)

  defp do_split([c | rest], kw, 0, nil, cur, acc) do
    sep = " " <> kw <> " "
    joined = Enum.join([c | rest])

    if String.starts_with?(joined, sep) and cur != "" do
      skip = String.length(sep) - 1
      do_split(Enum.drop(rest, skip), kw, 0, nil, "", [cur | acc])
    else
      do_split(rest, kw, 0, nil, cur <> c, acc)
    end
  end

  defp do_split([c | rest], kw, d, nil, cur, acc), do: do_split(rest, kw, d, nil, cur <> c, acc)

  # El parentesis que abre en `from` cierra exactamente al final de `s`.
  defp balanced_wrapper?(s, from) do
    chars = s |> String.graphemes() |> Enum.drop(from)
    last = length(chars) - 1

    chars
    |> Enum.with_index()
    |> Enum.reduce_while({0, nil}, fn
      {c, _i}, {d, q} when q != nil -> {:cont, {d, if(c == q, do: nil, else: q)}}
      {c, _}, {d, nil} when c in ["'", "\""] -> {:cont, {d, c}}
      {"(", _}, {d, nil} -> {:cont, {d + 1, nil}}
      {")", i}, {1, nil} -> {:halt, i == last}
      {")", _}, {d, nil} -> {:cont, {d - 1, nil}}
      _, st -> {:cont, st}
    end)
    |> Kernel.==(true)
  end
end
