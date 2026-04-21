# Monorepo Patterns

Patrones de estructura, configuración y publicación para proyectos
Elixir con múltiples paquetes.

## Layouts soportados

### Umbrella (estándar de Elixir)

```
mi_umbrella/
├── mix.exs
├── apps/
│   ├── core/
│   │   ├── mix.exs          # app: :core
│   │   ├── lib/
│   │   └── test/
│   ├── api/
│   │   ├── mix.exs          # app: :api, depends on :core
│   │   ├── lib/
│   │   └── test/
│   └── worker/
│       ├── mix.exs          # app: :worker, depends on :core
│       ├── lib/
│       └── test/
```

Deps entre apps (Releaser detecta ambas formas automáticamente):

```elixir
# apps/api/mix.exs
defp deps do
  [{:core, in_umbrella: true}]      # umbrella estándar ✓
  # ó
  [{:core, path: "../core"}]        # path explícito ✓
end
```

### Poncho (agrupado por dominio)

```
mi_proyecto/
├── mix.exs
├── apps/
│   ├── cfdi/                        ← grupo (no tiene mix.exs)
│   │   ├── xml/mix.exs
│   │   ├── csd/mix.exs
│   │   └── complementos/mix.exs
│   ├── sat/
│   │   ├── auth/mix.exs
│   │   └── pacs/mix.exs
│   └── clir/
│       ├── openssl/mix.exs
│       └── saxon_he/mix.exs
```

Deps entre apps:

```elixir
# apps/cfdi/xml/mix.exs
defp deps do
  [
    {:cfdi_csd, path: "../csd"},                  # mismo grupo
    {:saxon_he, path: "../../clir/saxon_he"},     # otro grupo
    {:saxy, "~> 1.5"}                             # Hex externo
  ]
end
```

### Proyecto single

```
mi_libreria/
├── mix.exs
├── lib/
└── test/
```

```elixir
releaser: [apps_root: "."]
```

Releaser detecta el único `mix.exs` y funciona para bump, changelog y
publish sin cascade (no hay dependientes).

## Publish policy

### Configuración por app

Cada app decide si es publicable con `releaser: [publish: true]` en su `mix.exs`:

```elixir
# apps/cfdi/xml/mix.exs — SE PUBLICA
def project do
  [
    app: :cfdi_xml,
    version: "4.0.18",
    description: "XML builder para CFDI",
    releaser: [publish: true]
  ]
end

# apps/sat/scraper/mix.exs — NO SE PUBLICA (privado)
def project do
  [
    app: :sat_scraper,
    version: "0.0.1"
    # sin releaser → privado
  ]
end
```

### Qué controla `publish: true`

```
                    ┌──────────────┬──────────────┐
                    │ publish: true│ sin publish   │
┌───────────────────┼──────────────┼──────────────┤
│ mix releaser.bump │ Recibe       │ NO recibe    │
│ (cascade)         │ cascade bump │ cascade bump │
├───────────────────┼──────────────┼──────────────┤
│ mix releaser      │ Se publica   │ NO se publica│
│ .publish          │ a Hex        │              │
├───────────────────┼──────────────┼──────────────┤
│ mix releaser      │ ahead /      │ "private"    │
│ .status           │ published    │              │
├───────────────────┼──────────────┼──────────────┤
│ mix releaser      │ ✓ aparece    │ ✓ aparece    │
│ .graph            │              │              │
├───────────────────┼──────────────┼──────────────┤
│ mix releaser.bump │ ✓ aparece    │ ✓ aparece    │
│ --list            │              │              │
└───────────────────┴──────────────┴──────────────┘
```

### Cómo se resuelven las deps al publicar

Cuando un app publicable depende de uno no-publicable:

```
cfdi_xml (publish: true)
  └─ depends on: cfdi_transform (NO publish)
```

Al publicar `cfdi_xml`, Releaser reemplaza:
```elixir
{:cfdi_transform, path: "../transform"}
→
{:cfdi_transform, "~> 4.0"}
```

Hex resuelve `~> 4.0` contra la versión que **ya está publicada** en Hex
(por ejemplo `4.0.14`). No intenta publicar `transform`.

Esto funciona siempre que:
1. `cfdi_transform` alguna vez se publicó a Hex, **o**
2. `cfdi_transform` es una dep externa (ya está en Hex por otro proyecto)

Si nunca se publicó y no existe en Hex, la publicación de `cfdi_xml` fallará
con un error de Hex diciendo que no encuentra el paquete.

