# sat_cfdi_descarga

Cliente Elixir para el **Web Service de Descarga Masiva de CFDI** del SAT (v1.5).

Implementa el flujo oficial de 4 pasos: autenticación con FIEL → solicitud de descarga → verificación de estado → descarga de paquetes ZIP.

---

## Documentación oficial SAT

| Documento | Descripción |
|-----------|-------------|
| [Especificación técnica Descarga Masiva v1.5](https://www.sat.gob.mx/cs/Satellite?blobcol=urldata&blobkey=id&blobtable=MungoBlobs&blobwhere=1461174995051&ssbinary=true) | Especificación completa del WS: operaciones, SOAP envelopes, firma XML-DSig, códigos de estado |
| [Servicio de Solicitud](https://www.sat.gob.mx/cs/Satellite?blobcol=urldata&blobkey=id&blobtable=MungoBlobs&blobwhere=1461175195160&ssbinary=true) | Detalles de implementación del servicio `SolicitaDescarga` |
| [Servicio de Verificación](https://www.sat.gob.mx/cs/Satellite?blobcol=urldata&blobkey=id&blobtable=MungoBlobs&blobwhere=1461175779527) | Detalles del servicio `VerificaSolicitudDescarga` |

### WSDL de los servicios

```
# Autenticación
https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/CFDI-descarga-masiva-CSD-AuthService/autenticacion?wsdl

# Solicitud
https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/CFDI-descarga-masiva-CSD-SolicitudService/solicitud?wsdl

# Verificación
https://cfdidescargamasivasolicitud.clouda.sat.gob.mx/CFDI-descarga-masiva-CSD-ConsultaService/verificacion?wsdl

# Descarga
https://cfdidescargamasivadescarga.clouda.sat.gob.mx/CFDI-descarga-masiva-CSD-DescargaService/descarga?wsdl
```

---

## Instalación

```elixir
# mix.exs
{:sat_cfdi_descarga, "~> 1.5"}
```

Dependencias requeridas: `sat_certificados` (para manejar la FIEL).

---

## Prerequisitos

Necesitas una **FIEL vigente** (`.cer` + `.key` + contraseña). El SAT la llama _e.firma_.

```elixir
{:ok, cred} = Sat.Certificados.Credential.create("fiel.cer", "fiel.key", "mi_contrasena")
```

---

## Flujo de Descarga Masiva

El WS tiene 4 pasos obligatorios y secuenciales. Cada paso depende del resultado del anterior.

```
[1] Autenticacion  →  token (válido 5 min)
        │
        ▼
[2] Solicitud      →  id_solicitud
        │
        ▼
[3] Verificacion   →  ids_paquetes  (polling hasta que el SAT termine de procesar)
        │
        ▼
[4] Paquete        →  ZIP binary    (uno por cada id_paquete)
        │
        ▼
    Paquete.Reader  →  XMLs / metadata
```

### Paso 1 — Autenticación

Firma un `wsu:Timestamp` con la FIEL y obtiene un token Bearer válido por **5 minutos**.

```elixir
alias Sat.Cfdi.Descarga.Masiva.Autenticacion

{:ok, token} = Autenticacion.autenticar(credential: cred)
# token.value      → "eyJhbGci..."
# token.issued_at  → ~U[2025-01-01 00:00:00Z]
# token.expires_at → ~U[2025-01-01 00:05:00Z]
```

El token debe usarse en los pasos 2, 3 y 4. Si expira, repetir este paso.

> **Producción con Oban:** reautenticar al inicio de cada worker o verificar
> `token.expires_at` antes de usarlo.

---

### Paso 2 — Solicitud de descarga

Registra una solicitud de descarga. El SAT retorna un `id_solicitud` que se usa en la verificación.

```elixir
alias Sat.Cfdi.Descarga.Masiva.Solicitud
alias Sat.Cfdi.Descarga.Masiva.Types.SolicitudParams

params = %SolicitudParams{
  rfc_solicitante: "AAA010101AAA",
  fecha_inicial:   ~U[2025-01-01 00:00:00Z],
  fecha_final:     ~U[2025-01-31 23:59:59Z],
  tipo_solicitud:  :cfdi       # :cfdi | :metadata
}

{:ok, resultado} = Solicitud.solicitar(token, params, credential: cred)
# resultado.id_solicitud  → "b6ace7b1-9e39-4cdb-a9c6-7b9f6c7a2e1a"
# resultado.cod_estatus   → "5000"  (aceptada)
# resultado.mensaje       → "Solicitud Aceptada"
```

#### Tipos de solicitud (v1.5)

La operación SOAP se selecciona automáticamente según `tipo_solicitud`:

| `tipo_solicitud` | Operación SOAP | Descripción |
|---|---|---|
| `:emitidos` | `SolicitaDescargaEmitidos` | CFDIs emitidos por el RFC solicitante |
| `:recibidos` | `SolicitaDescargaRecibidos` | CFDIs recibidos por el RFC solicitante |
| `:folio` | `SolicitaDescargaFolio` | Un CFDI específico por UUID |
| `:cfdi` / `:metadata` | `SolicitaDescargaEmitidos` | Fallback (compatibilidad) |

#### Parámetros opcionales de `SolicitudParams`

| Campo | Tipo | Descripción |
|---|---|---|
| `rfc_emisor` | `String` | Filtra por RFC del emisor |
| `rfc_receptor` | `String \| [String]` | Filtra por RFC(s) del receptor |
| `tipo_comprobante` | `:i \| :e \| :t \| :n \| :p \| :null` | I=Ingreso, E=Egreso, T=Traslado, N=Nómina, P=Pago |
| `estado_comprobante` | `:todos \| :vigente \| :cancelado` | Estado del CFDI |
| `complemento` | `String` | Clave del complemento (p.ej. `"nomina12"`) |
| `uuid` | `String` | UUID específico (para solicitud tipo `:folio`) |
| `rfc_a_cuenta_terceros` | `String` | RFC a cuenta de terceros |

> **Límite SAT:** máximo **2 solicitudes con los mismos parámetros** (mismo RFC + rango de fechas).
> La tercera solicitud idéntica retorna `cod_estatus = "5002"` de forma permanente.

#### Códigos de estado en la solicitud

| Código | Significado |
|---|---|
| `5000` | Solicitud aceptada |
| `5002` | Solicitud duplicada (límite alcanzado) |
| `5004` | Sin comprobantes para los parámetros dados |
| `5005` | RFC no autorizado |

---

### Paso 3 — Verificación

Consulta el estado de la solicitud. El SAT procesa en background; puede tomar desde segundos hasta minutos dependiendo del volumen.

#### Verificación simple (un intento)

```elixir
alias Sat.Cfdi.Descarga.Masiva.Verificacion

{:ok, resultado} = Verificacion.verificar(token, id_solicitud, credential: cred)
# resultado.estado_solicitud         → :en_proceso | :terminada | :error | ...
# resultado.ids_paquetes             → ["PKG_AAA_01", "PKG_AAA_02"]
# resultado.numero_cfdis             → 1500
# resultado.codigo_estado_solicitud  → "5000"
```

#### Verificación con polling (flujo sincrónico)

```elixir
{:ok, resultado} = Verificacion.esperar_terminada(token, id_solicitud,
  credential:       cred,
  poll_interval_ms: 30_000,   # default: 30 segundos
  max_attempts:     60        # default: 60 intentos (~30 minutos máximo)
)

ids_paquetes = resultado.ids_paquetes
# ["PKG_AAA_01", "PKG_AAA_02", ...]
```

#### Estados de la solicitud

| Código | Átomo | Descripción |
|---|---|---|
| `1` | `:aceptada` | Solicitud recibida, pendiente de procesar |
| `2` | `:en_proceso` | El SAT está generando los paquetes |
| `3` | `:terminada` | Paquetes listos para descargar |
| `4` | `:error` | Error interno del SAT |
| `5` | `:rechazada` | Solicitud rechazada |
| `6` | `:vencida` | Solicitud expirada (no descargada a tiempo) |

Solo cuando el estado es `:terminada` el campo `ids_paquetes` contiene valores.

> **Producción con Oban:** no usar `esperar_terminada/3`. Crear un worker que llame
> `verificar/3` y se re-encole si el estado es `:en_proceso` o `:aceptada`.

---

### Paso 4 — Descarga de paquetes

Descarga cada paquete como ZIP en bytes. Cada paquete contiene hasta **10,000 CFDIs**.

```elixir
alias Sat.Cfdi.Descarga.Masiva.Paquete

Enum.each(ids_paquetes, fn id_paquete ->
  {:ok, paquete} = Paquete.descargar(token, id_paquete, credential: cred)
  # paquete.id       → "PKG_AAA_01"
  # paquete.content  → <<80, 75, 3, 4, ...>>  (ZIP binary)
  # paquete.size     → 2_048_000
end)
```

---

### Lectura de paquetes

Una vez descargado el ZIP, `Paquete.Reader` lo extrae en memoria sin escribir al filesystem.

#### CFDIs (tipo `:cfdi`)

```elixir
alias Sat.Cfdi.Descarga.Masiva.Paquete.Reader

{:ok, stream} = Paquete.Reader.stream_cfdis(paquete)

stream
|> Stream.each(fn {filename, xml} ->
  File.write!("output/#{filename}", xml)
end)
|> Stream.run()
```

#### Metadata (tipo `:metadata`)

```elixir
{:ok, filas} = Paquete.Reader.parse_metadata(paquete)

# filas → [
#   %{uuid: "...", rfcemisor: "AAA...", rfcreceptor: "BBB...", total: "1500.00", ...},
#   ...
# ]
```

#### Listar archivos del ZIP (debug)

```elixir
{:ok, nombres} = Paquete.Reader.list_files(paquete)
# ["uuid1.xml", "uuid2.xml", ...]
```

---

## Flujo completo de ejemplo

```elixir
alias Sat.Cfdi.Descarga.Masiva.{Autenticacion, Solicitud, Verificacion, Paquete}
alias Sat.Cfdi.Descarga.Masiva.Paquete.Reader
alias Sat.Cfdi.Descarga.Masiva.Types.SolicitudParams

{:ok, cred} = Sat.Certificados.Credential.create("fiel.cer", "fiel.key", "contrasena")

params = %SolicitudParams{
  rfc_solicitante: "AAA010101AAA",
  fecha_inicial:   ~U[2025-01-01 00:00:00Z],
  fecha_final:     ~U[2025-01-31 23:59:59Z],
  tipo_solicitud:  :cfdi
}

# 1. Autenticar
{:ok, token} = Autenticacion.autenticar(credential: cred)

# 2. Solicitar
{:ok, %{id_solicitud: id_sol, cod_estatus: "5000"}} =
  Solicitud.solicitar(token, params, credential: cred)

# 3. Verificar con polling
{:ok, %{ids_paquetes: ids}} =
  Verificacion.esperar_terminada(token, id_sol, credential: cred)

# 4. Descargar y extraer
Enum.each(ids, fn id ->
  {:ok, paquete} = Paquete.descargar(token, id, credential: cred)
  {:ok, stream}  = Paquete.Reader.stream_cfdis(paquete)

  Enum.each(stream, fn {filename, xml} ->
    File.write!("output/#{filename}", xml)
  end)
end)
```

---

## Pipeline sincrónico (`Masiva.Pipeline`)

Para scripts o herramientas CLI donde no se necesita control paso a paso:

```elixir
alias Sat.Cfdi.Descarga.Masiva.Pipeline

# Stream lazy — no carga todo en memoria
Pipeline.stream_xml(params, credential: cred)
|> Stream.each(fn
  {:ok, {filename, xml}} -> File.write!("output/#{filename}", xml)
  {:error, reason}       -> IO.warn("Error: #{inspect(reason)}")
end)
|> Stream.run()

# Lista completa (solo para volúmenes pequeños < 10,000 CFDIs)
{:ok, xmls} = Pipeline.listar_xml(params, credential: cred)

# Metadata
{:ok, filas} = Pipeline.listar_metadata(params, credential: cred)
```

> **Nota:** En producción con Oban usar los módulos primitivos directamente
> (`Autenticacion`, `Solicitud`, `Verificacion`, `Paquete`), no `Pipeline`.
> Oban provee retry por paso, visibilidad de estado y no bloquea un proceso
> durante el polling de verificación.

---

## Estructura del paquete

```
Sat.Cfdi.Descarga                          # entry point / version
└── Sat.Cfdi.Descarga.Masiva               # WS Descarga Masiva
    ├── Autenticacion                      # Paso 1: token FIEL
    ├── Solicitud                          # Paso 2: registrar solicitud
    ├── Verificacion                       # Paso 3: consultar estado (+ polling)
    ├── Paquete                            # Paso 4: descargar ZIP
    ├── Paquete.Reader                      # Extraer XMLs / metadata del ZIP
    ├── Pipeline                           # Flujo completo sincrónico
    ├── Types                              # Structs: Token, SolicitudParams, etc.
    └── Internal.*                         # SOAP, HTTP, XMLDSig (privado)
```

---

## Licencia

MIT
