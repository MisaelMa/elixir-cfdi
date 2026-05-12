defmodule Sat.WsDescargaMasiva.Solicitud do
  @moduledoc """
  Servicio `SolicitaDescarga` del WS de Descarga Masiva.

  Endpoint: `https://cfdidescargamasiva.clouda.sat.gob.mx/SolicitaDescargaService.svc`.

  Registra una solicitud de descarga por rango de fechas, RFC emisor/receptor,
  tipo de comprobante, estado, complemento, UUID, etc. Retorna un
  `IdSolicitud` que se usara despues para verificar el estado.
  """

  alias Sat.Certificados.Credential
  alias Sat.WsDescargaMasiva.Internal.{Http, Parser, SoapEnvelope}
  alias Sat.WsDescargaMasiva.Types.{SolicitudParams, SolicitudResult, Token}

  @endpoint "https://cfdidescargamasiva.clouda.sat.gob.mx/SolicitaDescargaService.svc"
  @soap_action "http://DescargaMasivaTerceros.sat.gob.mx/ISolicitaDescargaService/SolicitaDescarga"

  @doc """
  Registra una solicitud y retorna el `IdSolicitud`.

  Requiere un token vigente (`Sat.WsDescargaMasiva.Autenticacion.autenticar/1`)
  y la FIEL para firmar el sobre SOAP.

  Opciones:
    * `:credential` (requerido) — FIEL para firmar
    * `:endpoint`   — override
    * `:timeout`    — HTTP timeout
  """
  @spec solicitar(Token.t(), SolicitudParams.t(), keyword()) ::
          {:ok, SolicitudResult.t()} | {:error, term()}
  def solicitar(%Token{} = token, %SolicitudParams{} = params, opts \\ []) do
    with {:ok, %Credential{} = cred} <- fetch_credential(opts),
         envelope = SoapEnvelope.build_solicitud(cred, params, token.value),
         endpoint = Keyword.get(opts, :endpoint, @endpoint),
         http_opts = Keyword.put(opts, :token, token.value),
         {:ok, %{status: 200, body: body}} <-
           Http.post_soap(endpoint, @soap_action, envelope, http_opts),
         :ok <- Parser.detect_fault(body) do
      Parser.parse_solicitud(body)
    else
      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, _} = e ->
        e
    end
  end

  @doc "Endpoint del servicio."
  def endpoint, do: @endpoint

  @doc "SOAPAction."
  def soap_action, do: @soap_action

  defp fetch_credential(opts) do
    case Keyword.fetch(opts, :credential) do
      {:ok, %Credential{} = c} -> {:ok, c}
      {:ok, _} -> {:error, {:invalid_option, :credential, "expected Sat.Certificados.Credential"}}
      :error -> {:error, {:missing_option, :credential}}
    end
  end
end
