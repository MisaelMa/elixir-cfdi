defmodule Cfdi.Transform.XsltLocalizer do
  @moduledoc """
  Localiza el `cadenaoriginal_4_0.xslt` oficial del SAT.

  El XSLT que publica el SAT trae `xsl:include` con `href` REMOTO
  (`http://www.sat.gob.mx/...`) y `Cfdi.Transform.XsltParser` solo sigue includes
  relativos. Este modulo descarga cada complemento y reescribe los `href` a
  rutas relativas (`./complementos/<archivo>.xslt`).

  Lo usa `mix cfdi.xslt.update`. El fetcher es inyectable (`fetch/1`) para poder
  probarlo sin red.
  """

  @default_url "http://www.sat.gob.mx/sitio_internet/cfd/4/cadenaoriginal_4_0/cadenaoriginal_4_0.xslt"
  @main_file "cadenaoriginal_4_0.xslt"
  @complementos_dir "complementos"
  @include_re ~r/(<(?:\w+:)?include\s+[^>]*?href\s*=\s*)(["'])(https?:\/\/[^"']+)\2/

  @type fetch :: (String.t() -> {:ok, binary()} | {:error, term()})

  @doc "URL oficial del XSLT principal."
  def default_url, do: @default_url

  @doc "Lista los `href` remotos (`http(s)://`) de los `xsl:include` de un XSLT."
  @spec remote_includes(String.t()) :: [String.t()]
  def remote_includes(content) do
    @include_re |> Regex.scan(content) |> Enum.map(fn [_, _, _, href] -> href end)
  end

  @doc """
  Reescribe los includes remotos a `<prefix>/<archivo>`. Devuelve el contenido
  nuevo y la lista `[{href_remoto, nombre_local}]`.
  """
  @spec localize(String.t(), String.t()) :: {String.t(), [{String.t(), String.t()}]}
  def localize(content, prefix \\ "./" <> @complementos_dir) do
    mapping = for href <- remote_includes(content), do: {href, Path.basename(href)}

    out =
      Regex.replace(@include_re, content, fn _, head, quote, href ->
        head <> quote <> prefix <> "/" <> Path.basename(href) <> quote
      end)

    {out, mapping}
  end

  @doc """
  Descarga el XSLT principal y sus complementos a `dest_dir` con los includes
  reescritos. Solo escribe en disco si TODAS las descargas funcionan.

  Opciones: `:url` (por defecto la oficial).

  Devuelve `{:ok, [rutas_escritas]}` o `{:error, {:download_failed, url, razon}}`.
  """
  @spec update(String.t(), fetch(), keyword()) :: {:ok, [String.t()]} | {:error, term()}
  def update(dest_dir, fetch \\ &http_get/1, opts \\ []) do
    url = Keyword.get(opts, :url, @default_url)

    with {:ok, main} <- download(fetch, url),
         {main_local, mapping} = localize(main),
         {:ok, comps} <- download_all(fetch, mapping) do
      comps_dir = Path.join(dest_dir, @complementos_dir)
      File.mkdir_p!(comps_dir)

      main_path = Path.join(dest_dir, @main_file)
      File.write!(main_path, main_local)

      paths =
        for {name, body} <- comps do
          {body_local, _} = localize(body, ".")
          path = Path.join(comps_dir, name)
          File.write!(path, body_local)
          path
        end

      {:ok, [main_path | paths]}
    end
  end

  defp download_all(fetch, mapping) do
    Enum.reduce_while(mapping, {:ok, []}, fn {href, name}, {:ok, acc} ->
      case download(fetch, href) do
        {:ok, body} -> {:cont, {:ok, acc ++ [{name, body}]}}
        error -> {:halt, error}
      end
    end)
  end

  defp download(fetch, url) do
    case fetch.(url) do
      {:ok, body} -> {:ok, body}
      {:error, reason} -> {:error, {:download_failed, url, reason}}
    end
  end

  @doc false
  def http_get(url) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    request = {String.to_charlist(url), []}
    http_opts = [timeout: 30_000, ssl: [verify: :verify_none]]

    case :httpc.request(:get, request, http_opts, body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, body}} -> {:ok, body}
      {:ok, {{_, status, _}, _, _}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, reason}
    end
  end
end
