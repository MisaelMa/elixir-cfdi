# BrowserTLS NIF

Cliente HTTPS para Elixir que usa OpenSSL directamente con **perfiles de navegador configurables** (Chrome, Firefox, Safari). Produce un JA3 TLS fingerprint identico al navegador seleccionado para bypass de proteccion anti-bot (Akamai, Cloudflare, etc.).

## Arquitectura

```
Elixir (Gateways.BrowserTLS)              C NIF (browser_tls.c)
  |                                         |
  | Selecciona perfil (:chrome, :firefox)   |
  | Pasa ciphers/curves/sigalgs como strings|
  |                                         |
  | post(url, json: ..., profile: :chrome)  |
  |---------------------------------------->|
  |                                         | 1. tcp_connect (proxy o directo)
  |                                         | 2. proxy_connect (HTTPS CONNECT tunnel)
  |                                         | 3. create_tls_ctx(ciphers, curves, sigalgs)
  |                                         |    ^ recibe strings desde Elixir
  |                                         | 4. SSL_connect (TLS handshake con JA3 del perfil)
  |                                         | 5. SSL_write (HTTP request)
  |                                         | 6. SSL_read (response completa)
  |                                         | 7. decode_chunked (si aplica)
  |                                         | 8. decompress_gzip (si aplica)
  |                                         |
  |<----------------------------------------|
  | {:ok, status, body, content_type}       |
```

Los perfiles TLS viven en Elixir (`lib/gateways/browser_tls.ex`).
El codigo C es generico — no sabe que navegador esta imitando.
Para actualizar un fingerprint, solo editas Elixir y reinicias. Sin recompilar C.

## Archivos

| Archivo | Descripcion |
|---|---|
| `c_src/browser_tls.c` | NIF en C — HTTP/TLS/proxy/gzip generico |
| `lib/gateways/browser_tls.ex` | Modulo Elixir — perfiles, API publica, diagnostico |
| `priv/browser_tls.so` | Binary compilado (generado por make) |
| `Makefile` | Compila el NIF contra OpenSSL |

## Uso

```elixir
# Default (Chrome)
Gateways.BrowserTLS.post(url, json: body, proxy: proxy)

# Con perfil especifico
Gateways.BrowserTLS.post(url, json: body, proxy: proxy, profile: :firefox)
Gateways.BrowserTLS.get(url, profile: :safari)

# Todos los metodos HTTP soportados
Gateways.BrowserTLS.get(url, opts)
Gateways.BrowserTLS.post(url, opts)
Gateways.BrowserTLS.put(url, opts)
Gateways.BrowserTLS.patch(url, opts)
Gateways.BrowserTLS.delete(url, opts)
Gateways.BrowserTLS.options(url, opts)
Gateways.BrowserTLS.head(url, opts)

# Metodo HTTP arbitrario
Gateways.BrowserTLS.http_request("PROPFIND", url, opts)

# Ver perfiles disponibles
Gateways.BrowserTLS.profiles()
# => [:chrome, :firefox, :safari]
```

## Opciones

| Opcion | Tipo | Default | Descripcion |
|---|---|---|---|
| `json` | map | nil | Body como JSON (auto-agrega Content-Type) |
| `body` | string | "" | Body raw |
| `headers` | list | [] | `[{"key", "value"}]` |
| `proxy` | tuple/nil | nil | `{host, port, user, pass}` |
| `profile` | atom | `:chrome` | Perfil de navegador |
| `label` | string | "BROWSER_TLS" | Label para logs |

## Perfiles de navegador

Los perfiles viven en `lib/gateways/browser_tls.ex` como `@profiles`.
Para actualizar un fingerprint solo editas Elixir — no tocas C.

| Perfil | Navegador | Nota |
|---|---|---|
| `:chrome` | Chrome 131 | Default. Probado contra Akamai en gob.mx |
| `:firefox` | Firefox 133 | Incluye DHE ciphers |
| `:safari` | Safari 18 | ECDSA antes de RSA |

### Agregar o actualizar un perfil

Editar `@profiles` en `lib/gateways/browser_tls.ex`:

```elixir
@profiles %{
  chrome: %{
    name: "Chrome 131",
    ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:...",      # TLS 1.2 (OpenSSL names)
    tls13_ciphers: "TLS_AES_128_GCM_SHA256:...",        # TLS 1.3
    curves: "X25519:P-256:P-384",                        # ECDH curves (OpenSSL names)
    sigalgs: "ECDSA+SHA256:RSA-PSS+SHA256:..."           # Signature algorithms
  },
  # Agregar nuevo perfil — solo Elixir, sin tocar C:
  chrome_135: %{
    name: "Chrome 135",
    ciphers: "...",
    tls13_ciphers: "...",
    curves: "...",
    sigalgs: "..."
  }
}
```

Reiniciar Elixir para que tome el nuevo perfil. **No necesitas `make`.**

## Diagnostico con `diagnose()`