### Dirección de cascade y publish

```
                    DEPENDENCIAS (hacia abajo)
                    Lo que mi app CONSUME
                    ┌─────────────┐
                    │ clir_openssl│  ← no se republica
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │  cfdi_csd   │  ← YO MODIFIQUÉ ESTO
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────┴──────┐    │     ┌──────┴──────┐
       │  cfdi_xml   │    │     │  sat_auth   │  ← solo si publish: true
       └─────────────┘    │     └──────┬──────┘
                          │            │
                    DEPENDIENTES (hacia arriba)
                    Quienes USAN mi app
                    Se republican automáticamente
```

Al hacer `mix releaser.bump cfdi_csd patch`:
- **Hacia abajo** (clir_openssl): NO se toca, ya está en Hex
- **Hacia arriba** (cfdi_xml, sat_auth): cascade bump + se republican
- Solo si tienen `publish: true`

## Flujo de dependencias entre publicables y privados

### Ejemplo real: 34 paquetes

```
╔═══════════════════════════════════════════════════════╗
║ Apps publicables (publish: true)                      ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  Level 0:  clir_openssl, cfdi_catalogos,              ║
║            cfdi_complementos, saxon_he                 ║
║               │                                       ║
║  Level 1:  cfdi_csd                                   ║
║               │                                       ║
║  Level 2:  cfdi_xml                                   ║
║                                                       ║
╠═══════════════════════════════════════════════════════╣
║ Apps privados (sin publish)                           ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  sat_auth, sat_scraper, sat_pacs, cfdi_transform,     ║
║  cfdi_designs, cfdi_validador, renapo_curp, ...       ║
║                                                       ║
║  → No se publican                                     ║
║  → No reciben cascade                                 ║
║  → Siguen funcionando localmente con path: deps       ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

## Shared build paths

Para compartir compilación entre apps (más rápido):

```elixir
# En cada app's mix.exs
def project do
  [
    app: :cfdi_xml,
    version: "4.0.18",
    build_path: "../../../_build",      # compartido
    deps_path: "../../../deps",         # compartido
    lockfile: "../../../mix.lock",      # compartido
    deps: deps()
  ]
end
```

Con esto `mix compile` desde el root compila todo una vez.

## Estrategias de versionado

### Versión mayor compartida

Todos los paquetes comparten el mismo major. Útil cuando el monorepo
representa un solo producto:

```
cfdi_xml          4.0.18
cfdi_csd          4.0.16
cfdi_complementos 4.0.17
clir_openssl      4.0.12
```

### Versiones independientes

Cada paquete tiene su propio ciclo. Útil cuando los paquetes son
realmente independientes:

```
clir_openssl      0.0.17    ← utilidad, rara vez cambia
cfdi_xml          4.0.18    ← paquete principal
sat_auth          1.0.1     ← API estable
```

Releaser soporta ambas. El cascade maneja la coordinación.

## Anti-patrones

### Dependencia circular

```
app_a depends on app_b
app_b depends on app_a     ← ERROR
```

Releaser detecta esto y muestra error. Solución: extraer la parte
compartida a un tercer paquete.

### App publicable que depende de uno nunca publicado

```
cfdi_xml (publish: true)
  └─ depends on: mi_util_interna (never published, not in Hex)
```

Al publicar `cfdi_xml`, Hex no encontrará `mi_util_interna`. Soluciones:
1. Publicar `mi_util_interna` primero (marcar `publish: true`)
2. Mover el código compartido dentro de `cfdi_xml`
3. Publicar `mi_util_interna` una vez y luego quitar `publish: true`

### Demasiados paquetes publicables

Si todos los 34 paquetes son `publish: true`, cada bump cascadea a
muchos y cada publish toma mucho tiempo. Recomendación: solo marcar
como publicables los que realmente necesitan ser consumidos
externamente.

## Testing en monorepo

### Test de un solo app

```bash
cd apps/cfdi/xml && mix test
```

### Test de todo

```bash
# Desde el root
mix test

# O todos los apps con test
find apps -mindepth 3 -maxdepth 3 -name "mix.exs" -execdir mix test \;
```

### Usar el grafo para CI

El grafo te dice el orden correcto para tests en CI:

```bash
$ mix releaser.graph
# Level 0 → se pueden testear en paralelo (no deps internas)
# Level 1 → testear después de level 0
# etc.
```
