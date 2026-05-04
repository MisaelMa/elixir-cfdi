defmodule Cfdi.Catalogos.Codegen.Parsers.Xlsx do
  @moduledoc """
  Parser de archivos XLSX usando `:zip` de OTP y `Saxy` para parsear XML.

  No depende de `xlsxir` ni ninguna librería externa más allá de `saxy`.
  """

  alias Cfdi.Catalogos.Codegen.Parsers.Xlsx.SharedStrings
  alias Cfdi.Catalogos.Codegen.Parsers.Xlsx.Sheet

  @doc """
  Lee una hoja de un archivo XLSX por nombre.

  Retorna `{:ok, [[String.t() | nil]]}` donde cada elemento de la lista
  exterior es una fila, y cada fila es una lista de valores de celda.

  Retorna `{:error, reason}` si el archivo no existe o la hoja no se encuentra.
  """
  @spec read_sheet(Path.t(), String.t()) :: {:ok, [[String.t() | nil]]} | {:error, term()}
  def read_sheet(xlsx_path, sheet_name) when is_binary(xlsx_path) and is_binary(sheet_name) do
    with {:ok, zip_entries} <- unzip_to_map(xlsx_path),
         {:ok, sheet_index} <- find_sheet_index(zip_entries, sheet_name),
         {:ok, shared_strings} <- parse_shared_strings(zip_entries),
         {:ok, rows} <- parse_sheet(zip_entries, sheet_index, shared_strings) do
      {:ok, rows}
    end
  end

  # ---- Private helpers ----

  # Unzip the xlsx and return a map of filename => binary content
  defp unzip_to_map(path) do
    charlist_path = String.to_charlist(path)

    case :zip.unzip(charlist_path, [:memory]) do
      {:ok, entries} ->
        map =
          Enum.reduce(entries, %{}, fn {name, content}, acc ->
            Map.put(acc, List.to_string(name), content)
          end)

        {:ok, map}

      {:error, :enoent} ->
        {:error, :enoent}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Find the sheet number (1-based) from workbook.xml by matching the sheet name
  defp find_sheet_index(zip_entries, sheet_name) do
    workbook_xml = Map.get(zip_entries, "xl/workbook.xml")

    if is_nil(workbook_xml) do
      {:error, {:missing_file, "xl/workbook.xml"}}
    else
      extract_sheet_index(workbook_xml, sheet_name)
    end
  end

  defp extract_sheet_index(workbook_xml, sheet_name) do
    # Parse sheet names from workbook.xml using regex (lightweight approach)
    # <sheet name="c_FormaPago" sheetId="1" r:id="rId1"/>
    regex = ~r/<sheet\s[^>]*name="([^"]+)"[^>]*sheetId="(\d+)"/

    sheets =
      Regex.scan(regex, workbook_xml)
      |> Enum.map(fn [_full, name, sheet_id] -> {name, String.to_integer(sheet_id)} end)

    case Enum.find(sheets, fn {name, _id} -> name == sheet_name end) do
      nil -> {:error, {:sheet_not_found, sheet_name}}
      {_name, sheet_id} -> {:ok, sheet_id}
    end
  end

  defp parse_shared_strings(zip_entries) do
    case Map.get(zip_entries, "xl/sharedStrings.xml") do
      nil ->
        # sharedStrings.xml is optional — if missing, no shared strings
        {:ok, []}

      content ->
        SharedStrings.parse(content)
    end
  end

  defp parse_sheet(zip_entries, sheet_index, shared_strings) do
    sheet_path = "xl/worksheets/sheet#{sheet_index}.xml"

    case Map.get(zip_entries, sheet_path) do
      nil ->
        {:error, {:missing_file, sheet_path}}

      content ->
        Sheet.parse(content, shared_strings)
    end
  end
end
