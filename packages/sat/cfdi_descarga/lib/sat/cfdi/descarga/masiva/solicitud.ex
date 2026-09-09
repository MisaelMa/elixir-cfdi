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
  | `"5001"` | Tercero no autorizado | Tu RFC no es emisor ni receptor de lo que pediste. Ver **Terceros** abajo. |
  | `"5002"` | Se agotaron las solicitudes de por vida | Ya hiciste 2 idénticas. Cambia rango/criterios. |
  | `"5005"` | Ya existe una solicitud con esos criterios | Reutiliza el `IdSolicitud` anterior. |
  | `"301"`  | XML Mal Formado / info inválida | RFC inválido, o pediste CFDI sin `estado_comprobante: :vigente` (el SAT no da XML cancelados). |
  | `"303"`  | El sello no corresponde con RfcSolicitante | La FIEL no es del `rfc_solicitante`. |
  | `"304"`/`"305"` | Certificado caduco/revocado/inválido | Revisa la FIEL. |

  Ver la tabla completa en `Sat.Cfdi.Descarga.Masiva`.

  ### Errores (`{:error, reason}`)

  A nivel cliente: `{:missing_option, :credential}`,
  `{:rfc_ajeno, direccion, rfc_pedido, rfc_solicitante}` (candado local del
  `5001`, ver `validar_rfc_propio/2`), `{:http_error, status, body}`,
  `{:network_error, reason}`, `{:soap_fault, code, string}`,
  `{:parse_error, :missing_fields, body}`.

  ## Reglas del SAT que provocan rechazo

    * **Terceros (`"5001"`)**: `RfcSolicitante` debe ser emisor o receptor de los
      CFDI que pides. La documentación del SAT es explícita: *"Sólo el Emisor o
      Receptor podrán realizar la consulta y recuperación"*. Un contador **no
      puede** descargar los CFDI de un cliente con su propia e.firma — necesita
      la e.firma del cliente (`RfcSolicitante` = RFC del cliente). Lo que sí
      puede es filtrar por contraparte: siendo emisor, `rfc_receptor` (hasta 5);
      siendo receptor, `rfc_emisor`. `validar_rfc_propio/2` corta esto en local.

      > **Ojo:** `rfc_a_cuenta_terceros` (`RfcACuentaTerceros`) NO es un mecanismo
      > de autorización. Es un filtro para el concepto fiscal de CFDI *emitido a
      > cuenta de terceros*. No delega permisos sobre el RFC de nadie.

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
         rfc_solicitante = params.rfc_solicitante || Credential.rfc(cred),
         :ok <- validar_rfc_propio(params, rfc_solicitante),
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

  @doc """
  Candado local contra el `5001` del SAT ("Tercero no autorizado").

  El SAT exige que `RfcSolicitante` **participe** en los CFDI que pides:

  > `rfcSolicitante` debe corresponder con al menos un parametro `rfcEmisor` o
  > `rfcReceptor`. Solo el Emisor o Receptor podran realizar la consulta y
  > recuperacion.

  Un contador NO puede descargar los CFDI de un cliente con su propia e.firma:
  necesita la e.firma del cliente. Ver la nota de terceros en el `@moduledoc`.

  Por eso, segun la direccion, uno de los dos RFC esta clavado a ti y el otro
  queda libre como filtro de contraparte:

  | `tipo_solicitud` | Clavado a ti | Filtro libre |
  |------------------|--------------|--------------|
  | `:emitidos`      | `rfc_emisor`   | `rfc_receptor` (hasta 5 receptores) |
  | `:recibidos`     | `rfc_receptor` | `rfc_emisor` (tu proveedor) |
  | `:folio`         | — (va por UUID) | — |

  Retorna `:ok`, o `{:error, {:rfc_ajeno, direccion, rfc_pedido, rfc_solicitante}}`
  cuando el RFC clavado no es el tuyo. Cortar aqui evita gastar una llamada al
  SAT para que te conteste `5001`.
  """
  @spec validar_rfc_propio(SolicitudParams.t(), String.t()) :: :ok | {:error, term()}
  def validar_rfc_propio(%SolicitudParams{tipo_solicitud: :emitidos, rfc_emisor: rfc}, solicitante)
      when is_binary(rfc) do
    verificar_mismo_rfc(rfc, solicitante, :emitidos)
  end

  def validar_rfc_propio(
        %SolicitudParams{tipo_solicitud: :recibidos, rfc_receptor: rfc},
        solicitante
      )
      when is_binary(rfc) do
    verificar_mismo_rfc(rfc, solicitante, :recibidos)
  end

  def validar_rfc_propio(%SolicitudParams{}, _solicitante), do: :ok

  defp verificar_mismo_rfc(rfc, solicitante, direccion) do
    if normalizar_rfc(rfc) == normalizar_rfc(solicitante) do
      :ok
    else
      {:error, {:rfc_ajeno, direccion, rfc, solicitante}}
    end
  end

  defp normalizar_rfc(rfc) when is_binary(rfc), do: rfc |> String.trim() |> String.upcase()
  defp normalizar_rfc(rfc), do: rfc

  defp fetch_credential(opts) do
    case Keyword.fetch(opts, :credential) do
      {:ok, %Credential{} = c} -> {:ok, c}
      {:ok, _} -> {:error, {:invalid_option, :credential, "expected Sat.Certificados.Credential"}}
      :error -> {:error, {:missing_option, :credential}}
    end
  end

  @doc false
  # Normaliza params: (1) infiere `tipo_descarga` si no vino (retrocompat con el
  # `tipo_solicitud` legacy que mezclaba :cfdi/:metadata), (2) red de seguridad:
  # en descargas de CFDI (XML) el SAT SOLO entrega vigentes; si no se declara
  # EstadoComprobante, el SAT asume "Todos" y rechaza con 301. Como phpcfdi,
  # forzamos :vigente cuando `tipo_descarga: :cfdi` y no hay estado. Para
  # :metadata (que sí incluye cancelados) NO se toca. Estado explícito tampoco.
  @spec normalizar_params(SolicitudParams.t()) :: SolicitudParams.t()
  def normalizar_params(%SolicitudParams{} = p) do
    p
    |> inferir_tipo_descarga()
    |> forzar_vigente_para_cfdi()
  end

  # Legacy: si el llamador puso `tipo_solicitud: :metadata` (viejo estilo) y no
  # especificó `tipo_descarga`, lo tomamos como metadata. Cualquier otro → :cfdi.
  defp inferir_tipo_descarga(%SolicitudParams{tipo_descarga: nil, tipo_solicitud: :metadata} = p),
    do: %{p | tipo_descarga: :metadata}

  defp inferir_tipo_descarga(%SolicitudParams{tipo_descarga: nil} = p),
    do: %{p | tipo_descarga: :cfdi}

  defp inferir_tipo_descarga(%SolicitudParams{} = p), do: p

  defp forzar_vigente_para_cfdi(
         %SolicitudParams{estado_comprobante: nil, tipo_descarga: :cfdi} = p
       ),
       do: %{p | estado_comprobante: :vigente}

  defp forzar_vigente_para_cfdi(%SolicitudParams{} = p), do: p
end
