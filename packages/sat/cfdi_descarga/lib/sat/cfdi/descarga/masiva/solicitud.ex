defmodule Sat.Cfdi.Descarga.Masiva.Solicitud do
  @moduledoc """
  Servicio `SolicitaDescarga` del WS de Descarga Masiva (v1.5).

  Endpoint: `https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/CFDI-descarga-masiva-CSD-SolicitudService/solicitud`.

  Registra una solicitud de descarga por rango de fechas, RFC emisor/receptor,
  tipo de comprobante, estado, complemento, UUID, etc. Retorna un
  `IdSolicitud` que se usara despues para verificar el estado.

  En v1.5 la operacion `SolicitaDescarga` fue reemplazada por tres operaciones:
    * `SolicitaDescargaEmitidos`  — facturas emitidas por el RFC
    * `SolicitaDescargaRecibidos` — facturas recibidas por el RFC
    * `SolicitaDescargaFolio`     — un CFDI especifico por UUID (Folio)

  La funcion `solicitar/3` selecciona automaticamente la operacion correcta
  segun `params.tipo_solicitud` (:emitidos | :recibidos | :folio).
  """

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.Internal.{Http, Parser, SoapEnvelope}
  alias Sat.Cfdi.Descarga.Masiva.Types.{SolicitudParams, SolicitudResult, Token}

  @endpoint "https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/CFDI-descarga-masiva-CSD-SolicitudService/solicitud"

  @soap_action_base "http://DescargaMasivaTerceros.sat.gob.mx/ISolicitaDescargaService/"

  @doc """
  Registra una solicitud y retorna el `IdSolicitud`.

  Requiere un token vigente (`Sat.Cfdi.Descarga.Masiva.Autenticacion.autenticar/1`)
  y la FIEL para firmar el sobre SOAP.

  Selecciona la operacion SOAP segun `params.tipo_solicitud`:
    * `:emitidos`  → `SolicitaDescargaEmitidos`
    * `:recibidos` → `SolicitaDescargaRecibidos`
    * `:folio`     → `SolicitaDescargaFolio`

  Opciones:
    * `:credential` (requerido) — FIEL para firmar
    * `:endpoint`   — override
    * `:timeout`    — HTTP timeout

  IMPORTANTE: El SAT permite maximo 2 solicitudes con los mismos parametros
  (mismo RFC + mismo rango de fechas). La tercera solicitud identica devuelve
  `cod_estatus = "5002"` de forma permanente para esa combinacion.
  """
  @spec solicitar(Token.t(), SolicitudParams.t(), keyword()) ::
          {:ok, SolicitudResult.t()} | {:error, term()}
  def solicitar(%Token{} = token, %SolicitudParams{} = params, opts \\ []) do
    operation = soap_operation(params.tipo_solicitud)
    soap_action = @soap_action_base <> operation

    with {:ok, %Credential{} = cred} <- fetch_credential(opts),
         envelope = SoapEnvelope.build_solicitud(cred, params, token.value, operation),
         endpoint = Keyword.get(opts, :endpoint, @endpoint),
         http_opts = Keyword.put(opts, :token, token.value),
         {:ok, %{status: 200, body: body}} <-
           Http.post_soap(endpoint, soap_action, envelope, http_opts),
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

  @doc "SOAPAction base (sin sufijo de operacion)."
  def soap_action_base, do: @soap_action_base

  @doc "Selecciona la operacion SOAP segun el tipo de solicitud."
  def soap_operation(:emitidos), do: "SolicitaDescargaEmitidos"
  def soap_operation(:recibidos), do: "SolicitaDescargaRecibidos"
  def soap_operation(:folio), do: "SolicitaDescargaFolio"
  def soap_operation(_), do: "SolicitaDescargaEmitidos"

  defp fetch_credential(opts) do
    case Keyword.fetch(opts, :credential) do
      {:ok, %Credential{} = c} -> {:ok, c}
      {:ok, _} -> {:error, {:invalid_option, :credential, "expected Sat.Certificados.Credential"}}
      :error -> {:error, {:missing_option, :credential}}
    end
  end
end
