defmodule Sat.Cfdi.Descarga.Masiva.Paquete.Reader do
  @moduledoc """
  Extrae el contenido del ZIP descargado del WS de Descarga Masiva.

  Hay dos tipos de paquete segun el `tipo_solicitud`:

    * `:cfdi` — el ZIP contiene archivos `.xml` (uno por CFDI).
    * `:metadata` — el ZIP contiene un unico `.txt` con metadatos en TSV.

  Esta capa abre el ZIP en memoria con `:zip.unzip/2` y entrega cada
  XML/registro al consumidor. No parsea el XML — para eso usar `Cfdi.Xml.Parser`.
  """

  alias Sat.Cfdi.Descarga.Masiva.Types.Paquete

  @doc """
  Stream lazy de XMLs de un paquete `:cfdi`. Cada elemento es
  `{filename, xml}` donde `filename` es el nombre dentro del ZIP y `xml`
  es el contenido como binario UTF-8.
  """
  @spec stream_cfdis(Paquete.t()) :: {:ok, Enumerable.t()} | {:error, term()}
  def stream_cfdis(%Paquete{content: content}) when is_binary(content) do
    case unzip_in_memory(content) do
      {:ok, files} ->
        stream =
          files
          |> Stream.filter(fn {name, _} -> String.ends_with?(String.downcase(to_string(name)), ".xml") end)
          |> Stream.map(fn {name, data} -> {to_string(name), to_string(data)} end)

        {:ok, stream}

      {:error, _} = e ->
        e
    end
  end

  def stream_cfdis(_), do: {:error, {:invalid_paquete, :empty_or_nil}}

  @doc """
  Lista de filas del paquete `:metadata`. Cada fila es un map con keys
  como `:uuid`, `:rfcemisor`, `:rfcreceptor`, `:total`, etc.

  El TSV usa `~` (tilde) como separador de columnas (formato del SAT) y
  la primera linea es el header.
  """
  @spec parse_metadata(Paquete.t()) :: {:ok, [map()]} | {:error, term()}
  def parse_metadata(%Paquete{content: content}) when is_binary(content) do
    with {:ok, files} <- unzip_in_memory(content),
         {:ok, txt_content} <- find_txt(files) do
      rows =
        txt_content
        |> String.split(["\r\n", "\n"], trim: true)
        |> parse_tsv()

      {:ok, rows}
    end
  end

  def parse_metadata(_), do: {:error, {:invalid_paquete, :empty_or_nil}}

  @doc """
  Lista los nombres de archivos dentro del paquete (utilidad de debug).
  """
  @spec list_files(Paquete.t()) :: {:ok, [String.t()]} | {:error, term()}
  def list_files(%Paquete{content: content}) when is_binary(content) do
    case unzip_in_memory(content) do
      {:ok, files} -> {:ok, Enum.map(files, fn {n, _} -> to_string(n) end)}
      {:error, _} = e -> e
    end
  end

  def list_files(_), do: {:error, {:invalid_paquete, :empty_or_nil}}

  defp unzip_in_memory(zip_bin) when is_binary(zip_bin) do
    case :zip.unzip(zip_bin, [:memory]) do
      {:ok, files} -> {:ok, files}
      {:error, reason} -> {:error, {:zip_error, reason}}
    end
  rescue
    e -> {:error, {:zip_error, e}}
  end

  defp find_txt(files) do
    case Enum.find(files, fn {name, _} ->
           String.ends_with?(String.downcase(to_string(name)), ".txt")
         end) do
      {_name, content} -> {:ok, to_string(content)}
      nil -> {:error, {:metadata_not_found, :no_txt_file}}
    end
  end

  defp parse_tsv([]), do: []

  defp parse_tsv([header | rows]) do
    headers = header |> String.split("~") |> Enum.map(&normalize_header/1)

    Enum.map(rows, fn row ->
      values = String.split(row, "~")

      headers
      |> Enum.zip(values ++ List.duplicate("", max(0, length(headers) - length(values))))
      |> Map.new()
    end)
  end

  defp normalize_header(name) do
    name
    |> String.trim()
    |> String.replace(" ", "_")
    |> String.downcase()
    |> String.to_atom()
  end
end
