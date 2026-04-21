# CFDI Elixir

Réplica funcional del monorepo [cfdi-node](../cfdi-node) en Elixir. Contiene **34 paquetes** organizados por dominio, cada uno como un proyecto Mix independiente.

## Arquitectura: Poncho Project

Este proyecto **no** usa umbrella de Elixir. En su lugar usa el patrón **poncho**: un proyecto raíz que depende de cada paquete vía `path:` dependencies. Esto permite agrupar los paquetes en carpetas por dominio (como Node.js) sin las restricciones del umbrella.

```
cfdi-elixir/
├── mix.exs              ← proyecto raíz (poncho), lista los 34 paquetes
├── apps/
│   ├── cfdi/            ← @cfdi/* de Node.js
│   │   ├── cancelacion/
│   │   ├── catalogos/
│   │   ├── cleaner/
│   │   ├── complementos/
│   │   ├── csd/
│   │   ├── csf/
│   │   ├── descarga/
│   │   ├── designs/
│   │   ├── elements/
│   │   ├── estado/
│   │   ├── expresiones/
│   │   ├── pdf/
│   │   ├── retenciones/
│   │   ├── rfc/
│   │   ├── schema/
│   │   ├── transform/
│   │   ├── types/
│   │   ├── utils/
│   │   ├── validador/
│   │   ├── xml/
│   │   ├── xml2json/
│   │   └── xsd/
│   ├── sat/             ← @sat/* de Node.js
│   │   ├── auth/
│   │   ├── banxico/
│   │   ├── captcha/
│   │   ├── contabilidad/
│   │   ├── diot/
│   │   ├── opinion/
│   │   ├── pacs/
│   │   ├── recursos/
│   │   └── scraper/
│   ├── clir/            ← @clir/* y @saxon-he/* de Node.js
│   │   ├── openssl/
│   │   └── saxon_he/
│   └── renapo/          ← @renapo/* de Node.js
│       └── curp/
└── lib/mix/tasks/
    ├── bump.ex              ← versionado con pre-release tags y cascada
    └── hex_publish_all.ex   ← publicación a Hex en orden topológico
```

## Inicio rápido

```bash
# Instalar dependencias
mix deps.get

# Compilar todo
mix compile

# Tests de un paquete específico
cd apps/cfdi/catalogos && mix test

# Tests de todos los paquetes
find apps -mindepth 3 -maxdepth 3 -name "mix.exs" -execdir mix test \;
```

## Cada paquete es independiente

Cada directorio dentro de `apps/<grupo>/<nombre>/` es un proyecto Mix completo con su propio `mix.exs`, `lib/`, y `test/`. Puedes compilar y testear cada uno por separado:

```bash
cd apps/cfdi/rfc
mix deps.get
mix test
```

### Dependencias entre paquetes

Los paquetes usan `path:` para depender de otros paquetes del monorepo:

```elixir
# apps/cfdi/xml/mix.exs
defp deps do
  [
    {:cfdi_csd, path: "../csd"},                    # mismo grupo
    {:saxon_he, path: "../../clir/saxon_he"},       # otro grupo
    {:xml_builder, "~> 2.1"}                        # Hex (externo)
  ]
end
```

- **Mismo grupo**: `path: "../<paquete>"`
- **Otro grupo**: `path: "../../<grupo>/<paquete>"`
- **Externo**: se declara como dependencia normal de Hex

## Versionado (mix bump)

Herramienta integrada similar a Rush para manejar versiones semver con pre-release tags y bumps en cascada.

### Listar versiones

```bash
mix bump --list
```

```
cfdi/
  cancelacion          0.0.1
  catalogos            4.0.16
  xml                  4.0.18
  ...
sat/
  auth                 1.0.1
  banxico              0.0.1
  ...
```

### Bump simple

```bash
mix bump cfdi_catalogos patch        # 4.0.16 → 4.0.17
mix bump sat_auth minor              # 1.0.1  → 1.1.0
mix bump cfdi_csd major              # 4.0.16 → 5.0.0
```