```elixir
Gateways.BrowserTLS.diagnose()           # Chrome
Gateways.BrowserTLS.diagnose(:firefox)   # Firefox
Gateways.BrowserTLS.diagnose(:safari)    # Safari
```

Muestra:
```
====================================
BrowserTLS JA3 Diagnostico
====================================
Perfil:       Chrome 131 (:chrome)
TLS Version:  TLSv1.3
Cipher:       TLS_AES_128_GCM_SHA256
JA3 Hash:     abc123...
JA3 Text:     771,4866-4867-...
====================================
```

## Como saber si te bloquearon

HTTP **428** con body JSON que contiene `"sec-cp-challenge": "true"` = Akamai bloqueo tu JA3.

### Paso a paso para arreglar

1. `Gateways.BrowserTLS.diagnose()` — ver tu JA3 actual
2. Abrir Chrome → visitar `https://tls.browserleaks.com/json` — anotar JA3
3. Comparar. Si son diferentes, actualizar el perfil en `browser_tls.ex`
4. Reiniciar Elixir (**no** necesitas recompilar C)
5. `Gateways.BrowserTLS.diagnose()` — verificar nuevo JA3

### Tabla de cipher IDs (JA3 text → nombre OpenSSL)

| ID | Nombre OpenSSL | TLS |
|---|---|---|
| 4865 | TLS_AES_128_GCM_SHA256 | 1.3 |
| 4866 | TLS_AES_256_GCM_SHA384 | 1.3 |
| 4867 | TLS_CHACHA20_POLY1305_SHA256 | 1.3 |
| 49195 | ECDHE-ECDSA-AES128-GCM-SHA256 | 1.2 |
| 49196 | ECDHE-ECDSA-AES256-GCM-SHA384 | 1.2 |
| 49199 | ECDHE-RSA-AES128-GCM-SHA256 | 1.2 |
| 49200 | ECDHE-RSA-AES256-GCM-SHA384 | 1.2 |
| 52392 | ECDHE-RSA-CHACHA20-POLY1305 | 1.2 |
| 52393 | ECDHE-ECDSA-CHACHA20-POLY1305 | 1.2 |

Referencia completa: https://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml

### Tabla de curve IDs → nombres OpenSSL

| ID | Nombre |
|---|---|
| 29 | X25519 |
| 23 | P-256 |
| 24 | P-384 |
| 25 | P-521 |

## Que es JA3

JA3 fingerprinting identifica clientes TLS por los campos del ClientHello: version, cipher suites, extensions, curves, y point formats. Se hashean con MD5. Los WAF (Akamai, Cloudflare) bloquean JA3 que no reconocen como navegadores.

## Que es un NIF

NIF (Native Implemented Function) = funcion C cargada en la Erlang VM. Se carga al inicio con `@on_load`. Usa dirty IO scheduler para no bloquear. Si el `.so` no existe, el modulo falla con `:nif_not_loaded`. Reiniciar Elixir despues de recompilar.

## Compilacion

```bash
cd apps/gateways
make              # compilar
make clean && make  # limpiar y recompilar
mix compile       # tambien compila automaticamente
```

Requisitos: OpenSSL 3.x, Erlang headers, zlib, make/cc.

## Codigos de error

| Codigo | Significado |
|---|---|
| `request_failed_-1` | No se pudo conectar (DNS o red) |
| `request_failed_-2` | Proxy CONNECT fallo (auth incorrecta) |
| `request_failed_-3` | No se pudo crear SSL context |
| `request_failed_-5` | TLS handshake fallo |
| `request_failed_-6` | SSL_write fallo |

## Lo que ya funciona

| Feature | Estado |
|---|---|
| Perfiles configurables desde Elixir (sin recompilar C) | OK |
| Chrome / Firefox / Safari profiles | OK |
| GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD | OK |
| Metodo HTTP arbitrario (http_request/3) | OK |
| HTTPS CONNECT proxy tunneling | OK |
| gzip / deflate decompression | OK |
| Chunked transfer encoding | OK |
| Binary-safe body (PDF, imagenes) | OK |
| Content-Type devuelto a Elixir | OK |
| SNI (Server Name Indication) | OK |
| TLS 1.2 + TLS 1.3 | OK |
| Dirty IO scheduler | OK |
| Diagnostico JA3 por perfil | OK |
| Compilacion automatica (elixir_make) | OK |

## Posibles mejoras futuras

| Mejora | Prioridad | Nota |
|---|---|---|
| Brotli decompression | Baja | Usar `accept-encoding: gzip, deflate` por ahora |
| Keep-alive / connection pooling | Media | Solo si hay alto trafico |
| Timeout configurable | Baja | Ahora 30s hardcoded |
| HTTP/2 (ALPN h2) | Baja | Requiere parser HTTP/2 en C |
| Request body > 64KB | Baja | Cambiar a enif_inspect_binary |
| Response > 10MB | Baja | Aumentar MAX_RESPONSE |
| Tests automatizados | Media | Test JA3, test proxy, test gzip |
