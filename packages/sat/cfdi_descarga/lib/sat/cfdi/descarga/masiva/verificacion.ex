defmodule Sat.Cfdi.Descarga.Masiva.Verificacion do
  @moduledoc """
  Servicio `VerificaSolicitudDescarga` del WS de Descarga Masiva.

  Endpoint: `https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/VerificaSolicitudDescargaService.svc`.

  Consulta el estado de una solicitud previa. Posibles estados:
  `:aceptada` (1), `:en_proceso` (2), `:terminada` (3), `:error` (4),
  `:rechazada` (5), `:vencida` (6).
  Cuando el estado es `:terminada`, la respuesta incluye los `IdsPaquetes`
  listos para descargar.
  """

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.Internal.{Http, Parser, SoapEnvelope}
  alias Sat.Cfdi.Descarga.Masiva.Types.{Token, VerificacionResult}

  @endpoint "https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/VerificaSolicitudDescargaService.svc"
  @soap_action "http://DescargaMasivaTerceros.sat.gob.mx/IVerificaSolicitudDescargaService/VerificaSolicitudDescarga"

  @default_poll_interval_ms 30_000
  @default_max_attempts 60

  @doc """
  Verifica el estado de una solicitud por su `id_solicitud`.

  Opciones:
    * `:credential` (requerido) — FIEL para firmar
    * `:rfc_solicitante` (requerido) — RFC del solicitante
    * `:endpoint` — override
    * `:timeout` — HTTP timeout
  """
  @spec verificar(Token.t(), String.t(), keyword()) ::
          {:ok, VerificacionResult.t()} | {:error, term()}
  def verificar(%Token{} = token, id_solicitud, opts \\ []) when is_binary(id_solicitud) do
    with {:ok, %Credential{} = cred} <- fetch_credential(opts),
         {:ok, rfc} <- fetch_rfc(opts, cred),
         envelope = SoapEnvelope.build_verificacion(cred, rfc, id_solicitud, token.value),
         endpoint = Keyword.get(opts, :endpoint, @endpoint),
         http_opts = Keyword.put(opts, :token, token.value),
         {:ok, %{status: 200, body: body}} <-
           Http.post_soap(endpoint, @soap_action, envelope, http_opts),
         :ok <- Parser.detect_fault(body),
         {:ok, %VerificacionResult{} = result} <- Parser.parse_verificacion(body) do
      {:ok, %{result | id_solicitud: id_solicitud}}
    else
      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, _} = e ->
        e
    end
  end

  @doc """
  Hace polling hasta que la solicitud termine (estado `:terminada`,
  `:error`, `:rechazada` o `:vencida`).

  Opciones extra:
    * `:poll_interval_ms` (default 30_000)
    * `:max_attempts` (default 60 — total maximo ~30 minutos)
  """
  @spec esperar_terminada(Token.t(), String.t(), keyword()) ::
          {:ok, VerificacionResult.t()} | {:error, term()}
  def esperar_terminada(%Token{} = token, id_solicitud, opts \\ []) do
    interval = Keyword.get(opts, :poll_interval_ms, @default_poll_interval_ms)
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)
    poll(token, id_solicitud, opts, interval, max_attempts, 0)
  end

  defp poll(_token, _id, _opts, _interval, max, attempt) when attempt >= max do
    {:error, {:timeout, :max_attempts_reached, max}}
  end

  defp poll(token, id, opts, interval, max, attempt) do
    case verificar(token, id, opts) do
      {:ok, %VerificacionResult{estado_solicitud: estado} = r}
      when estado in [:terminada, :error, :rechazada, :vencida] ->
        {:ok, r}

      {:ok, %VerificacionResult{}} ->
        if attempt + 1 < max do
          Process.sleep(interval)
          poll(token, id, opts, interval, max, attempt + 1)
        else
          {:error, {:timeout, :max_attempts_reached, max}}
        end

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

  defp fetch_rfc(opts, cred) do
    case Keyword.get(opts, :rfc_solicitante) do
      nil -> {:ok, Credential.rfc(cred)}
      rfc when is_binary(rfc) -> {:ok, rfc}
      _ -> {:error, {:invalid_option, :rfc_solicitante}}
    end
  end
end
