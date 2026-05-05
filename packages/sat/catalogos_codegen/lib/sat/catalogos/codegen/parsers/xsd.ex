defmodule Sat.Catalogos.Codegen.Parsers.Xsd do
  @moduledoc """
  Parser de archivos XSD del SAT para extraer simpleType + enumeraciones.

  Utiliza expresiones regulares sobre el contenido del XSD para extraer
  los bloques `xs:simpleType` y sus valores `xs:enumeration`.
  """

  @simple_type_regex ~r/<xs:simpleType\s+name="([^"]+)"[^>]*>([\s\S]*?)<\/xs:simpleType>/
  @enumeration_regex ~r/<xs:enumeration\s+value="([^"]*)"\s*\/?>/

  @doc """
  Parsea el contenido de un XSD como string y extrae los simpleTypes.

  Retorna `{:ok, %{type_name => [code, ...]}}` o `{:error, reason}`.
  """
  @spec parse_string(String.t()) :: {:ok, %{String.t() => [String.t()]}} | {:error, term()}
  def parse_string(content) when is_binary(content) do
    case validate_xml(content) do
      :ok ->
        result =
          @simple_type_regex
          |> Regex.scan(content, capture: :all_but_first)
          |> Enum.reduce(%{}, fn [name, body], acc ->
            codes =
              @enumeration_regex
              |> Regex.scan(body, capture: :all_but_first)
              |> Enum.map(fn [value] -> value end)

            if codes == [] do
              acc
            else
              Map.put(acc, name, codes)
            end
          end)

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parsea un archivo XSD desde el filesystem.

  Retorna `{:ok, %{type_name => [code, ...]}}` o `{:error, reason}`.
  """
  @spec parse(Path.t()) :: {:ok, %{String.t() => [String.t()]}} | {:error, term()}
  def parse(path) when is_binary(path) do
    case File.read(path) do
      {:ok, content} -> parse_string(content)
      {:error, reason} -> {:error, reason}
    end
  end

  # Validates that the XSD content is well-formed XML using Saxy.
  # Returns :ok for valid XML, {:error, reason} for malformed/truncated XML.
  defp validate_xml(content) do
    case Saxy.parse_string(content, __MODULE__.NullHandler, nil) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Minimal SAX handler used only for XML validation — discards all events.
  defmodule NullHandler do
    @moduledoc false
    @behaviour Saxy.Handler

    @impl Saxy.Handler
    def handle_event(_event, _data, state), do: {:ok, state}
  end
end
