defmodule Cfdi.Cleaner.Cleaners.RemoveNonSatNodes do
  @moduledoc false

  @allowed_prefixes MapSet.new(["cfdi", "tfd", ""])

  @doc """
  Elimina elementos cuyo nombre calificado usa un prefijo no permitido
  (`cfdi`, `tfd` o sin prefijo). Pensado para XML CFDI típico.
  """
  @spec clean(String.t()) :: String.t()
  def clean(xml) when is_binary(xml) do
    remove_non_sat(xml, 0, byte_size(xml), [])
  end

  defp remove_non_sat(_xml, pos, len, acc) when pos >= len do
    IO.iodata_to_binary(Enum.reverse(acc))
  end

  defp remove_non_sat(xml, pos, len, acc) do
    case :binary.match(xml, "<", scope: {pos, len - pos}) do
      :nomatch ->
        IO.iodata_to_binary(Enum.reverse([binary_part(xml, pos, len - pos) | acc]))

      {start, _} ->
        prefix = binary_part(xml, pos, start - pos)

        case parse_token(xml, start + 1, len) do
          {:pi, end_pos} ->
            chunk = binary_part(xml, start, end_pos - start)
            remove_non_sat(xml, end_pos, len, [chunk, prefix | acc])

          {:comment, end_pos} ->
            chunk = binary_part(xml, start, end_pos - start)
            remove_non_sat(xml, end_pos, len, [chunk, prefix | acc])

          {:close, _name, end_pos} ->
            chunk = binary_part(xml, start, end_pos - start)
            remove_non_sat(xml, end_pos, len, [chunk, prefix | acc])

          {:open, qname, self_closing?, end_pos} ->
            pre = tag_prefix(qname)

            cond do
              MapSet.member?(@allowed_prefixes, pre) ->
                chunk = binary_part(xml, start, end_pos - start)
                remove_non_sat(xml, end_pos, len, [chunk, prefix | acc])

              self_closing? ->
                remove_non_sat(xml, end_pos, len, [prefix | acc])

              true ->
                case skip_subtree(xml, end_pos, len, qname) do
                  {:ok, after_close} -> remove_non_sat(xml, after_close, len, [prefix | acc])
                  :nomatch -> IO.iodata_to_binary(Enum.reverse([prefix | acc]))
                end
            end

          :incomplete ->
            IO.iodata_to_binary(Enum.reverse([binary_part(xml, start, len - start), prefix | acc]))
        end
    end
  end

  defp tag_prefix(qname) do
    case String.split(qname, ":", parts: 2) do
      [p, _] -> p
      [_] -> ""
    end
  end

  defp parse_token(xml, pos, len) do
    cond do
      comment_start?(xml, pos, len) ->
        case :binary.match(xml, "-->", scope: {pos, len - pos}) do
          :nomatch -> :incomplete
          {mpos, mlen} -> {:comment, mpos + mlen}
        end

      pos < len and :binary.at(xml, pos) == ?? ->
        case :binary.match(xml, "?>", scope: {pos, len - pos}) do
          :nomatch -> :incomplete
          {mpos, mlen} -> {:pi, mpos + mlen}
        end

      close_start?(xml, pos, len) ->
        case read_qname(xml, pos + 2, len) do
          {:ok, name, after_name} ->
            end_pos = scan_to_gt(xml, after_name, len)
            if end_pos == :incomplete, do: :incomplete, else: {:close, name, end_pos}

          :bad ->
            :incomplete
        end

      true ->
        case read_qname(xml, pos, len) do
          {:ok, name, after_name} ->
            case scan_to_gt(xml, after_name, len) do
              :incomplete ->
                :incomplete

              end_pos ->
                sc = self_closing_at?(xml, end_pos)
                {:open, name, sc, end_pos}
            end

          :bad ->
            :incomplete
        end
    end
  end

  defp comment_start?(xml, pos, len), do: pos + 3 <= len and binary_part(xml, pos, 3) == "!--"

  defp close_start?(xml, pos, len), do: pos + 1 < len and binary_part(xml, pos, 2) == "</"

  defp read_qname(xml, pos, len) when pos < len do
    c = :binary.at(xml, pos)

    if name_start?(c) do
      take_name(xml, pos + 1, len, pos)
    else
      :bad
    end
  end

  defp read_qname(_, _, _), do: :bad

  defp name_start?(c) do
    (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) or c == ?_ or c == ?:
  end

  defp name_char?(c) do
    name_start?(c) or (c >= ?0 and c <= ?9) or c == ?-
  end

  defp take_name(xml, pos, len, start) when pos < len do
    c = :binary.at(xml, pos)

    if name_char?(c) do
      take_name(xml, pos + 1, len, start)
    else
      {:ok, binary_part(xml, start, pos - start), pos}
    end
  end

  defp take_name(xml, pos, len, start) do
    {:ok, binary_part(xml, start, pos - start), pos}
  end

  defp self_closing_at?(xml, end_pos) when end_pos >= 1 do
    # end_pos is index just after '>'
    gt = end_pos - 1
    # walk back over whitespace before '>'
    p = skip_ws_back(xml, gt - 1)
    p >= 0 and :binary.at(xml, p) == ?/
  end

  defp self_closing_at?(_, _), do: false

  defp skip_ws_back(xml, p) when p >= 0 do
    c = :binary.at(xml, p)

    if c in [?\s, ?\t, ?\n, ?\r] do
      skip_ws_back(xml, p - 1)
    else
      p
    end
  end

  defp skip_ws_back(_, p), do: p

  defp scan_to_gt(xml, pos, len) when pos < len do
    case :binary.at(xml, pos) do
      ?> ->
        pos + 1

      ?" ->
        case scan_string(xml, pos + 1, len, ?") do
          {:ok, np} -> scan_to_gt(xml, np, len)
          :incomplete -> :incomplete
        end

      ?' ->
        case scan_string(xml, pos + 1, len, ?') do
          {:ok, np} -> scan_to_gt(xml, np, len)
          :incomplete -> :incomplete
        end

      _ ->
        scan_to_gt(xml, pos + 1, len)
    end
  end

  defp scan_to_gt(_, _, _), do: :incomplete

  defp scan_string(xml, pos, len, quote) when pos < len do
    case :binary.at(xml, pos) do
      ^quote ->
        pos + 1

      ?\\ ->
        scan_string(xml, pos + 2, len, quote)

      _ ->
        scan_string(xml, pos + 1, len, quote)
    end
  end

  defp scan_string(_, _, _, _), do: :incomplete

  defp skip_subtree(xml, pos, len, open_qname) do
    skip_subtree(xml, pos, len, open_qname, 1)
  end

  defp skip_subtree(xml, pos, len, open_qname, depth) when depth > 0 and pos < len do
    case :binary.match(xml, "<", scope: {pos, len - pos}) do
      :nomatch ->
        :nomatch

      {s, _} ->
        case parse_token(xml, s + 1, len) do
          {:open, qname, self_closing?, end_pos} ->
            nd =
              if not self_closing? and qname == open_qname, do: depth + 1, else: depth

            skip_subtree(xml, end_pos, len, open_qname, nd)

          {:close, qname, end_pos} ->
            nd = if qname == open_qname, do: depth - 1, else: depth
            skip_subtree(xml, end_pos, len, open_qname, nd)

          {:pi, end_pos} ->
            skip_subtree(xml, end_pos, len, open_qname, depth)

          {:comment, end_pos} ->
            skip_subtree(xml, end_pos, len, open_qname, depth)

          :incomplete ->
            :nomatch
        end
    end
  end

  defp skip_subtree(_, pos, _, _, 0), do: {:ok, pos}
  defp skip_subtree(_, _, _, _, _), do: :nomatch
end
