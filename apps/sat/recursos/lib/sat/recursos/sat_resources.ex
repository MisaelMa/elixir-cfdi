defmodule Sat.Recursos.SatResources do
  @moduledoc false

  defstruct [:version, :output_dir]

  @type version :: String.t()
  @type t :: %__MODULE__{version: version(), output_dir: String.t()}

  defmodule DownloadResult do
    @moduledoc false
    defstruct [
      :schema_path,
      :xslt_path,
      :catalog_schema_path,
      :tipo_datos_schema_path,
      :complementos,
      :unused,
      :added
    ]

    @type t :: %__MODULE__{
            schema_path: String.t(),
            xslt_path: String.t(),
            catalog_schema_path: String.t() | nil,
            tipo_datos_schema_path: String.t() | nil,
            complementos: [String.t()],
            unused: [String.t()],
            added: [String.t()]
          }
  end

  @urls %{
    "4.0" => %{
      schema: "https://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd",
      xslt: "https://www.sat.gob.mx/sitio_internet/cfd/4/cadenaoriginal_4_0/cadenaoriginal_4_0.xslt"
    },
    "3.3" => %{
      schema: "https://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd",
      xslt: "https://www.sat.gob.mx/sitio_internet/cfd/3/cadenaoriginal_3_3/cadenaoriginal_3_3.xslt"
    }
  }

  @spec new(keyword() | map()) :: t()
  def new(opts) when is_list(opts), do: new(Map.new(opts))

  def new(%{} = opts) do
    v = Map.fetch!(opts, :version) |> to_string()
    out = Map.fetch!(opts, :output_dir) |> to_string()

    unless Map.has_key?(@urls, v) do
      raise ArgumentError, "version must be 3.3 or 4.0"
    end

    %__MODULE__{version: v, output_dir: out}
  end

  @spec download(t()) :: {:ok, DownloadResult.t()} | {:error, String.t()}
  def download(%__MODULE__{} = resources) do
    urls = Map.fetch!(@urls, resources.version)
    comp_dir = Path.join(resources.output_dir, "complementos")

    with :ok <- ensure_dir(resources.output_dir),
         :ok <- ensure_dir(comp_dir),
         {:ok, schema_text} <- fetch_text(urls.schema),
         {:ok, _} <- write_file(schema_path(resources), schema_text),
         {catalog, tipo} = maybe_imports(schema_text, resources.output_dir),
         {:ok, raw_xslt} <- fetch_text(urls.xslt),
         xslt_clean = clean_xml(raw_xslt),
         includes = extract_xsl_includes(xslt_clean),
         {:ok, comp_paths} <- download_includes(includes, comp_dir),
         local_xslt = rewrite_includes(xslt_clean, includes),
         {:ok, _} <- write_file(Path.join(resources.output_dir, "cadenaoriginal.xslt"), local_xslt) do
      downloaded_names = comp_paths |> Enum.map(&Path.basename/1) |> MapSet.new()
      {unused, added} = diff_complementos(comp_dir, downloaded_names)

      {:ok,
       %DownloadResult{
         schema_path: schema_path(resources),
         xslt_path: Path.join(resources.output_dir, "cadenaoriginal.xslt"),
         catalog_schema_path: catalog,
         tipo_datos_schema_path: tipo,
         complementos: comp_paths,
         unused: unused,
         added: added
       }}
    end
  end

  defp schema_path(%{version: "4.0", output_dir: out}), do: Path.join(out, "cfdv40.xsd")
  defp schema_path(%{version: "3.3", output_dir: out}), do: Path.join(out, "cfdv33.xsd")

  defp ensure_dir(path) do
    case File.mkdir_p(path) do
      :ok -> :ok
      {:error, reason} -> {:error, "mkdir #{path}: #{inspect(reason)}"}
    end
  end

  defp fetch_text(url) do
    case Req.get(url, receive_timeout: 120_000) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "GET #{url} -> HTTP #{status}"}

      {:error, reason} ->
        {:error, "GET #{url}: #{inspect(reason)}"}
    end
  end

  defp write_file(path, content) do
    case File.write(path, content) do
      :ok -> {:ok, path}
      {:error, reason} -> {:error, "write #{path}: #{inspect(reason)}"}
    end
  end

  defp maybe_imports(schema_text, out_dir) do
    {cat_url, td_url} = extract_schema_imports(schema_text)
    {download_optional(cat_url, out_dir), download_optional(td_url, out_dir)}
  end

  defp download_optional(url, _out_dir) when not is_binary(url), do: nil

  defp download_optional(url, out_dir) do
    case fetch_text(url) do
      {:ok, text} ->
        path = Path.join(out_dir, basename_url(url))

        case write_file(path, text) do
          {:ok, _} -> path
          {:error, _} -> nil
        end

      {:error, _} ->
        nil
    end
  end

  defp extract_schema_imports(content) do
    re = ~r/<xs:import[^>]*schemaLocation=["']([^"']+)["'][^>]*>/i

    Enum.reduce(Regex.scan(re, content), {nil, nil}, fn [_whole, loc], {cat, td} ->
      cond do
        String.contains?(loc, "catCFDI") or String.contains?(loc, "catalogos") ->
          {loc, td}

        String.contains?(loc, "tdCFDI") or String.contains?(loc, "tipoDatos") ->
          {cat, loc}

        true ->
          {cat, td}
      end
    end)
  end

  defp extract_xsl_includes(xslt) do
    re = ~r/<xsl:include[^>]*href=["']([^"']+)["'][^>]*\/?>/i

    Regex.scan(re, xslt)
    |> Enum.map(fn [_w, href] -> href end)
    |> Enum.filter(&String.starts_with?(&1, "http://") or String.starts_with?(&1, "https://"))
  end

  defp download_includes(urls, comp_dir) do
    paths =
      Enum.reduce_while(urls, [], fn url, acc ->
        case fetch_text(url) do
          {:ok, body} ->
            name = basename_url(url)
            path = Path.join(comp_dir, name)

            case write_file(path, clean_xml(body)) do
              {:ok, _} -> {:cont, [path | acc]}
              {:error, err} -> {:halt, {:error, err}}
            end

          {:error, _} ->
            {:cont, acc}
        end
      end)

    case paths do
      {:error, _} = e -> e
      list -> {:ok, Enum.reverse(list)}
    end
  end

  defp rewrite_includes(xslt, include_urls) do
    Enum.reduce(include_urls, xslt, fn url, acc ->
      name = basename_url(url)
      local = "./complementos/#{name}"
      String.replace(acc, url, local)
    end)
  end

  defp diff_complementos(comp_dir, downloaded_names) do
    local_files =
      case File.ls(comp_dir) do
        {:ok, names} -> Enum.filter(names, &String.ends_with?(&1, ".xslt"))
        {:error, _} -> []
      end

    local_set = MapSet.new(local_files)
    unused = Enum.filter(local_files, fn f -> not MapSet.member?(downloaded_names, f) end)
    added = Enum.filter(downloaded_names, fn f -> not MapSet.member?(local_set, f) end)
    {unused, added}
  end

  defp basename_url(url) do
    url |> URI.parse() |> Map.get(:path, "") |> Path.basename() |> String.split("?") |> hd()
  end

  defp clean_xml(content) do
    starts =
      [
        match_start(content, "<?xml"),
        match_start(content, "<xsl:stylesheet"),
        match_start(content, "<xs:schema"),
        match_start(content, "<schema")
      ]
      |> Enum.reject(&is_nil/1)

    if starts == [] do
      content
    else
      start = Enum.min(starts)
      cleaned = binary_part(content, start, byte_size(content) - start)

      if not String.starts_with?(cleaned, "<?xml") and
           (String.contains?(cleaned, "<xsl:stylesheet") or
              String.contains?(cleaned, "<xsl:transform")) do
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" <> cleaned
      else
        cleaned
      end
    end
  end

  defp match_start(content, needle) do
    case :binary.match(content, needle) do
      {i, _} -> i
      :nomatch -> nil
    end
  end
end