### Pre-release tags (como npm dist-tags)

Los tags permiten publicar versiones de prueba antes del release estable.
Hex y semver 2.0 soportan pre-release: las versiones con tag siempre son menores
que la versión estable del mismo número (`4.0.18-dev.1 < 4.0.18`).

#### Ciclo de vida de una versión

```
  ┌─────────────────────────────────────────────────────────────────┐
  │                   Ciclo de vida de versión                      │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  4.0.17 (estable actual)                                        │
  │    │                                                            │
  │    ├── mix bump <app> patch --tag dev                           │
  │    │     → 4.0.18-dev.1          bump base + agrega tag         │
  │    │                                                            │
  │    ├── mix bump <app> patch --tag dev                           │
  │    │     → 4.0.18-dev.2          mismo tag = solo incrementa    │
  │    │                                                            │
  │    ├── mix bump <app> patch --tag dev                           │
  │    │     → 4.0.18-dev.3          otro fix en dev                │
  │    │                                                            │
  │    ├── mix bump <app> patch --tag beta                          │
  │    │     → 4.0.18-beta.1         cambio de tag = mantiene base  │
  │    │                                                            │
  │    ├── mix bump <app> patch --tag beta                          │
  │    │     → 4.0.18-beta.2         fix en beta                    │
  │    │                                                            │
  │    ├── mix bump <app> release                                   │
  │    │     → 4.0.18                quita tag = release estable    │
  │    │                                                            │
  │  4.0.18 (nueva versión estable)                                 │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
```

#### Comandos

```bash
# Iniciar desarrollo: versión estable → dev
mix bump cfdi_complementos patch --tag dev    # 4.0.17 → 4.0.18-dev.1

# Iterar en dev (mismo tag solo incrementa el número)
mix bump cfdi_complementos patch --tag dev    # 4.0.18-dev.1 → 4.0.18-dev.2
mix bump cfdi_complementos patch --tag dev    # 4.0.18-dev.2 → 4.0.18-dev.3

# Promover a beta (cambio de tag mantiene el base)
mix bump cfdi_complementos patch --tag beta   # 4.0.18-dev.3 → 4.0.18-beta.1

# Iterar en beta
mix bump cfdi_complementos patch --tag beta   # 4.0.18-beta.1 → 4.0.18-beta.2

# Release final (quita el tag)
mix bump cfdi_complementos release            # 4.0.18-beta.2 → 4.0.18
```

#### Reglas de tags

| Situación | Comando | Resultado |
|---|---|---|
| Versión limpia `4.0.17` | `patch --tag dev` | `4.0.18-dev.1` (bump base + tag) |
| Mismo tag `-dev.2` | `patch --tag dev` | `4.0.18-dev.3` (solo incrementa) |
| Otro tag `-dev.3` | `patch --tag beta` | `4.0.18-beta.1` (mantiene base, cambia tag) |
| Cualquier tag `-beta.2` | `release` | `4.0.18` (quita tag) |

#### Tags comunes

| Tag | Uso |
|---|---|
| `dev` | Desarrollo activo, puede romper cosas |
| `alpha` | Primera versión de prueba interna |
| `beta` | Feature-complete pero puede tener bugs |
| `rc` | Release candidate, listo para producción salvo bugs |

> **Nota**: Hex ordena pre-release tags alfabéticamente (`alpha < beta < dev < rc`).
> La versión estable (`4.0.18`) siempre es mayor que cualquier pre-release del mismo número.

### Bump en cascada

Cuando haces bump de un paquete, **automáticamente** hace patch bump a todos los que dependen de él (como Rush):

```bash
mix bump clir_openssl minor --dry-run
```

```
Version changes:
  clir_openssl              0.0.17 → 0.1.0  (minor)
  cfdi_csd                  4.0.16 → 4.0.17  (patch)    ← depende de clir_openssl
  sat_auth                  1.0.1  → 1.0.2   (patch)    ← depende de cfdi_csd
  cfdi_xml                  4.0.18 → 4.0.19  (patch)    ← depende de cfdi_csd
  cfdi_descarga             0.0.1  → 0.0.2   (patch)    ← depende de sat_auth
  cfdi_cancelacion          0.0.1  → 0.0.2   (patch)    ← depende de sat_auth
```

