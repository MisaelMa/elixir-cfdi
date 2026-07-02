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

  ## Opciones
    * `:credential` (requerido) — FIEL para firmar.
    * `:rfc_solicitante` — RFC del solicitante (default: el del certificado).
    * `:endpoint` — override.
    * `:timeout` — HTTP timeout.

  ## Retorno

  `{:ok, %VerificacionResult{estado_solicitud, codigo_estado_solicitud,
  numero_cfdis, mensaje, ids_paquetes, id_solicitud}}`.

  El campo clave es `estado_solicitud` (átomo):

  | Átomo | `EstadoSolicitud` | Significado | ¿Terminal? |
  |-------|-------------------|-------------|------------|
  | `:aceptada`   | 1 | En espera de procesar. | No, sigue haciendo polling. |
  | `:en_proceso` | 2 | Generando paquetes.    | No, sigue haciendo polling. |
  | `:terminada`  | 3 | Lista; `ids_paquetes` disponibles. | **Sí** → descargar. |
  | `:error`      | 4 | Error del SAT.          | **Sí**. |
  | `:rechazada`  | 5 | Rechazada.              | **Sí**. |
  | `:vencida`    | 6 | Venció (paquetes viven 72 h). | **Sí**. |

  `codigo_estado_solicitud` (string) da el detalle, sobre todo si `:rechazada`:

  | Código | Significado |
  |--------|-------------|
  | `"5000"` | Solicitud recibida con éxito. |
  | `"5002"` | Se agotaron las solicitudes de por vida. |
  | `"5003"` | Tope máximo de elementos. |
  | `"5004"` | **No se encontró la información** — no hay CFDI con esos criterios. Suele venir con `estado_solicitud: :rechazada` y `numero_cfdis: 0`. **No es un bug.** Causa #1: el **rango de fechas** no cubre la *fecha de emisión* de los CFDIs (año/mes equivocado); causa #2: los CFDIs están cancelados y filtraste `:vigente`. Revisa el `<des:solicitud FechaInicial=... FechaFinal=...>` enviado vs. el portal del SAT. |
  | `"5005"` | Solicitud duplicada. |

  `ids_paquetes` solo trae elementos cuando `estado_solicitud == :terminada`.

  ### Errores (`{:error, reason}`)

  `{:missing_option, :credential}`, `{:http_error, status, body}`,
  `{:network_error, reason}`, `{:soap_fault, code, string}`,
  `{:parse_error, :missing_fields, body}`.

  ## Respuesta cruda del SAT (HTTP 200) y mapeo a `VerificacionResult`

  El cuerpo relevante es el elemento `<VerificaSolicitudDescargaResult>`. Cada
  atributo/hijo se mapea así:

  | XML | Campo del struct | Nota |
  |-----|------------------|------|
  | `EstadoSolicitud="3"` | `estado_solicitud` | Se convierte al átomo (`3` → `:terminada`). |
  | `CodigoEstadoSolicitud="5000"` | `codigo_estado_solicitud` | String tal cual. |
  | `NumeroCFDIs="35"` | `numero_cfdis` | Entero. |
  | `Mensaje="..."` | `mensaje` | String. |
  | `CodEstatus="5000"` | — | Estatus de la *petición de verificación* (no de la solicitud). |
  | `<IdsPaquetes>...</IdsPaquetes>` | `ids_paquetes` | Lista; solo llega si `:terminada`. |

  ### Ejemplo TERMINADA (hay paquetes para descargar)

      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
        <s:Body>
          <VerificaSolicitudDescargaResponse xmlns="http://DescargaMasivaTerceros.sat.gob.mx">
            <VerificaSolicitudDescargaResult CodEstatus="5000" EstadoSolicitud="3"
              CodigoEstadoSolicitud="5000" NumeroCFDIs="35" Mensaje="Solicitud Aceptada">
              <IdsPaquetes>790040c0-1135-4a30-bf03-9cb25f863396_01</IdsPaquetes>
            </VerificaSolicitudDescargaResult>
          </VerificaSolicitudDescargaResponse>
        </s:Body>
      </s:Envelope>

  → `%VerificacionResult{estado_solicitud: :terminada, codigo_estado_solicitud: "5000",
  numero_cfdis: 35, ids_paquetes: ["790040c0-...-_01"], mensaje: "Solicitud Aceptada"}`

  ### Ejemplo RECHAZADA sin datos (respuesta real del SAT)

      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
        <s:Body>
          <VerificaSolicitudDescargaResponse xmlns="http://DescargaMasivaTerceros.sat.gob.mx">
            <VerificaSolicitudDescargaResult CodEstatus="5000" EstadoSolicitud="5"
              CodigoEstadoSolicitud="5004" NumeroCFDIs="0" Mensaje="Solicitud Aceptada"/>
          </VerificaSolicitudDescargaResponse>
        </s:Body>
      </s:Envelope>

  → `%VerificacionResult{estado_solicitud: :rechazada, codigo_estado_solicitud: "5004",
  numero_cfdis: 0, ids_paquetes: [], mensaje: "Solicitud Aceptada"}`

  Nota: `CodEstatus="5000"` + `Mensaje="Solicitud Aceptada"` se refieren a que la
  *consulta de verificación* fue procesada, NO a que la *solicitud* tenga datos.
  El estado real de la solicitud está en `estado_solicitud` +
  `codigo_estado_solicitud` (aquí `:rechazada` / `"5004"` = sin CFDIs).

  ## Ejemplo

      case Verificacion.verificar(token, id, credential: cred) do
        {:ok, %{estado_solicitud: :terminada, ids_paquetes: ids}} -> {:ok, ids}
        {:ok, %{estado_solicitud: e}} when e in [:aceptada, :en_proceso] -> :en_proceso
        {:ok, %{estado_solicitud: :rechazada, codigo_estado_solicitud: "5004"}} -> {:ok, []}
        {:ok, %{codigo_estado_solicitud: cod}} -> {:error, {:rechazada, cod}}
        {:error, reason} -> {:error, reason}
      end
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
  Hace polling llamando a `verificar/3` hasta que la solicitud llegue a un
  estado **terminal**: `:terminada`, `:error`, `:rechazada` o `:vencida`.

  ## Opciones extra
    * `:poll_interval_ms` (default 30_000) — espera entre intentos.
    * `:max_attempts` (default 60 — total máximo ~30 minutos).
    * (más las mismas de `verificar/3`: `:credential`, `:rfc_solicitante`, …).

  ## Retorno

    * `{:ok, %VerificacionResult{}}` con un `estado_solicitud` terminal. **Ojo:
      terminal NO implica éxito** — `:rechazada`/`:error`/`:vencida` también
      terminan el polling. Revisa `estado_solicitud` y `codigo_estado_solicitud`
      (p. ej. `:rechazada` + `"5004"` = sin datos).
    * `{:error, {:timeout, :max_attempts_reached, max}}` — se agotaron los
      intentos y la solicitud seguía en `:aceptada`/`:en_proceso`. Reintenta más
      tarde o sube `:max_attempts`.
    * cualquier `{:error, reason}` que devuelva `verificar/3`.

  ## Ejemplo

      case Verificacion.esperar_terminada(token, id, credential: cred, max_attempts: 20) do
        {:ok, %{estado_solicitud: :terminada, ids_paquetes: ids}} -> descargar(ids)
        {:ok, %{estado_solicitud: :rechazada, codigo_estado_solicitud: "5004"}} -> :sin_datos
        {:ok, %{estado_solicitud: estado}} -> {:error, {:no_terminada, estado}}
        {:error, {:timeout, _, _}} -> {:error, :sigue_en_proceso}
        {:error, reason} -> {:error, reason}
      end
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
