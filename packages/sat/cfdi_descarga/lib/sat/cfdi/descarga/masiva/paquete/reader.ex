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
          |> Stream.filter(fn {name, _} ->
            String.ends_with?(String.downcase(to_string(name)), ".xml")
          end)
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

  Igual que phpcfdi (`MetadataFileFilter`, `MetadataPreprocessor`,
  `ThirdPartiesFileFilter`):

    * Lee **todos** los `.txt` cuyo contenido empieza con `Uuid~RfcEmisor~`
      (en orden por nombre). El ZIP puede traer tambien el archivo de terceros
      (`*_tercero.txt`, que tambien empieza con `Uuid~`), que no es metadata.
    * El EOL del SAT es `\\r\\n` y un campo puede traer un `\\n` adentro: si el
      archivo usa CRLF, los `\\n` sueltos se quitan antes de partir en lineas.
    * Si viene el archivo de terceros, agrega `:rfcacuentaterceros` y
      `:nombreacuentaterceros` a la fila con el mismo UUID.
  """
  @spec parse_metadata(Paquete.t()) :: {:ok, [map()]} | {:error, term()}
  def parse_metadata(%Paquete{content: content}) when is_binary(content) do
    with {:ok, files} <- unzip_in_memory(content),
         txts = txt_files(files),
         [_ | _] = metadata <- Enum.filter(txts, fn {_, data} -> metadata_txt?(data) end) do
      terceros = terceros_por_uuid(txts)

      rows =
        Enum.flat_map(metadata, fn {_name, data} ->
          data
          |> lines()
          |> parse_tsv()
          |> Enum.map(&agregar_terceros(&1, terceros))
        end)

      {:ok, rows}
    else
      [] -> {:error, {:metadata_not_found, :no_txt_file}}
      {:error, _} = e -> e
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

  @bom "﻿"

  # `.txt` del ZIP como `{nombre, contenido}` sin BOM, en orden por nombre.
  defp txt_files(files) do
    files
    |> Enum.map(fn {name, data} -> {to_string(name), data |> to_string() |> strip_bom()} end)
    |> Enum.filter(fn {name, _} -> String.ends_with?(String.downcase(name), ".txt") end)
    |> Enum.sort_by(fn {name, _} -> name end)
  end

  defp strip_bom(@bom <> rest), do: rest
  defp strip_bom(data), do: data

  defp metadata_txt?(data), do: header_starts_with?(data, "uuid~rfcemisor~")

  defp terceros_txt?(data),
    do: header_starts_with?(data, "uuid~rfcacuentaterceros~nombreacuentaterceros")

  defp header_starts_with?(data, prefix) do
    data
    |> binary_part(0, min(byte_size(data), byte_size(prefix)))
    |> String.downcase()
    |> Kernel.==(prefix)
  end

  # Mapa UUID (mayusculas) => campos de terceros, del primer `.txt` de terceros.
  defp terceros_por_uuid(txts) do
    case Enum.find(txts, fn {_, data} -> terceros_txt?(data) end) do
      nil ->
        %{}

      {_name, data} ->
        data
        |> lines()
        |> parse_tsv()
        |> Enum.reject(&(Map.get(&1, :uuid, "") == ""))
        |> Map.new(fn row ->
          {String.upcase(row.uuid), Map.take(row, [:rfcacuentaterceros, :nombreacuentaterceros])}
        end)
    end
  end

  defp agregar_terceros(row, terceros) when terceros == %{}, do: row

  defp agregar_terceros(row, terceros) do
    case Map.get(terceros, String.upcase(Map.get(row, :uuid, ""))) do
      nil -> row
      extra -> Map.merge(row, extra)
    end
  end

  # Parte en lineas. Si el EOL es CRLF, un `\n` suelto es un salto dentro de un
  # campo y se quita (phpcfdi `MetadataPreprocessor::fixEolCrLf`).
  defp lines(data) do
    if crlf?(data) do
      data
      |> String.split("\r\n", trim: true)
      |> Enum.map(&String.replace(&1, "\n", ""))
    else
      String.split(data, ["\r\n", "\n"], trim: true)
    end
  end

  defp crlf?(data) do
    case :binary.match(data, "\n") do
      {pos, _} when pos > 0 -> :binary.at(data, pos - 1) == ?\r
      _ -> false
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
