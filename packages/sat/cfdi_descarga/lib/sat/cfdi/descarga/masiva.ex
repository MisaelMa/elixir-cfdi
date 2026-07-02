defmodule Sat.Cfdi.Descarga.Masiva do
  @moduledoc """
  Web Service de Descarga Masiva del SAT.

  Endpoint base: `https://cfdidescargamasivasolicitud.clouda.sat.gob.mx`.

  El flujo oficial consta de 4 pasos:

    1. **Autenticacion** (`Sat.Cfdi.Descarga.Masiva.Autenticacion`) — obtiene un
       token Bearer firmando con FIEL.
    2. **Solicitud** (`Sat.Cfdi.Descarga.Masiva.Solicitud`) — registra
       una solicitud por rango de fechas, RFC emisor/receptor, tipo, etc.
       Retorna un `IdSolicitud`.
    3. **Verificacion** (`Sat.Cfdi.Descarga.Masiva.Verificacion`) — consulta
       el estado del job (en proceso, terminado, error). Cuando esta listo
       devuelve los `IdsPaquetes` disponibles.
    4. **Paquete** (`Sat.Cfdi.Descarga.Masiva.Paquete`) — descarga cada
       paquete (ZIP base64). El llamador puede extraer XMLs con
       `Sat.Cfdi.Descarga.Masiva.Paquete.Reader`.

  Para el flujo completo sincronico, ver `Sat.Cfdi.Descarga.Masiva.Pipeline`.

  ## Contrato de retorno (IMPORTANTE)

  Todas las funciones publicas devuelven `{:ok, struct}` o `{:error, reason}`.

  > ⚠️ **`{:ok, _}` significa "el SAT respondio HTTP 200", NO "el SAT acepto tu
  > peticion".** Los errores de negocio del SAT (RFC invalido, sin datos, limite
  > de solicitudes, etc.) llegan DENTRO del `{:ok, struct}` como un `cod_estatus`
  > / `estado_solicitud` de error. SIEMPRE revisa esos campos, no solo el `:ok`.

  ### Errores a nivel cliente (`{:error, reason}`)

  Estos ocurren antes o alrededor de la respuesta del SAT:

  | `reason` | Cuando |
  |----------|--------|
  | `{:missing_option, :credential}` | No pasaste `:credential`. |
  | `{:invalid_option, :credential, msg}` | `:credential` no es un `Sat.Certificados.Credential`. |
  | `{:invalid_option, :rfc_solicitante}` | `:rfc_solicitante` no es string. |
  | `{:http_error, status, body}` | El SAT respondio con HTTP != 200. |
  | `{:network_error, reason}` | Fallo de red/conexion (timeout, DNS, TLS). |
  | `{:exception, e}` | Excepcion inesperada en la capa HTTP. |
  | `{:soap_fault, code, string}` | La respuesta fue un SOAP Fault. |
  | `{:parse_error, motivo, body}` | No se pudo parsear la respuesta (body incluido para debug). |
  | `{:timeout, :max_attempts_reached, max}` | `esperar_terminada/3` agoto los intentos de polling. |

  ### Códigos del SAT (dentro del `{:ok, struct}`)

  #### `CodEstatus` — respuesta de `Solicitud` y `Descarga`

  | Código | Significado | Que hacer |
  |--------|-------------|-----------|
  | `5000` | Solicitud recibida con éxito / Aceptada | Continuar (llega `IdSolicitud`). |
  | `5002` | Se agotaron las solicitudes de por vida | Ya hiciste el máx (2) con ESOS mismos parámetros. Cambia el rango/criterios. |
  | `5003` | Tope máximo de elementos de la consulta | Acota el rango de fechas. |
  | `5004` | No se encontró la información | No hay CFDI con esos criterios. No es un bug. |
  | `5005` | Ya existe una solicitud con los mismos criterios | Reutiliza el `IdSolicitud` previo. |
  | `300`  | Usuario No Válido | La FIEL/RFC no está autorizada. |
  | `301`  | XML Mal Formado (información inválida) | RFC inválido, o `EstadoComprobante` que incluye cancelados en descarga de CFDI. Usa `estado_comprobante: :vigente`. |
  | `302`  | Sello Mal Formado | Problema en la firma XML-DSig. |
  | `303`  | El sello no corresponde con el RfcSolicitante | La FIEL no es del `RfcSolicitante`. |
  | `304`  | Certificado Revocado o Caduco | La FIEL venció o fue revocada. |
  | `305`  | Certificado Inválido | Tipo/codificación de certificado incorrecto (¿es CSD en vez de FIEL?). |
  | `404`  | Error no controlado | Reintenta; si persiste, levanta RMA con el SAT. |

  #### `EstadoSolicitud` — `estado_solicitud` de `Verificacion`

  | Valor | Átomo | Significado |
  |-------|-------|-------------|
  | `1` | `:aceptada`  | En espera de ser procesada. |
  | `2` | `:en_proceso`| Generando los paquetes. |
  | `3` | `:terminada` | Lista; `ids_paquetes` ya disponibles. |
  | `4` | `:error`     | Error durante el procesamiento. |
  | `5` | `:rechazada` | Rechazada (mira `codigo_estado_solicitud`, p. ej. `5004` = sin datos). |
  | `6` | `:vencida`   | Venció (los paquetes viven 72 h). |

  #### Códigos extra de `Descarga` (paquete)

  | Código | Significado |
  |--------|-------------|
  | `5007` | No existe el paquete solicitado (vida máx 72 h). |
  | `5008` | Máximo de descargas permitidas (cada paquete solo se descarga 2 veces). |
  """
end
