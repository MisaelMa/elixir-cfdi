defmodule Browser.Tls do
  @moduledoc """
  HTTPS client en NIF (OpenSSL) con TLS fingerprint configurable de
  navegador (JA3 de Chrome / Firefox / Safari).

  Permite bypass de proteccion anti-bot que detecta clientes TLS no-navegador
  (Akamai, Cloudflare) y sirve para servicios que verifican JA3 como el
  portal del SAT mexicano (`cfdiau.sat.gob.mx`).

  Los perfiles TLS viven en este modulo (`@profiles`). Para actualizar un
  fingerprint solo editas el atributo y reinicias Elixir — **no se
  recompila el codigo C**.

  ## Perfiles disponibles

      Browser.Tls.profiles()
      # => [:chrome, :firefox, :safari]

  ## Ejemplo

      # Default (Chrome)
      Browser.Tls.get("https://api.example.mx/v1/foo")

      # Con perfil especifico
      Browser.Tls.post(url, json: %{"a" => 1}, profile: :firefox)

      # A traves de un proxy HTTPS CONNECT
      Browser.Tls.get(url, proxy: {"proxy.example", 8080, "user", "pass"})

      # Diagnostico del JA3 actual (consulta tls.browserleaks.com)
      Browser.Tls.diagnose()           # Chrome
      Browser.Tls.diagnose(:firefox)
  """

  require Logger

  @profiles %{
    chrome: %{
      name: "Chrome 131",
      ciphers:
        "ECDHE-ECDSA-AES128-GCM-SHA256:" <>
          "ECDHE-RSA-AES128-GCM-SHA256:" <>
          "ECDHE-ECDSA-AES256-GCM-SHA384:" <>
          "ECDHE-RSA-AES256-GCM-SHA384:" <>
          "ECDHE-ECDSA-CHACHA20-POLY1305:" <>
          "ECDHE-RSA-CHACHA20-POLY1305:" <>
          "ECDHE-RSA-AES128-SHA:" <>
          "ECDHE-RSA-AES256-SHA:" <>
          "AES128-GCM-SHA256:" <>
          "AES256-GCM-SHA384:" <>
          "AES128-SHA:" <>
          "AES256-SHA",
      tls13_ciphers: "TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256",
      curves: "X25519:P-256:P-384",
      sigalgs:
        "ECDSA+SHA256:RSA-PSS+SHA256:RSA+SHA256:" <>
          "ECDSA+SHA384:RSA-PSS+SHA384:RSA+SHA384:" <>
          "RSA-PSS+SHA512:RSA+SHA512"
    },
    firefox: %{
      name: "Firefox 133",
      ciphers:
        "ECDHE-ECDSA-AES128-GCM-SHA256:" <>
          "ECDHE-RSA-AES128-GCM-SHA256:" <>
          "ECDHE-ECDSA-AES256-GCM-SHA384:" <>
          "ECDHE-RSA-AES256-GCM-SHA384:" <>
          "ECDHE-ECDSA-CHACHA20-POLY1305:" <>
          "ECDHE-RSA-CHACHA20-POLY1305:" <>
          "DHE-RSA-AES128-GCM-SHA256:" <>
          "DHE-RSA-AES256-GCM-SHA384:" <>
          "DHE-RSA-CHACHA20-POLY1305:" <>
          "ECDHE-RSA-AES128-SHA:" <>
          "ECDHE-RSA-AES256-SHA:" <>
          "AES128-GCM-SHA256:" <>
          "AES256-GCM-SHA384:" <>
          "AES128-SHA:" <>
          "AES256-SHA",
      tls13_ciphers: "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
      curves: "X25519:P-256:P-384:P-521",
      sigalgs:
        "ECDSA+SHA256:ECDSA+SHA384:ECDSA+SHA512:" <>
          "RSA-PSS+SHA256:RSA-PSS+SHA384:RSA-PSS+SHA512:" <>
          "RSA+SHA256:RSA+SHA384:RSA+SHA512"
    },
    safari: %{
      name: "Safari 18",
      ciphers:
        "ECDHE-ECDSA-AES256-GCM-SHA384:" <>
          "ECDHE-ECDSA-AES128-GCM-SHA256:" <>
          "ECDHE-ECDSA-CHACHA20-POLY1305:" <>
          "ECDHE-RSA-AES256-GCM-SHA384:" <>
          "ECDHE-RSA-AES128-GCM-SHA256:" <>
          "ECDHE-RSA-CHACHA20-POLY1305:" <>
          "ECDHE-ECDSA-AES256-SHA:" <>
          "ECDHE-ECDSA-AES128-SHA:" <>
          "ECDHE-RSA-AES256-SHA:" <>
          "ECDHE-RSA-AES128-SHA:" <>
          "AES256-GCM-SHA384:" <>
          "AES128-GCM-SHA256:" <>
          "AES256-SHA:" <>
          "AES128-SHA",
      tls13_ciphers: "TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256",
      curves: "X25519:P-256:P-384:P-521",
      sigalgs:
        "ECDSA+SHA256:RSA-PSS+SHA256:RSA+SHA256:" <>
          "ECDSA+SHA384:RSA-PSS+SHA384:RSA+SHA384:" <>
          "RSA-PSS+SHA512:RSA+SHA512"
    }
  }

  @default_profile :chrome

  # ── NIF Loading ─────────────────────────────────────────────────────

  @on_load :load_nif

  def load_nif do
    nif_path =
      :browser_tls
      |> :code.priv_dir()
      |> Path.join("browser_tls")
      |> String.to_charlist()

    :erlang.load_nif(nif_path, 0)
  end

  # NIF placeholder — reemplazado al cargar (13 args)
  def request(_method, _url, _headers, _body,
              _proxy_host, _proxy_port, _proxy_user, _proxy_pass,
              _ciphers, _tls13_ciphers, _curves, _sigalgs,
              _timeout_ms) do
    :erlang.nif_error(:nif_not_loaded)
  end

  # ── Public API ──────────────────────────────────────────────────────

  @doc "Lista de perfiles TLS disponibles."
  @spec profiles() :: [atom()]
  def profiles, do: Map.keys(@profiles)

  @doc "Datos de un perfil por nombre."
  @spec profile(atom()) :: map() | nil
  def profile(name), do: Map.get(@profiles, name)

  @doc "Nombre del perfil default (`:chrome`)."
  def default_profile, do: @default_profile

  def get(url, opts \\ []),     do: do_request("GET", url, opts)
  def post(url, opts \\ []),    do: do_request("POST", url, opts)
  def put(url, opts \\ []),     do: do_request("PUT", url, opts)
  def patch(url, opts \\ []),   do: do_request("PATCH", url, opts)
  def delete(url, opts \\ []),  do: do_request("DELETE", url, opts)
  def options(url, opts \\ []), do: do_request("OPTIONS", url, opts)
  def head(url, opts \\ []),    do: do_request("HEAD", url, opts)

  @doc "Request con metodo HTTP arbitrario."
  def http_request(method, url, opts \\ []) when is_binary(method) do
    do_request(String.upcase(method), url, opts)
  end

  # ── Diagnostico JA3 ─────────────────────────────────────────────────

  @doc """
  Muestra el JA3 fingerprint que produce el NIF con el perfil dado,
  consultando `tls.browserleaks.com`.

  Util para verificar que el perfil coincide con el navegador real cuando
  un servicio nos bloquea por JA3.
  """
  def diagnose(profile_name \\ @default_profile) do
    prof = Map.fetch!(@profiles, profile_name)
    Logger.info("[BrowserTls] Verificando JA3 con perfil #{prof.name}...")

    case get("https://tls.browserleaks.com/json", label: "JA3_DIAG", profile: profile_name) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        IO.puts("""

        ====================================
        Browser.Tls — JA3 Diagnostico
        ====================================
        Perfil:       #{prof.name} (:#{profile_name})
        TLS Version:  #{body["tls_version"]}
        Cipher:       #{body["cipher_name"]}
        JA3 Hash:     #{body["ja3_hash"]}
        JA3N Hash:    #{body["ja3n_hash"]}
        JA3 Text:     #{body["ja3_text"]}
        ====================================

        Perfiles disponibles: #{inspect(profiles())}

        Si el servicio te bloquea por JA3, abre el navegador y visita
        https://tls.browserleaks.com/json — compara el hash. Si difiere,
        actualiza @profiles en lib/clir/browser_tls.ex (no necesitas
        recompilar el C).
        ====================================
        """)

        {:ok,
         %{
           profile: profile_name,
           ja3_hash: body["ja3_hash"],
           ja3_text: body["ja3_text"],
           tls_version: body["tls_version"]
         }}

      {:ok, %{status: status, body: body}} ->
        Logger.error("[BrowserTls] browserleaks respondio #{status}")
        {:error, {:unexpected_status, status, body}}

      {:error, reason} ->
        Logger.error("[BrowserTls] No se pudo verificar JA3: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── Internals ───────────────────────────────────────────────────────

  defp do_request(method, url, opts) do
    label = Keyword.get(opts, :label, "BROWSER_TLS")
    headers = Keyword.get(opts, :headers, [])
    json_body = Keyword.get(opts, :json)
    proxy = Keyword.get(opts, :proxy)
    profile_name = Keyword.get(opts, :profile, @default_profile)
    timeout_ms = Keyword.get(opts, :receive_timeout, 30_000)

    prof = Map.fetch!(@profiles, profile_name)

    body =
      cond do
        json_body -> Jason.encode!(json_body)
        true -> Keyword.get(opts, :body, "")
      end

    headers = if json_body, do: ensure_content_type(headers), else: headers

    headers_str =
      headers
      |> Enum.map(fn {k, v} -> "#{k}: #{v}\r\n" end)
      |> Enum.join()

    {proxy_host, proxy_port, proxy_user, proxy_pass} =
      case proxy do
        {h, p, u, pw} -> {h, p, u, pw}
        nil -> {"", 0, "", ""}
      end

    Logger.debug(
      "[#{label}] -> #{method} #{url} | profile=#{profile_name} | proxy=#{format_proxy(proxy)}"
    )

    result =
      request(
        to_charlist(method), to_charlist(url),
        to_charlist(headers_str), to_charlist(body),
        to_charlist(proxy_host), proxy_port,
        to_charlist(proxy_user), to_charlist(proxy_pass),
        to_charlist(prof.ciphers), to_charlist(prof.tls13_ciphers),
        to_charlist(prof.curves), to_charlist(prof.sigalgs),
        timeout_ms
      )

    case result do
      {:ok, status, resp_body, content_type, headers_raw} when is_binary(resp_body) ->
        ct = to_string(content_type)
        headers = parse_headers(headers_raw)

        parsed_body =
          if json_content?(ct) do
            case Jason.decode(resp_body) do
              {:ok, decoded} -> decoded
              _ -> resp_body
            end
          else
            resp_body
          end

        if status in 200..299 do
          Logger.debug("[#{label}] <- #{status} OK | #{ct} | #{byte_size(resp_body)} bytes")
        else
          Logger.debug("[#{label}] <- #{status} | #{ct} | #{preview(parsed_body)}")
        end

        {:ok, %{status: status, body: parsed_body, content_type: ct, headers: headers}}

      {:error, reason} ->
        Logger.warning("[#{label}] <- ERROR: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Parsea un blob de headers HTTP crudos a una lista `[{name, value}]`.
  Los headers repetidos (como `Set-Cookie`) se preservan como entradas
  separadas. Ignora la status line.
  """
  @spec parse_headers(binary()) :: [{String.t(), String.t()}]
  def parse_headers(""), do: []
  def parse_headers(nil), do: []

  def parse_headers(raw) when is_binary(raw) do
    raw
    |> String.split(["\r\n", "\n"], trim: false)
    |> Enum.drop(1)
    |> Enum.flat_map(fn line ->
      case String.split(line, ":", parts: 2) do
        [name, value] -> [{String.downcase(String.trim(name)), String.trim(value)}]
        _ -> []
      end
    end)
  end

  defp json_content?(ct), do: String.contains?(ct, "json") or ct == "" or ct == nil
  defp format_proxy(nil), do: "none"
  defp format_proxy({host, port, _, _}), do: "#{host}:#{port}"

  defp ensure_content_type(headers) do
    has_ct = Enum.any?(headers, fn {k, _} -> String.downcase(k) == "content-type" end)
    if has_ct, do: headers, else: [{"content-type", "application/json"} | headers]
  end

  defp preview(body) when is_map(body) do
    json = Jason.encode!(body)
    if byte_size(json) > 300, do: String.slice(json, 0, 300) <> "...", else: json
  end

  defp preview(body) when is_binary(body) do
    if String.valid?(body),
      do: if(byte_size(body) > 300, do: String.slice(body, 0, 300) <> "...", else: body),
      else: "(#{byte_size(body)} binary bytes)"
  end

  defp preview(body), do: inspect(body, limit: 300)
end
