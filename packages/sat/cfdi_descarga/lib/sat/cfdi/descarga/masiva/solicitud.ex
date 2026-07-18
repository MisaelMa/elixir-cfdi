defmodule Sat.Cfdi.Descarga.Masiva.Solicitud do
  @moduledoc """
  Servicio `SolicitaDescarga` del WS de Descarga Masiva (v1.5).

  Endpoint: `https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/SolicitaDescargaService.svc`.

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

  @endpoint "https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/SolicitaDescargaService.svc"

  @soap_action_base "http://DescargaMasivaTerceros.sat.gob.mx/ISolicitaDescargaService/"

  @doc """
  Registra una solicitud y retorna el `IdSolicitud`.

  Requiere un token vigente (`Sat.Cfdi.Descarga.Masiva.Autenticacion.autenticar/1`)
  y la FIEL para firmar el sobre SOAP.

  Selecciona la operacion SOAP segun `params.tipo_solicitud`:
    * `:emitidos`  → `SolicitaDescargaEmitidos`
    * `:recibidos` → `SolicitaDescargaRecibidos`
    * `:folio`     → `SolicitaDescargaFolio`

  ## Opciones
    * `:credential` (requerido) — FIEL para firmar.
    * `:endpoint`   — override.
    * `:timeout`    — HTTP timeout.

  ## Retorno

  `{:ok, %SolicitudResult{id_solicitud, cod_estatus, mensaje}}`.

  > ⚠️ **`{:ok, _}` NO significa que el SAT aceptó.** El SAT responde HTTP 200
  > incluso cuando rechaza la petición: el resultado real está en `cod_estatus`.
  > Debes ramificar sobre `cod_estatus`:

  | `cod_estatus` | Significado | Acción |
  |---------------|-------------|--------|
  | `"5000"` | Aceptada | Usa `id_solicitud` para verificar. |
  | `"5002"` | Se agotaron las solicitudes de por vida | Ya hiciste 2 idénticas. Cambia rango/criterios. |
  | `"5005"` | Ya existe una solicitud con esos criterios | Reutiliza el `IdSolicitud` anterior. |
  | `"301"`  | XML Mal Formado / info inválida | RFC inválido, o pediste CFDI sin `estado_comprobante: :vigente` (el SAT no da XML cancelados). |
  | `"303"`  | El sello no corresponde con RfcSolicitante | La FIEL no es del `rfc_solicitante`. |
  | `"304"`/`"305"` | Certificado caduco/revocado/inválido | Revisa la FIEL. |

  Ver la tabla completa en `Sat.Cfdi.Descarga.Masiva`.

  ### Errores (`{:error, reason}`)

  A nivel cliente: `{:missing_option, :credential}`, `{:http_error, status, body}`,
  `{:network_error, reason}`, `{:soap_fault, code, string}`,
  `{:parse_error, :missing_fields, body}`.

  ## Reglas del SAT que provocan rechazo

    * **Límite de por vida**: máximo **2** solicitudes con los MISMOS parámetros
      (mismo RFC + mismo rango). La 3.ª idéntica devuelve `"5002"` permanente.
    * **CFDI cancelados**: para `tipo_solicitud: :recibidos`/`:emitidos`/`:folio`
      con descarga de XML, el SAT **solo entrega vigentes**. Con `:todos`/
      `:cancelado` devuelve `"301"`. Si necesitas cancelados, usa
      `tipo_solicitud: :metadata`.

      > **Red de seguridad (desde 1.5.8):** si el tipo produce `TipoSolicitud="CFDI"`
      > y NO especificas `estado_comprobante`, la librería lo fuerza a `:vigente`
      > automáticamente (igual que phpcfdi), para evitar el `301`. Si lo pones
      > explícito (`:todos`/`:cancelado`) se respeta tu valor. Para `:metadata`
      > no se toca.

  ## Semántica de `fecha_inicial` / `fecha_final` (¡ojo!)

  El rango filtra por la **fecha de EMISIÓN del CFDI** (`fecha de emisión` en el
  timbre), NO por "cuándo lo recibiste" ni por la fecha de certificación. Un CFDI
  aparece si `FechaInicial <= fecha_emision <= FechaFinal`.

  > Si esperabas facturas y la verificación regresa `NumeroCFDIs: 0` /
  > `codigo_estado_solicitud: "5004"`, lo primero a revisar es el **rango de
  > fechas**: que el año/mes sean correctos y que cubran la fecha de emisión de
  > los CFDIs. Es la causa #1 de "recibí facturas pero dice 0". Verifica el rango
  > real en el XML enviado (`<des:solicitud FechaInicial=... FechaFinal=...>`) y
  > compáralo contra el portal del SAT (Consultar facturas) con el mismo RFC.

  ## Respuesta cruda del SAT (HTTP 200)

      <SolicitaDescargaRecibidosResponse xmlns="http://DescargaMasivaTerceros.sat.gob.mx">
        <SolicitaDescargaRecibidosResult
          IdSolicitud="790040c0-1135-4a30-bf03-9cb25f863396"
          RfcSolicitante="MACA961017759" CodEstatus="5000" Mensaje="Solicitud Aceptada"/>
      </SolicitaDescargaRecibidosResponse>

  ## Ejemplo

      case Solicitud.solicitar(token, params, credential: cred) do
        {:ok, %{cod_estatus: "5000", id_solicitud: id}} -> {:ok, id}
        {:ok, %{cod_estatus: "5002"}} -> {:error, :limite_agotado}
        {:ok, %{cod_estatus: cod, mensaje: msg}} -> {:error, {:rechazada, cod, msg}}
        {:error, reason} -> {:error, reason}
      end
  """
  @spec solicitar(Token.t(), SolicitudParams.t(), keyword()) ::
          {:ok, SolicitudResult.t()} | {:error, term()}
  def solicitar(%Token{} = token, %SolicitudParams{} = params, opts \\ []) do
    params = normalizar_params(params)
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

  @cfdi_tipos [:emitidos, :recibidos, :folio, :cfdi]

  @doc false
  # Red de seguridad: en descargas de CFDI (XML) el SAT SOLO entrega vigentes; si
  # no se declara EstadoComprobante, el SAT asume "Todos" y rechaza con 301 ("No
  # se permite la descarga de xml que se encuentren cancelados"). Igual que
  # phpcfdi, forzamos :vigente cuando el tipo produce TipoSolicitud="CFDI" y el
  # llamador no especificó estado. Para :metadata (que sí incluye cancelados) NO
  # se toca. Un estado explícito (:todos/:cancelado) tampoco se toca.
  @spec normalizar_params(SolicitudParams.t()) :: SolicitudParams.t()
  def normalizar_params(%SolicitudParams{estado_comprobante: nil, tipo_solicitud: t} = p)
      when t in @cfdi_tipos do
    %{p | estado_comprobante: :vigente}
  end

  def normalizar_params(%SolicitudParams{} = p), do: p
end
