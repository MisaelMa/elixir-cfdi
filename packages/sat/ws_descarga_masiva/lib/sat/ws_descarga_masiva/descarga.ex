defmodule Sat.WsDescargaMasiva.Descarga do
  @moduledoc """
  Servicio `DescargaMasivaSolicitudes` del WS de Descarga Masiva.

  Endpoint: `https://cfdidescargamasiva.clouda.sat.gob.mx/DescargaMasivaService.svc`.

  Descarga un paquete por su `id_paquete`. La respuesta contiene el contenido
  del ZIP en base64 dentro del sobre SOAP. Cada paquete puede contener hasta
  10,000 CFDIs.
  """

  alias Sat.Certificados.Credential
  alias Sat.WsDescargaMasiva.Internal.{Http, Parser, SoapEnvelope}
  alias Sat.WsDescargaMasiva.Types.{Paquete, Token}

  @endpoint "https://cfdidescargamasiva.clouda.sat.gob.mx/DescargaMasivaService.svc"
  @soap_action "http://DescargaMasivaTerceros.sat.gob.mx/IDescargaMasivaTercerosService/Descargar"

  @doc """
  Descarga un paquete y devuelve su contenido como bytes ZIP.

  Opciones:
    * `:credential` (requerido) — FIEL
    * `:rfc_solicitante` (requerido si la FIEL no es del solicitante)
    * `:endpoint` — override
    * `:timeout` — HTTP timeout (default 60000 ms para paquetes grandes)
  """
  @spec descargar(Token.t(), String.t(), keyword()) ::
          {:ok, Paquete.t()} | {:error, term()}
  def descargar(%Token{} = token, id_paquete, opts \\ []) when is_binary(id_paquete) do
    opts = Keyword.put_new(opts, :timeout, 60_000)

    with {:ok, %Credential{} = cred} <- fetch_credential(opts),
         {:ok, rfc} <- fetch_rfc(opts, cred),
         envelope = SoapEnvelope.build_descarga(cred, rfc, id_paquete, token.value),
         endpoint = Keyword.get(opts, :endpoint, @endpoint),
         http_opts = Keyword.put(opts, :token, token.value),
         {:ok, %{status: 200, body: body}} <-
           Http.post_soap(endpoint, @soap_action, envelope, http_opts),
         :ok <- Parser.detect_fault(body) do
      Parser.parse_descarga(body, id_paquete)
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

  defp fetch_rfc(opts, cred) do
    case Keyword.get(opts, :rfc_solicitante) do
      nil -> {:ok, Credential.rfc(cred)}
      rfc when is_binary(rfc) -> {:ok, rfc}
      _ -> {:error, {:invalid_option, :rfc_solicitante}}
    end
  end
end