| Flag | Efecto |
|---|---|
| `--dry-run` | Muestra qué cambiaría sin modificar archivos |
| `--no-cascade` | Solo hace bump del paquete indicado |
| `--tag TAG` | Agrega pre-release tag (dev, beta, rc, alpha) |

### Ver grafo de dependientes

```bash
mix bump --graph cfdi_csd
```

```
Dependents of cfdi_csd:
  └─ sat_auth
    └─ cfdi_descarga
    └─ cfdi_cancelacion
  └─ cfdi_xml
```

## Publicación a Hex (mix hex.publish_all)

Herramienta que publica todos los paquetes a Hex respetando el orden de dependencias.
Equivalente a `rush publish` en Node.js.

### Ver grafo de dependencias

```bash
mix hex.publish_all --graph
```

```
╔══════════════════════════════════════════════════╗
║        CFDI Umbrella — Dependency Graph          ║
╚══════════════════════════════════════════════════╝

┌── Level 0  (sin dependencias internas) ──┐
│   cfdi_catalogos v4.0.16
│   cfdi_complementos v4.0.17
│   clir_openssl v0.0.17
│   saxon_he v12.5.2
│   ... (28 apps)
│       ▼
┌── Level 1 ──┐
│   cfdi_csd v4.0.16
│   └─ depends on: clir_openssl
│   cfdi_designs v1.0.0
│   └─ depends on: cfdi_xml2json, cfdi_utils, cfdi_types, cfdi_complementos
│       ▼
┌── Level 2 ──┐
│   cfdi_xml v4.0.18
│   └─ depends on: cfdi_csd, cfdi_transform, cfdi_complementos, ...
│   sat_auth v1.0.1
│   └─ depends on: cfdi_csd
│       ▼
┌── Level 3 ──┐
│   cfdi_cancelacion v0.0.1
│   └─ depends on: sat_auth
│   cfdi_descarga v0.0.1
│   └─ depends on: sat_auth
└── end ──┘
```

### Ver plan sin publicar

```bash
mix hex.publish_all --dry-run
```

Muestra el orden de publicación y los cambios que haría en cada `mix.exs`:

```
cfdi_csd mix.exs changes:
  {:clir_openssl, path: "..."} → {:clir_openssl, "~> 0.0"}

cfdi_xml mix.exs changes:
  {:cfdi_csd, path: "..."} → {:cfdi_csd, "~> 4.0"}
  {:cfdi_transform, path: "..."} → {:cfdi_transform, "~> 4.0"}
  ...
```

### Publicar

```bash
# Publicar todo
mix hex.publish_all

# Publicar con bump de versión
mix hex.publish_all --bump patch

# Publicar solo un paquete (incluye sus deps automáticamente)
mix hex.publish_all --only cfdi_xml

# Publicar a una organización
mix hex.publish_all --org miorg
```

### Qué hace internamente

Para cada paquete (en orden topológico):

1. Backup del `mix.exs` original
2. Bump de versión si se pasó `--bump`
3. Reemplazo de deps `path:` → `~> X.Y` (versión publicada)
4. Inyección de `package/0` con licencia y links
5. `mix hex.publish --yes`
6. Restauración del `mix.exs` original (siempre, incluso si falla)

### Flujo recomendado para release

```bash
# 1. Desarrollo: bump a dev
mix bump cfdi_xml patch --tag dev

# 2. Iterar y probar
mix bump cfdi_xml patch --tag dev     # incrementa dev.N

# 3. Beta
mix bump cfdi_xml patch --tag beta

# 4. Release
mix bump cfdi_xml release

# 5. Publicar todo a Hex
mix hex.publish_all
```

## Mapa Node.js → Elixir

