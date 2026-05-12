defmodule Sat.PortalCfdi.Auth.Ciec do
  @moduledoc """
  Login al portal SAT con CIEC (RFC + contrasena).

  El portal exige resolver un CAPTCHA. Esta libreria NO resuelve captchas
  por si misma — el llamador inyecta un `:captcha_resolver` que recibe los
  bytes de la imagen y devuelve `{:ok, "TEXTO"}` o `{:error, reason}`.

  ## Resolver

  El resolver puede ser:
    * Una llamada manual (mostrar la imagen en consola y leer stdin)
    * Servicios externos (2captcha, AntiCaptcha, DeathByCaptcha)
    * OCR local (Tesseract entrenado)

  ## Endpoints

  El IDP del SAT esta en `https://cfdiau.sat.gob.mx`. El captcha viene de
  `/nidp/app/login?option=credential&sid=0` y se envia en el siguiente POST.
  """

  alias Sat.PortalCfdi.Auth.CaptchaResolver
  alias Sat.PortalCfdi.Internal.{Form, Http}
  alias Sat.PortalCfdi.Types.{CredencialCIEC, SesionSAT}

  @login_url "https://cfdiau.sat.gob.mx/nidp/app/login?id=SATUPCFDiCon&sid=0&option=credential&sid=0"
  @captcha_url "https://cfdiau.sat.gob.mx/nidp/app/login"
  @return_to "https://portalcfdi.facturaelectronica.sat.gob.mx/"

  @type captcha_resolver :: (binary() -> {:ok, String.t()} | {:error, term()})

  @doc """
  Login con CIEC. Retorna una `SesionSAT` autenticada.

  Opciones:
    * `:captcha_resolver` (requerido) — funcion `(image_bytes -> {:ok, text})`
    * `:max_captcha_attempts` (default 3)
  """
  @spec login(CredencialCIEC.t(), keyword()) :: {:ok, SesionSAT.t()} | {:error, term()}
  def login(%CredencialCIEC{rfc: rfc, password: password}, opts) do
    resolver = Keyword.fetch!(opts, :captcha_resolver)
    max_attempts = Keyword.get(opts, :max_captcha_attempts, 3)
    sesion = %SesionSAT{cookies: %{}, authenticated: false, meta: %{}}

    with {:ok, %{body: html}, sesion} <- Http.get(sesion, @login_url, opts) do
      hidden = Form.extract_hidden_inputs(html)
      attempt_login(sesion, hidden, rfc, password, resolver, max_attempts, 1, opts)
    end
  end

  defp attempt_login(_sesion, _hidden, _rfc, _pwd, _resolver, max, attempt, _opts)
       when attempt > max do
    {:error, {:captcha_failed, :max_attempts_reached, max}}
  end

  defp attempt_login(sesion, hidden, rfc, password, resolver, max, attempt, opts) do
    with {:ok, captcha_image, sesion} <- fetch_captcha_image(sesion, opts),
         {:ok, captcha_text} <- CaptchaResolver.dispatch(captcha_image, resolver),
         {:ok, response, sesion} <- post_login(sesion, hidden, rfc, password, captcha_text, opts) do
      case classify_login_response(response) do
        :ok ->
          {:ok, %{sesion | authenticated: true, rfc: rfc, expires_at: thirty_minutes_from_now()}}

        :captcha_invalid ->
          attempt_login(sesion, hidden, rfc, password, resolver, max, attempt + 1, opts)

        {:error, _} = e ->
          e
      end
    end
  end

  defp fetch_captcha_image(sesion, opts) do
    case Http.get(sesion, @captcha_url <> "/captcha.jpg", Keyword.put(opts, :follow_redirects, false)) do
      {:ok, %{status: 200, body: body}, sesion} -> {:ok, body, sesion}
      {:ok, %{status: status}, _} -> {:error, {:captcha_fetch, status}}
      {:error, _} = e -> e
    end
  end

  defp post_login(sesion, hidden, rfc, password, captcha_text, opts) do
    form_params =
      hidden
      |> Map.merge(%{
        "Ecom_User_ID" => rfc,
        "Ecom_Password" => password,
        "userCaptcha" => captcha_text,
        "option" => "credential",
        "submit" => "Enviar"
      })

    body = Form.encode(form_params)

    headers = [
      {"content-type", "application/x-www-form-urlencoded"},
      {"referer", @login_url}
    ]

    Http.post(sesion, @login_url, body, Keyword.put(opts, :extra_headers, headers))
  end

  defp classify_login_response(%{status: 302}), do: :ok
  defp classify_login_response(%{status: 200, body: body}) do
    cond do
      String.contains?(body, "captchaCode") or String.contains?(body, "Codigo no valido") ->
        :captcha_invalid

      String.contains?(body, "Acceso") and String.contains?(body, "denegado") ->
        {:error, :credenciales_invalidas}

      String.contains?(body, "Pagina principal") or String.contains?(body, @return_to) ->
        :ok

      true ->
        {:error, {:respuesta_inesperada, String.slice(body, 0, 200)}}
    end
  end

  defp classify_login_response(%{status: status}), do: {:error, {:http_error, status}}

  defp thirty_minutes_from_now do
    DateTime.add(DateTime.utc_now(), 30 * 60, :second)
  end
end
