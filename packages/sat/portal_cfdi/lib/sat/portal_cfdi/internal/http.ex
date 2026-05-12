defmodule Sat.PortalCfdi.Internal.Http do
  @moduledoc false
  # Cliente HTTP del portal SAT con manejo manual de cookies y JA3
  # spoofing via `Browser.Tls`.
  #
  # Por que NO usamos Req/Finch/Mint contra el portal SAT:
  #   El SAT (cfdiau.sat.gob.mx) usa Akamai con bloqueo por JA3 fingerprint.
  #   Cualquier cliente TLS de Erlang/OTP genera un JA3 que NO coincide con
  #   navegadores y termina rechazado con timeout o `:unknown_ca`. Por eso
  #   usamos `Browser.Tls`, un NIF de OpenSSL con ciphers/curves/sigalgs
  #   en el mismo orden que Chrome 131 -> JA3 = Chrome.
  #
  # Manejo manual de cookies/redirects: el NIF devuelve los headers crudos
  # y nosotros parseamos `Set-Cookie` y `Location` para acumular sesion
  # y seguir 3xx.

  alias Browser.Tls
  alias Sat.PortalCfdi.Types.SesionSAT

  @default_timeout 60_000
  @default_profile :chrome

  @doc """
  GET con cookies actuales. Acumula nuevas cookies en la sesion.
  Sigue redirects manualmente preservando cookies entre saltos.
  """
  @spec get(SesionSAT.t(), String.t(), keyword()) ::
          {:ok, %{status: integer(), body: binary(), headers: list(), final_url: String.t()},
           SesionSAT.t()}
          | {:error, term()}
  def get(sesion, url, opts \\ []) do
    request(:get, sesion, url, nil, opts)
  end

  @doc "POST con cookies actuales. Acumula nuevas cookies."
  @spec post(SesionSAT.t(), String.t(), iodata(), keyword()) ::
          {:ok, %{status: integer(), body: binary(), headers: list(), final_url: String.t()},
           SesionSAT.t()}
          | {:error, term()}
  def post(sesion, url, body, opts \\ []) do
    request(:post, sesion, url, body, opts)
  end

  defp request(method, sesion, url, body, opts) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    follow = Keyword.get(opts, :follow_redirects, true)
    max_redirects = Keyword.get(opts, :max_redirects, 10)

    do_request(method, sesion, url, body, timeout, follow, max_redirects, opts)
  end

  defp do_request(_m, _s, _u, _b, _t, _f, 0, _opts) do
    {:error, {:too_many_redirects, "max_redirects reached"}}
  end

  defp do_request(method, sesion, url, body, timeout, follow, redirects_left, opts) do
    headers = build_headers(sesion, opts)
    profile = Keyword.get(opts, :profile, @default_profile)
    label = Keyword.get(opts, :label, "SAT_PORTAL")

    tls_opts = [
      headers: headers,
      profile: profile,
      label: label,
      receive_timeout: timeout
    ]

    tls_opts = if body && method == :post, do: Keyword.put(tls_opts, :body, IO.iodata_to_binary(body)), else: tls_opts
    tls_opts = if proxy = Keyword.get(opts, :proxy), do: Keyword.put(tls_opts, :proxy, proxy), else: tls_opts

    case dispatch(method, url, tls_opts) do
      {:ok, %{status: status, body: rbody, content_type: ct, headers: resp_headers}} ->
        new_sesion = merge_cookies(sesion, resp_headers)
        rbody_bin = body_to_binary(rbody)

        cond do
          follow and status in 300..399 ->
            case header_value(resp_headers, "location") do
              nil ->
                {:ok,
                 %{
                   status: status,
                   body: rbody_bin,
                   headers: resp_headers ++ [{"content-type", ct}],
                   final_url: url
                 }, new_sesion}

              location ->
                next_url = absolute_url(location, url)
                # Tras 3xx, el siguiente request es GET (estandar HTTP).
                # Pasamos el URL actual como Referer — el SAT lo exige
                # para validar el flujo SAML.
                next_opts = put_referer(opts, url)
                do_request(:get, new_sesion, next_url, nil, timeout, follow, redirects_left - 1, next_opts)
            end

          true ->
            {:ok,
             %{
               status: status,
               body: rbody_bin,
               headers: resp_headers ++ [{"content-type", ct}],
               final_url: url
             }, new_sesion}
        end

      {:error, reason} ->
        {:error, {:network_error, %{reason: reason, url: url, prev_url: Keyword.get(opts, :_prev_url)}}}
    end
  rescue
    e -> {:error, {:exception, e}}
  end

  defp put_referer(opts, url) do
    extra = Keyword.get(opts, :extra_headers, [])

    extra_without_referer =
      Enum.reject(extra, fn {k, _} -> String.downcase(to_string(k)) == "referer" end)

    new_extra = [{"referer", url} | extra_without_referer]

    opts
    |> Keyword.put(:extra_headers, new_extra)
    |> Keyword.put(:_prev_url, url)
  end

  defp dispatch(:get, url, opts), do: Tls.get(url, opts)
  defp dispatch(:post, url, opts), do: Tls.post(url, opts)
  defp dispatch(method, _, _), do: {:error, {:unsupported_method, method}}

  defp build_headers(%SesionSAT{cookies: cookies}, opts) do
    base = [
      {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"},
      {"accept-language", "es-MX,es;q=0.9,en;q=0.8"},
      {"accept-encoding", "gzip, deflate"}
    ]

    base =
      if cookie_header(cookies) != "" do
        [{"cookie", cookie_header(cookies)} | base]
      else
        base
      end

    Keyword.get(opts, :extra_headers, []) ++ base
  end

  defp cookie_header(cookies) when is_map(cookies) and map_size(cookies) > 0 do
    cookies
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join("; ")
  end

  defp cookie_header(_), do: ""

  defp merge_cookies(%SesionSAT{cookies: existing} = sesion, headers) do
    existing = existing || %{}

    new =
      headers
      |> Enum.flat_map(fn
        {"set-cookie", v} -> [v]
        _ -> []
      end)
      |> Enum.reduce(existing, fn cookie_str, acc ->
        case parse_set_cookie(cookie_str) do
          {k, v} -> Map.put(acc, k, v)
          :error -> acc
        end
      end)

    %SesionSAT{sesion | cookies: new}
  end

  defp parse_set_cookie(cookie_str) do
    case String.split(cookie_str, ";", parts: 2) do
      [pair | _] ->
        case String.split(pair, "=", parts: 2) do
          [k, v] -> {String.trim(k), String.trim(v)}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp header_value(headers, name) do
    target = String.downcase(name)

    case Enum.find(headers, fn {k, _} -> String.downcase(to_string(k)) == target end) do
      {_, v} -> to_string(v)
      _ -> nil
    end
  end

  defp absolute_url("http" <> _ = abs_url, _), do: abs_url

  defp absolute_url("/" <> _ = path, current) do
    uri = URI.parse(current)
    "#{uri.scheme}://#{uri.host}#{path}"
  end

  defp absolute_url(rel, current) do
    URI.merge(current, rel) |> URI.to_string()
  end

  defp body_to_binary(b) when is_binary(b), do: b
  defp body_to_binary(b) when is_list(b), do: IO.iodata_to_binary(b)
  defp body_to_binary(o), do: to_string(o)
end