| Node.js (`@scope/name`) | Elixir (app name) | Ruta |
|---|---|---|
| `@cfdi/cancelacion` | `:cfdi_cancelacion` | `apps/cfdi/cancelacion/` |
| `@cfdi/catalogos` | `:cfdi_catalogos` | `apps/cfdi/catalogos/` |
| `@cfdi/cleaner` | `:cfdi_cleaner` | `apps/cfdi/cleaner/` |
| `@cfdi/complementos` | `:cfdi_complementos` | `apps/cfdi/complementos/` |
| `@cfdi/csd` | `:cfdi_csd` | `apps/cfdi/csd/` |
| `@cfdi/csf` | `:cfdi_csf` | `apps/cfdi/csf/` |
| `@cfdi/descarga` | `:cfdi_descarga` | `apps/cfdi/descarga/` |
| `@cfdi/designs` | `:cfdi_designs` | `apps/cfdi/designs/` |
| `@cfdi/elements` | `:cfdi_elements` | `apps/cfdi/elements/` |
| `@cfdi/estado` | `:cfdi_estado` | `apps/cfdi/estado/` |
| `@cfdi/expresiones` | `:cfdi_expresiones` | `apps/cfdi/expresiones/` |
| `@cfdi/pdf` | `:cfdi_pdf` | `apps/cfdi/pdf/` |
| `@cfdi/retenciones` | `:cfdi_retenciones` | `apps/cfdi/retenciones/` |
| `@cfdi/rfc` | `:cfdi_rfc` | `apps/cfdi/rfc/` |
| `@cfdi/schema` | `:cfdi_schema` | `apps/cfdi/schema/` |
| `@cfdi/transform` | `:cfdi_transform` | `apps/cfdi/transform/` |
| `@cfdi/types` | `:cfdi_types` | `apps/cfdi/types/` |
| `@cfdi/utils` | `:cfdi_utils` | `apps/cfdi/utils/` |
| `@cfdi/validador` | `:cfdi_validador` | `apps/cfdi/validador/` |
| `@cfdi/xml` | `:cfdi_xml` | `apps/cfdi/xml/` |
| `@cfdi/xml2json` | `:cfdi_xml2json` | `apps/cfdi/xml2json/` |
| `@cfdi/xsd` | `:cfdi_xsd` | `apps/cfdi/xsd/` |
| `@sat/auth` | `:sat_auth` | `apps/sat/auth/` |
| `@sat/banxico` | `:sat_banxico` | `apps/sat/banxico/` |
| `@sat/captcha` | `:sat_captcha` | `apps/sat/captcha/` |
| `@sat/contabilidad` | `:sat_contabilidad` | `apps/sat/contabilidad/` |
| `@sat/diot` | `:sat_diot` | `apps/sat/diot/` |
| `@sat/opinion` | `:sat_opinion` | `apps/sat/opinion/` |
| `@sat/pacs` | `:sat_pacs` | `apps/sat/pacs/` |
| `@sat/recursos` | `:sat_recursos` | `apps/sat/recursos/` |
| `@sat/scraper` | `:sat_scraper` | `apps/sat/scraper/` |
| `@clir/openssl` | `:clir_openssl` | `apps/clir/openssl/` |
| `@saxon-he/cli` | `:saxon_he` | `apps/clir/saxon_he/` |
| `@renapo/curp` | `:renapo_curp` | `apps/renapo/curp/` |

## Diferencias con umbrella

| | Umbrella | Poncho (este proyecto) |
|---|---|---|
| Estructura | `apps/cfdi_catalogos/` (plano) | `apps/cfdi/catalogos/` (agrupado) |
| Descubrimiento | Automático por Mix | Explícito en `deps` del root |
| Deps entre apps | `in_umbrella: true` | `path: "../catalogos"` |
| `mix test` (root) | Corre todos los tests | Corre solo root tests |
| `mix compile` | Compila todo | Compila todo (via path deps) |
| Build compartido | Sí (por defecto) | Sí (via `build_path` compartido) |
