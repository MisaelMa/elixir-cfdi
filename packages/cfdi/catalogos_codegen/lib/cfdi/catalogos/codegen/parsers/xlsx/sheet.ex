defmodule Cfdi.Catalogos.Codegen.Parsers.Xlsx.Sheet do
  @moduledoc """
  SAX handler para parsear `xl/worksheets/sheetN.xml` de un archivo XLSX.

  Construye una lista de filas, donde cada fila es una lista de valores string (o nil).
  Resuelve referencias a sharedStrings cuando el tipo de celda es `t="s"`.
  """

  @behaviour Saxy.Handler

  @doc "Parse sheet XML, returns {:ok, [[String.t() | nil]]} | {:error, term()}"
  @spec parse(String.t(), [String.t()]) :: {:ok, [[String.t() | nil]]} | {:error, term()}
  def parse(content, shared_strings) when is_binary(content) and is_list(shared_strings) do
    initial = %{
      shared_strings: shared_strings,
      rows: [],
      current_row: [],
      current_cell_type: nil,
      current_cell_value: nil,
      in_v: false,
      in_t: false
    }

    case Saxy.parse_string(content, __MODULE__, initial) do
      {:ok, state} -> {:ok, Enum.reverse(state.rows)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl Saxy.Handler
  def handle_event(event, data, state) do
    handle(event, data, state)
  end

  defp handle(:start_document, _prolog, state), do: {:ok, state}
  defp handle(:end_document, _data, state), do: {:ok, state}

  defp handle(:start_element, {name_or_ns, attributes}, state) do
    name = local_name(name_or_ns)
    on_start(name, attributes, state)
  end

  defp handle(:end_element, name_or_ns, state) do
    name = local_name(name_or_ns)
    on_end(name, state)
  end

  defp handle(:characters, chars, state) do
    cond do
      state.in_v ->
        current = state.current_cell_value || ""
        {:ok, %{state | current_cell_value: current <> chars}}

      state.in_t ->
        current = state.current_cell_value || ""
        {:ok, %{state | current_cell_value: current <> chars}}

      true ->
        {:ok, state}
    end
  end

  defp on_start("row", _attrs, state) do
    {:ok, %{state | current_row: []}}
  end

  defp on_start("c", attrs, state) do
    cell_type = find_attr(attrs, "t")
    {:ok, %{state | current_cell_type: cell_type, current_cell_value: nil}}
  end

  defp on_start("v", _attrs, state) do
    {:ok, %{state | in_v: true, current_cell_value: nil}}
  end

  defp on_start("t", _attrs, state) do
    # Inline string <is><t>...</t></is>
    {:ok, %{state | in_t: true, current_cell_value: nil}}
  end

  defp on_start(_name, _attrs, state), do: {:ok, state}

  defp on_end("v", state) do
    {:ok, %{state | in_v: false}}
  end

  defp on_end("t", state) do
    {:ok, %{state | in_t: false}}
  end

  defp on_end("c", state) do
    value = resolve_value(state.current_cell_type, state.current_cell_value, state.shared_strings)
    {:ok, %{state | current_row: [value | state.current_row], current_cell_type: nil, current_cell_value: nil}}
  end

  defp on_end("row", state) do
    row = Enum.reverse(state.current_row)
    {:ok, %{state | rows: [row | state.rows], current_row: []}}
  end

  defp on_end(_name, state), do: {:ok, state}

  # Resolve cell value based on OOXML type:
  # "s" = shared string index reference
  # nil/other = inline value (number or string)
  defp resolve_value("s", raw, shared_strings) when is_binary(raw) do
    case Integer.parse(raw) do
      {index, ""} -> Enum.at(shared_strings, index)
      _ -> raw
    end
  end

  defp resolve_value(_type, raw, _shared_strings), do: raw

  defp local_name({_ns, local}), do: local
  defp local_name(name) when is_binary(name), do: name

  defp find_attr(attrs, key) do
    Enum.find_value(attrs, nil, fn
      {^key, value} -> value
      _ -> false
    end)
  end
end
