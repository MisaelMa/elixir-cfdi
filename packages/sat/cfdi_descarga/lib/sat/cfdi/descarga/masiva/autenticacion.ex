defmodule Sat.Cfdi.Descarga.Masiva.Autenticacion do
  @moduledoc """
  Servicio `Autentica` del WS de Descarga Masiva.

  Endpoint: `https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/Autenticacion/Autenticacion.svc`.

  Genera un sobre SOAP con `wsse:BinarySecurityToken` (FIEL en base64) y
  un `ds:Signature` sobre el `wsu:Timestamp`. El servidor responde con un
  token Bearer valido por 5 minutos.
  """

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.Internal.{Http, Parser, SoapEnvelope}
  alias Sat.Cfdi.Descarga.Masiva.Types.Token

  require Logger

  @endpoint "https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/Autenticacion/Autenticacion.svc"
  @soap_action "http://DescargaMasivaTerceros.gob.mx/IAutenticacion/Autentica"

  @doc """
  Solicita un token al servicio `Autentica` firmando con la FIEL del
  solicitante.

  ## Opciones
    * `:credential` (requerido) — `Sat.Certificados.Credential.t()` (FIEL/e.firma).
    * `:endpoint`   — override del endpoint (para testing).
    * `:timeout`    — timeout HTTP (default 30000 ms).
    * `:now`        — DateTime fijo para `Created` (testing/reproducibilidad).
    * `:lifetime_seconds` — duracion del Timestamp (default 300s).

  ## Retorno

  `{:ok, %Token{value, issued_at, expires_at}}` — el token Bearer es válido
  **5 minutos** (`expires_at`). Reutilízalo en solicitud/verificación/descarga
  dentro de esa ventana; si expira, vuelve a autenticar.

  ### Errores (`{:error, reason}`)
    * `{:missing_option, :credential}` — no pasaste `:credential`.
    * `{:invalid_option, :credential, msg}` — no es un `Credential`.
    * `{:http_error, status, body}` — HTTP != 200.
    * `{:network_error, reason}` — fallo de red.
    * `{:soap_fault, code, string}` — el SAT devolvió un Fault: FIEL no válida,
      certificado que no es FIEL (¿es CSD?), firma inválida, etc.
    * `{:parse_error, :missing_fields, body}` — respuesta sin el token esperado.

  > A diferencia de los demás servicios, aquí un `{:ok, _}` SÍ implica éxito:
  > si la FIEL es inválida el SAT responde con un SOAP Fault → `{:error, ...}`.

  ## Respuesta cruda del SAT (HTTP 200)

      <s:Envelope ...>
        <s:Header>
          <o:Security s:mustUnderstand="1" ...>
            <u:Timestamp u:Id="_0">
              <u:Created>2026-07-01T20:19:58.175Z</u:Created>
              <u:Expires>2026-07-01T20:24:58.175Z</u:Expires>
            </u:Timestamp>
          </o:Security>
        </s:Header>
        <s:Body>
          <AutenticaResponse xmlns="http://DescargaMasivaTerceros.gob.mx">
            <AutenticaResult>eyJhbGciOi...(JWT)...</AutenticaResult>
          </AutenticaResponse>
        </s:Body>
      </s:Envelope>

  `AutenticaResult` → `token.value`; `Created`/`Expires` → `issued_at`/`expires_at`.

  ## Ejemplo

      {:ok, cred} = Sat.Certificados.Credential.create("fiel.cer", "fiel.key", "pass")

      case Autenticacion.autenticar(credential: cred) do
        {:ok, token} -> token.value
        {:error, {:soap_fault, _, msg}} -> {:fiel_invalida, msg}
        {:error, reason} -> {:fallo, reason}
      end
  """
  @spec autenticar(keyword()) :: {:ok, Token.t()} | {:error, term()}
  def autenticar(opts) do
    with {:ok, %Credential{} = cred} <- fetch_credential(opts),
         envelope = SoapEnvelope.build_autenticacion(cred, opts),
         endpoint = Keyword.get(opts, :endpoint, @endpoint),
         {:ok, %{status: 200, body: body} = resp} <-
           Http.post_soap(endpoint, @soap_action, envelope, opts),
         :ok <- Parser.detect_fault(body) do
      Logger.debug("Autenticacion: HTTP 200 OK - #{inspect(resp)}")
      r = Parser.parse_autenticacion(body)
      Logger.debug("Autenticacion: token obtenido - #{inspect(r)}")
      r
    else
      {:ok, %{status: status, body: body} = resp} ->
        Logger.error("Response: #{inspect(resp)}")
        Logger.error("Autenticacion: HTTP error #{status} - #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, _} = e ->
        e
    end
  end

  @doc "Endpoint del servicio de autenticacion."
  def endpoint, do: @endpoint

  @doc "SOAPAction del servicio."
  def soap_action, do: @soap_action

  defp fetch_credential(opts) do
    case Keyword.fetch(opts, :credential) do
      {:ok, %Credential{} = c} -> {:ok, c}
      {:ok, _} -> {:error, {:invalid_option, :credential, "expected Sat.Certificados.Credential"}}
      :error -> {:error, {:missing_option, :credential}}
    end
  end
end
