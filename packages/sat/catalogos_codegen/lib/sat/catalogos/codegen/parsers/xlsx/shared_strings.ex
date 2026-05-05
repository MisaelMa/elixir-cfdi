defmodule Sat.Catalogos.Codegen.Parsers.Xlsx.SharedStrings do
  @moduledoc """
  SAX handler para parsear `xl/sharedStrings.xml` de un archivo XLSX.

  Construye un array indexado de strings que se usa para resolver
  referencias de tipo `t="s"` en las celdas de la hoja.
  """

  @behaviour Saxy.Handler

  @doc "Parse sharedStrings XML content, returns {:ok, [String.t()]} | {:error, term()}"
  @spec parse(String.t()) :: {:ok, [String.t()]} | {:error, term()}
  def parse(content) when is_binary(content) do
    initial = %{strings: [], current_text: nil, in_si: false, in_t: false}

    case Saxy.parse_string(content, __MODULE__, initial) do
      {:ok, state} -> {:ok, Enum.reverse(state.strings)}
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
    if state.in_t do
      current = state.current_text || ""
      {:ok, %{state | current_text: current <> chars}}
    else
      {:ok, state}
    end
  end

  defp on_start("si", _attrs, state) do
    {:ok, %{state | in_si: true, current_text: nil}}
  end

  defp on_start("t", _attrs, state) do
    {:ok, %{state | in_t: true}}
  end

  defp on_start(_name, _attrs, state), do: {:ok, state}

  defp on_end("t", state) do
    {:ok, %{state | in_t: false}}
  end

  defp on_end("si", state) do
    text = state.current_text || ""
    {:ok, %{state | in_si: false, current_text: nil, strings: [text | state.strings]}}
  end

  defp on_end(_name, state), do: {:ok, state}

  defp local_name({_ns, local}), do: local
  defp local_name(name) when is_binary(name), do: name
end
