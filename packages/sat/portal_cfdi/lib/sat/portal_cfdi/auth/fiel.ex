defmodule Sat.PortalCfdi.Auth.Fiel do
  @moduledoc """
  Login al portal SAT con FIEL (e.firma) via WS-Federation.

  ## Flujo real verificado contra el portal (mayo 2026)

  1. **GET** `https://portalcfdi.facturaelectronica.sat.gob.mx/`
     → 302 a `cfdiau.sat.gob.mx/nidp/wsfed_portalCFDI.jsp?wa=wsignin1.0&wtrealm=...&wctx=...&wct=...&wreply=...`

  2. **GET** al IDP (siguiendo el redirect) → entrega un HTML con un form de
     login. Extraemos los parametros WS-Federation (`wa`, `wctx`, `wreply`,
     `wtrealm`) de la URL del redirect.

  3. **POST** un `wresult` (SAML 1.1 RequestSecurityTokenResponse) firmado
     con FIEL al endpoint `wreply` indicando `wa=wsignin1.0`, `wctx=<original>`,
     `wresult=<xml firmado>`.

  4. El callback responde 302 con cookies de sesion → seguir redirect
     hasta llegar a `portalcfdi.facturaelectronica.sat.gob.mx/`.

  ## Si falla con `:network_error / :timeout`

  La causa mas comun es que `cfdiau.sat.gob.mx` rechaza tu IP por
  geo-bloqueo. Solo IPs mexicanas (o ciertas redes) llegan al IDP. Si tu
  servidor esta en otro pais, considera un proxy mexicano o salir por una
  VPN local.

  Otras causas posibles:
    - El SAT cambio el flujo (1-2 veces por anio). Revisar wsfed_portalCFDI.jsp
    - User-Agent o headers bloqueados.
  """

  alias Sat.Certificados.Credential
  alias Sat.PortalCfdi.Internal.{Form, Http, Saml}
  alias Sat.PortalCfdi.Types.{CredencialFIEL, SesionSAT}

  @portal_url "https://portalcfdi.facturaelectronica.sat.gob.mx/"

  @doc """
  Login con FIEL.

  Acepta una `CredencialFIEL` con paths a `.cer`/`.key` o un
  `:credential` (`Sat.Certificados.Credential`) ya cargado en `opts`.

  Opciones:
    * `:credential` — alternativa a la struct `CredencialFIEL`
    * `:now` — DateTime fijo (testing)
    * `:timeout` — timeout HTTP (default 60_000ms)
  """
  @spec login(CredencialFIEL.t() | nil, keyword()) :: {:ok, SesionSAT.t()} | {:error, term()}
  def login(fiel \\ nil, opts) do
    sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}

    with {:ok, cred} <- resolve_credential(fiel, opts),
         {:ok, idp_response, sesion} <- get_idp_form(sesion, opts),
         {:ok, context} <- extract_wsfed_context(idp_response),
         wresult =
           Saml.build_wresult(cred,
             issuer: context.wtrealm,
             audience: context.wtrealm,
             nonce: random_uuid(),
             now: Keyword.get(opts, :now, DateTime.utc_now())
           ),
         {:ok, response, sesion} <- post_assertion(sesion, context, wresult, opts) do
      classify_response(sesion, response, cred)
    end
  end

  defp resolve_credential(nil, opts) do
    case Keyword.fetch(opts, :credential) do
      {:ok, %Credential{} = c} -> {:ok, c}
      _ -> {:error, {:missing_option, :credential_or_fiel}}
    end
  end

  defp resolve_credential(%CredencialFIEL{certificate_path: cer, private_key_path: key, password: pwd}, _opts) do
    Credential.create(cer, key, pwd)
  end

  defp get_idp_form(sesion, opts) do
    # GET al portal -> 302 a cfdiau (IDP) -> 200 con form HTML.
    # El cliente HTTP ya sigue redirects automaticamente.
    case Http.get(sesion, @portal_url, opts) do
      {:ok, %{status: 200, final_url: idp_url} = resp, sesion} ->
        {:ok, %{resp | final_url: idp_url}, sesion}

      {:ok, %{status: status, body: body}, _} ->
        {:error,
         {:idp_form_unexpected_status, status,
          "esperaba 200 tras seguir redirect a cfdiau.sat.gob.mx, recibio #{status}. " <>
            "Body: #{String.slice(body, 0, 300)}"}}

      {:error, _} = e ->
        e
    end
  end

  defp extract_wsfed_context(%{final_url: idp_url, body: html}) do
    %URI{query: query} = URI.parse(idp_url)
    params = if query, do: URI.decode_query(query), else: %{}

    case {params["wa"], params["wctx"], params["wreply"], params["wtrealm"]} do
      {wa, wctx, wreply, wtrealm}
      when is_binary(wa) and is_binary(wctx) and is_binary(wreply) and is_binary(wtrealm) ->
        # El form de login del IDP a veces tiene su propio `action` y
        # campos hidden que debemos preservar al hacer POST.
        hidden = Form.extract_hidden_inputs(html)
        form_action = extract_form_action(html) || wreply

        {:ok,
         %{
           wa: wa,
           wctx: wctx,
           wreply: wreply,
           wtrealm: wtrealm,
           idp_url: idp_url,
           form_action: form_action,
           hidden: hidden
         }}

      _ ->
        {:error,
         {:wsfed_params_missing,
          "no se encontraron wa/wctx/wreply/wtrealm en #{idp_url}. " <>
            "Es probable que el flujo del IDP haya cambiado."}}
    end
  end

  defp extract_form_action(html) do
    case Regex.run(~r|<form[^>]+action="([^"]+)"|i, html) do
      [_, action] -> action
      _ -> nil
    end
  end

  defp post_assertion(sesion, context, wresult, opts) do
    body =
      Form.encode(
        Map.merge(
          context.hidden,
          %{
            "wa" => context.wa,
            "wresult" => wresult,
            "wctx" => context.wctx
          }
        )
      )

    headers = [
      {"content-type", "application/x-www-form-urlencoded"},
      {"referer", context.idp_url}
    ]

    Http.post(sesion, context.form_action, body, Keyword.put(opts, :extra_headers, headers))
  end

  defp classify_response(sesion, %{status: status, final_url: final_url}, cred)
       when status in [200, 302] do
    if String.contains?(final_url, "portalcfdi.facturaelectronica.sat.gob.mx") do
      {:ok,
       %{
         sesion
         | authenticated: true,
           rfc: Credential.rfc(cred),
           expires_at: DateTime.add(DateTime.utc_now(), 30 * 60, :second)
       }}
    else
      {:error,
       {:login_failed_redirect,
        "el callback no termino en portalcfdi.facturaelectronica.sat.gob.mx. " <>
          "Termino en: #{final_url}"}}
    end
  end

  defp classify_response(_sesion, %{status: status, body: body, final_url: final_url}, _cred) do
    {:error,
     {:login_failed,
      %{
        status: status,
        final_url: final_url,
        body_preview: String.slice(body, 0, 500)
      }}}
  end

  defp random_uuid do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
