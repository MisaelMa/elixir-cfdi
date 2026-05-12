defmodule Sat.WsDescargaMasiva.Autenticacion do
  @moduledoc """
  Servicio `Autentica` del WS de Descarga Masiva.

  Endpoint: `https://cfdidescargamasiva.clouda.sat.gob.mx/Autenticacion/Autenticacion.svc`.

  Genera un sobre SOAP con `wsse:BinarySecurityToken` (FIEL en base64) y
  un `ds:Signature` sobre el `wsu:Timestamp`. El servidor responde con un
  token Bearer valido por 5 minutos.
  """

  alias Sat.Certificados.Credential
  alias Sat.WsDescargaMasiva.Internal.{Http, Parser, SoapEnvelope}
  alias Sat.WsDescargaMasiva.Types.Token

  @endpoint "https://cfdidescargamasiva.clouda.sat.gob.mx/Autenticacion/Autenticacion.svc"
  @soap_action "http://DescargaMasivaTerceros.gob.mx/IAutenticacion/Autentica"

  @doc """
  Solicita un token al servicio `Autentica` firmando con la FIEL del
  solicitante.

  Opciones:
    * `:credential` (requerido) — `Sat.Certificados.Credential.t()`
    * `:endpoint`   — override del endpoint (para testing)
    * `:timeout`    — timeout HTTP (default 30000 ms)
    * `:now`        — DateTime fijo para `Created` (testing/reproducibilidad)
    * `:lifetime_seconds` — duracion del Timestamp (default 300s)
  """
  @spec autenticar(keyword()) :: {:ok, Token.t()} | {:error, term()}
  def autenticar(opts) do
    with {:ok, %Credential{} = cred} <- fetch_credential(opts),
         envelope = SoapEnvelope.build_autenticacion(cred, opts),
         endpoint = Keyword.get(opts, :endpoint, @endpoint),
         {:ok, %{status: 200, body: body}} <-
           Http.post_soap(endpoint, @soap_action, envelope, opts),
         :ok <- Parser.detect_fault(body) do
      Parser.parse_autenticacion(body)
    else
      {:ok, %{status: status, body: body}} ->
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
