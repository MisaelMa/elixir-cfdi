# Getting Started

Releaser funciona con tres tipos de proyecto Elixir:

1. **Poncho project** (multi-app con grupos, como cfdi-elixir)
2. **Umbrella project** (multi-app estándar de Elixir)
3. **Proyecto single** (un solo mix.exs sin apps/)

## Instalación

Agrega `releaser` a tu **root** `mix.exs`:

```elixir
defp deps do
  [
    {:releaser, "~> 0.1", only: :dev, runtime: false}
  ]
end
```

```bash
mix deps.get
```

## Configuración por tipo de proyecto

### Poncho project (apps agrupados)

```
mi_proyecto/
├── mix.exs                          ← root
├── apps/
│   ├── cfdi/                        ← grupo
│   │   ├── xml/mix.exs              ← app
│   │   ├── csd/mix.exs              ← app
│   │   └── complementos/mix.exs     ← app
│   ├── sat/                         ← grupo
│   │   ├── auth/mix.exs             ← app
│   │   └── pacs/mix.exs             ← app
│   └── clir/
│       └── openssl/mix.exs          ← app
```

Configuración en el root `mix.exs`:

```elixir
def project do
  [
    app: :mi_proyecto,
    version: "0.1.0",
    deps: deps(),
    releaser: [
      apps_root: "apps"    # default, busca mix.exs recursivamente
    ]
  ]
end
```

En cada app que quieras publicar a Hex:

```elixir
# apps/cfdi/xml/mix.exs
def project do
  [
    app: :cfdi_xml,
    version: "4.0.18",
    deps: deps(),
    description: "XML builder para CFDI",
    releaser: [publish: true]         # ← marcado como publicable
  ]
end
```

### Umbrella project (estándar de Elixir)

```
mi_umbrella/
├── mix.exs                          ← root umbrella
├── apps/
│   ├── core/mix.exs                 ← app
│   ├── api/mix.exs                  ← app
│   └── worker/mix.exs               ← app
```

Configuración idéntica. Releaser detecta ambos layouts automáticamente:

```elixir
# mix.exs (root)
def project do
  [
    app: :mi_umbrella,
    version: "0.1.0",
    apps_path: "apps",    # esto es de umbrella
    deps: deps(),
    releaser: [
      apps_root: "apps"
    ]
  ]
end
```

En cada app:

```elixir
# apps/core/mix.exs
def project do
  [
    app: :core,
    version: "1.0.0",
    build_path: "../../_build",
    deps_path: "../../deps",
    lockfile: "../../mix.lock",
    deps: deps(),
    description: "Core business logic",
    releaser: [publish: true]
  ]
end
```

### Proyecto single (sin apps/)

Para un proyecto con un solo `mix.exs`:

```
mi_libreria/
├── mix.exs
├── lib/
└── test/
```

```elixir
# mix.exs
def project do
  [
    app: :mi_libreria,
    version: "1.0.0",
    deps: deps(),
    description: "Mi librería",
    releaser: [
      apps_root: ".",           # ← apunta al directorio actual
      publish: true
    ]
  ]
end
```

En este caso Releaser detecta un solo app y funciona para bump + changelog + publish (sin cascade porque no hay dependientes).

## Publish policy

### Qué es `publish: true`

El flag `releaser: [publish: true]` en el `mix.exs` de cada app controla:

| Con `publish: true` | Sin `publish: true` |
|---|---|
| Se publica a Hex con `mix releaser.publish` | NO se publica |
| Recibe cascade bump cuando sus deps cambian | NO recibe cascade bump |
| Aparece en `mix releaser.publish --dry-run` | No aparece en el plan de publish |
| Aparece en `mix releaser.status` con su estado | Aparece como "private" |
| Se incluye en `mix releaser.bump --list` | Se incluye en `--list` |
| Se incluye en `mix releaser.graph` | Se incluye en el grafo |

### Reglas de publicación

```
┌───────────────────────────────────────────────────────────────────────┐
│                       Reglas de publish                               │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  1. Solo apps con publish: true se publican                           │
│                                                                       │
│  2. Al publicar un app, también se publican sus DEPENDIENTES          │
│     (quienes dependen de él), no sus dependencias                     │
│                                                                       │
│  3. Las dependencias que no son publicables (publish: false)          │
│     se resuelven contra la versión que ya está en Hex                 │
│                                                                       │
│  4. El cascade de bump solo aplica a apps publicables                 │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

### Ejemplo: ¿qué pasa cuando modifico un app?

#### Caso 1: Modifico `cfdi_xml` (nadie depende de él)

```bash
$ mix releaser.bump cfdi_xml patch --dry-run

Version changes:
  cfdi_xml    4.0.18 → 4.0.19  (direct)
  # Solo cfdi_xml — nadie más depende de él

$ mix releaser.publish --only cfdi_xml --dry-run
# Solo publica cfdi_xml
# Sus deps (cfdi_csd, saxon_he, etc.) ya están en Hex
```

#### Caso 2: Modifico `cfdi_csd` (cfdi_xml depende de él)

```bash
$ mix releaser.bump cfdi_csd patch --dry-run

Version changes:
  cfdi_csd    4.0.16 → 4.0.17  (direct)
  cfdi_xml    4.0.18 → 4.0.19  (cascade)  ← depende de csd, publish: true
  # sat_auth NO aparece — tiene publish: false

$ mix releaser.publish --only cfdi_csd --dry-run
# Publica: cfdi_csd (nivel 1), luego cfdi_xml (nivel 2)
# sat_auth NO se publica — no tiene publish: true
```

#### Caso 3: Modifico `clir_openssl` (toda la cadena depende)

```bash
$ mix releaser.bump clir_openssl patch --dry-run

Version changes:
  clir_openssl  0.0.17 → 0.0.18  (direct)
  cfdi_csd      4.0.16 → 4.0.17  (cascade)
  cfdi_xml      4.0.18 → 4.0.19  (cascade)
  # Solo los publicables cascadean
```

### Escenarios de policy

#### App interno que nunca se publica

```elixir
# apps/sat/scraper/mix.exs — herramienta interna de scraping
def project do
  [
    app: :sat_scraper,
    version: "0.0.1",
    deps: deps()
    # Sin releaser: [publish: true] → privado, no se publica nunca
  ]
end
```

#### App que YA estaba en Hex pero ya no se publicará más

Si `cfdi_transform` ya está en Hex como `4.0.14` y decides no publicar más versiones:

1. Quita `releaser: [publish: true]` de su `mix.exs` (o simplemente no lo pongas)
2. La versión `4.0.14` sigue disponible en Hex
3. Los apps que dependen de él usan `{:cfdi_transform, "~> 4.0"}` — resuelve a `4.0.14`
4. No recibe cascade bumps
5. No se intenta publicar

#### App nuevo que se publicará por primera vez

```elixir
# apps/cfdi/nuevo/mix.exs
def project do
  [
    app: :cfdi_nuevo,
    version: "0.1.0",
    deps: deps(),
    description: "Nuevo paquete",        # requerido por Hex
    releaser: [publish: true]
  ]
end
```

Al ejecutar `mix releaser.publish`, se publica por primera vez.
`mix releaser.status` lo mostrará como "unpublished".

## Primeros pasos después de configurar

```bash
# 1. Ver todos los apps descubiertos
$ mix releaser.bump --list

# 2. Ver el grafo de dependencias
$ mix releaser.graph

# 3. Ver qué está pendiente de publicar
$ mix releaser.status

# 4. Probar un bump (sin aplicar cambios)
$ mix releaser.bump mi_app patch --tag dev --dry-run

# 5. Probar el plan de publicación
$ mix releaser.publish --dry-run
```

## Siguiente lectura

- [Pre-release Tags](pre-release-tags.html) — ciclo dev → beta → rc → release
- [Publishing to Hex](publishing-to-hex.html) — cómo funciona la publicación topológica
- [Changelog and Hooks](changelog-and-hooks.html) — automatizar git tags y changelogs
- [Monorepo Patterns](monorepo-patterns.html) — estructuras de proyecto y patrones avanzados
