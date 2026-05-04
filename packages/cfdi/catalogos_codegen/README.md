# cfdi_catalogos_codegen

Herramienta de desarrollo que **genera automáticamente** los 15 módulos `.ex` de [`cfdi_catalogos`](../catalogos) a partir de los archivos oficiales del SAT: `catCFDI.xsd` (códigos válidos) y `catCFDI.xlsx` (descripciones, fechas de vigencia, metadata).

> **⚠️ Solo para desarrollo.** Este paquete está declarado con `only: :dev, runtime: false` en el monorepo. NO entra en el closure de runtime de ningún consumer.

---

## Quickstart

```bash
# Generar todos los catálogos usando el XLSX ya presente en packages/files/4.0/
mix cfdi.catalogos.generate

# Generar solo algunos
mix cfdi.catalogos.generate --only forma_pago,metodo_pago

# Escribir a un directorio temporal (útil para revisar antes de pisar)
mix cfdi.catalogos.generate --output tmp/generated

# Descargar el XLSX más reciente del SAT y regenerar
mix cfdi.catalogos.generate --force-download

# Override de URL (nueva release del SAT)
mix cfdi.catalogos.generate --force-download \
  --xlsx-url "https://omawww.sat.gob.mx/.../catCFDI_V_4_DDMMYYYY.xls"
```

---

## Catálogos generados

Quince catálogos en total — coinciden con los que genera `@cfdi/catalogos-codegen` en el monorepo Node.

### Con átomos curados (7) — variant `:with_atoms`

API: `list/0`, `valid?/1` (acepta string Y átomo), `value/1` (átomo → string), `from_code/1` (string → `{:ok, %{value: atom, code: string, label: string, deprecated: bool}}`).

| Catálogo | Módulo | Override file |
|----------|--------|---------------|
| `c_FormaPago` | `Cfdi.Catalogos.FormaPago` | `forma_pago.exs` |
| `c_MetodoPago` | `Cfdi.Catalogos.MetodoPago` | `metodo_pago.exs` |
| `c_TipoDeComprobante` | `Cfdi.Catalogos.TipoComprobante` | `tipo_comprobante.exs` |
| `c_Impuesto` | `Cfdi.Catalogos.Impuesto` | `impuesto.exs` |
| `c_UsoCFDI` | `Cfdi.Catalogos.UsoCFDI` | `uso_cfdi.exs` |
| `c_Exportacion` | `Cfdi.Catalogos.Exportacion` | `exportacion.exs` |
| `c_Moneda` | `Cfdi.Catalogos.Moneda` | `moneda.exs` (code-as-atom) |

### Solo strings (7) — variant `:strings_only`

API: `list/0`, `valid?/1` (solo string), `from_code/1`. SIN `value/1`. Las entries usan `:value` como string.

| Catálogo | Módulo | Override (opcional, solo descriptions) |
|----------|--------|---------------------------------------|
| `c_Periodicidad` | `Cfdi.Catalogos.Periodicidad` | — |
| `c_Meses` | `Cfdi.Catalogos.Meses` | — |
| `c_TipoRelacion` | `Cfdi.Catalogos.TipoRelacion` | `tipo_relacion.exs` |
| `c_ObjetoImp` | `Cfdi.Catalogos.ObjetoImp` | — |
| `c_TipoFactor` | `Cfdi.Catalogos.TipoFactor` | — |
| `c_Pais` | `Cfdi.Catalogos.Pais` | — |
| `c_Estado` | `Cfdi.Catalogos.Estado` | `estado.exs` |

### Con extras (1) — variant `:regimen_fiscal`

| Catálogo | Módulo | Extras |
|----------|--------|--------|
| `c_RegimenFiscal` | `Cfdi.Catalogos.RegimenFiscal` | `persona_fisica`, `persona_moral`, `inicio_vigencia`, `fin_vigencia` |

API: igual a strings_only, más los 4 extras en cada entry.

### Catálogos excluidos deliberadamente

Los siguientes son demasiado grandes para compilar como atom maps en BEAM y se excluyen — el consumidor típico los necesita como lookup en DB, no como código:

`c_ClaveProdServ` (~52k filas), `c_ClaveUnidad` (~2.3k), `c_CodigoPostal`, `c_Colonia`, `c_Localidad`, `c_Municipio`.

Esto coincide con la decisión de Node-cfdi.

---

## Pipeline interno

```
catCFDI.xsd  ──► Parsers.Xsd       (regex)            ─┐
                                                         │
catCFDI.xlsx ──► Parsers.Xlsx      (:zip + Saxy)       ─┼──► CrossValidator ──► Renderer ──► .ex files
                                                         │
priv/overrides/<cat>.exs ──► Overrides (Code.eval_file)─┘                                  con header NO EDITAR
```

| Módulo | Responsabilidad |
|--------|----------------|
| `Cfdi.Catalogos.Codegen.Parsers.Xsd` | Lee `catCFDI.xsd` con regex; devuelve `%{simpletype => [code, ...]}` |
| `Cfdi.Catalogos.Codegen.Parsers.Xlsx` | Abre `.xlsx` con `:zip.unzip/2`, lee `xl/sharedStrings.xml` y `xl/worksheets/sheet*.xml` con SAX handlers de `Saxy`. Devuelve `[[cell, ...]]`. Sin `xlsxir` |
| `Cfdi.Catalogos.Codegen.Overrides` | `Code.eval_file/1` sobre archivos `.exs` de `priv/overrides/`; devuelve `%{enum_names: %{}, descriptions: %{}}` |
| `Cfdi.Catalogos.Codegen.AtomNamer` | Normaliza `"Cheque nominativo"` → `:cheque_nominativo` (NFD strip + ASCII filter + snake_case + trim). Solo se usa para auto-derivar átomos cuando un override tiene un código sin `enum_names` (raramente; las catalogos con átomos siempre traen overrides explícitos) |
| `Cfdi.Catalogos.Codegen.CrossValidator` | XSD ∩ XLSX ∩ overrides → entries. XLSX sin XSD → `:error`. XSD sin XLSX → `deprecated: true`, label desde `descriptions` o `""`. `ending_date` pasada → `deprecated: true` |
| `Cfdi.Catalogos.Codegen.Catalogs` | Lista estática `Catalogs.specs/0` con los 15 `Spec` (qué hoja leer, qué columna es el label, padding del código, etc.) |
| `Cfdi.Catalogos.Codegen.Renderer` | Emite código Elixir formateado. 3 variantes: `:with_atoms`, `:strings_only`, `:regimen_fiscal`. El header banner es **idéntico** en todos los archivos generados |
| `Cfdi.Catalogos.Codegen` | Orchestrator. Loop sobre `specs`, llama parsers/validator/renderer, escribe archivos |
| `Mix.Tasks.Cfdi.Catalogos.Generate` | CLI. Parsea flags, opcionalmente descarga via `Sat.Recursos`, llama orchestrator |

---

## Archivos de override

Ubicación: `priv/overrides/<catalog>.exs`. Una clave por catálogo. Cada archivo evalúa a un mapa con dos keys:

```elixir
# priv/overrides/forma_pago.exs
%{
  enum_names: %{
    "01" => :efectivo,
    "02" => :cheque_nominativo,
    # ... un átomo por código del XLSX
  },
  descriptions: %{
    # Códigos que ESTÁN en el XSD pero NO en el XLSX
    # (típicamente deprecated). Sin esto, label queda como "".
    "P01" => "Por definir"
  }
}
```

- **`enum_names`** — solo aplica a catálogos `:with_atoms` (y a `:moneda`, code-as-atom). Para `:strings_only` se deja `%{}`.
- **`descriptions`** — fallback de label cuando el código está deprecated (presente en XSD, ausente en XLSX). El `CrossValidator` lo consulta automáticamente.

**Importante**: si un catálogo `:with_atoms` recibe del XLSX un código sin entrada en `enum_names`, el `CrossValidator` lanza `{:error, {:missing_atom_override, code}}` — falla rápido para que actualicés el override antes de generar archivos rotos.

---

## Spec de un catálogo

`Cfdi.Catalogos.Codegen.Catalogs.Spec` define qué leer y cómo renderizar:

```elixir
%Spec{
  simpletype:      "c_FormaPago",                     # nombre en XSD
  module_name:     Cfdi.Catalogos.FormaPago,          # módulo destino
  file_name:       "forma_pago.ex",                   # archivo .ex
  variant:         :with_atoms,                       # :with_atoms | :strings_only | :regimen_fiscal
  sheet_name:      nil,                               # nil → usa simpletype
  extra_columns:   [],                                # solo para :regimen_fiscal
  overrides_file:  "forma_pago.exs",                  # nil si no hay overrides
  code_pad_start:  2,                                 # 0 = sin padding; 2 = "1" → "01"
  label_column:    1                                  # 1 = col B (default); 2 = col C (Estado tiene c_Pais en B)
}
```

### Cuándo cambiar `label_column`

Cuando la hoja del SAT tenga columnas intermedias antes del label real. Ejemplos detectados:

- **`c_Estado`** → `label_column: 2` (col B = `c_Pais` "MEX", col C = nombre del estado).
- **`c_TipoFactor`** → `label_column: 0` (sin columna de descripción separada; el código `"Tasa"` ES el label).

### Cuándo cambiar `code_pad_start`

Cuando el XLSX devuelva el código como **integer** y el XSD lo tenga como string padded:

- `c_FormaPago`: XLSX `1` → XSD `"01"` → `code_pad_start: 2`
- `c_Impuesto`: XLSX `1` → XSD `"001"` → `code_pad_start: 3`
- `c_RegimenFiscal`: XLSX `601` → XSD `"601"` → `code_pad_start: 0` (ya tiene 3 dígitos)
- `c_Moneda`: XLSX `"MXN"` → XSD `"MXN"` → `code_pad_start: 0` (string ISO ya correcto)

---

## Workflow ante una nueva release del SAT

El SAT publica el catálogo CFDI 4.0 unas 2-3 veces al año.

### 1. Encontrar la URL nueva

Visitar [Anexo 20](http://omawww.sat.gob.mx/tramitesyservicios/Paginas/anexo_20.htm) y buscar el link a `catCFDI_V_4_DDMMYYYY.xls`.

> **El SAT publica el archivo en formato `.xls` binario (BIFF/OLE2)** — formato Excel 97–2003. **No es `.xlsx`** (ZIP+XML). Esto se confirmó cuando intentamos parsear el binario directo.

### 2. Actualizar la URL hardcoded

Editar `packages/sat/recursos/lib/sat/recursos/sat_resources.ex`:

```elixir
@xlsx_last_verified ~D[YYYY-MM-DD]   # ← fecha de la nueva release
@urls %{
  "4.0" => %{
    schema: "...",
    xslt: "...",
    xlsx: "http://omawww.sat.gob.mx/tramitesyservicios/Paginas/documentos/catCFDI_V_4_DDMMYYYY.xls"
    #                                                                                 ↑ nueva fecha
  },
  ...
}
```

Y actualizá los tests en `packages/sat/recursos/test/sat_resources_test.exs` que asertan la fecha y la URL hardcoded.

### 3. Bajar el archivo

```bash
mix cfdi.catalogos.generate --force-download
```

Esto descarga el `.xls` y lo guarda en `packages/files/4.0/catCFDI.xlsx`. **El nombre tiene `.xlsx` pero el contenido es `.xls`** — necesita conversión.

### 4. Convertir `.xls` → `.xlsx`

Hasta que tengamos un BIFF parser nativo en Elixir, hay que convertirlo. Tres formas:

**Con SheetJS (si tenés node-cfdi clonado al lado)**:
```bash
cd ../node-cfdi/packages/cfdi/catalogos-codegen && node -e '
const X = require("xlsx");
const f = "/Users/amir/Documents/proyectos/recreando/sat/elixir-cfdi/packages/files/4.0/catCFDI.xlsx";
X.writeFile(X.readFile(f), f, { bookType: "xlsx" });
'
```

**Con LibreOffice (si lo tenés instalado)**:
```bash
soffice --headless --convert-to xlsx \
  --outdir packages/files/4.0 \
  packages/files/4.0/catCFDI.xlsx
mv packages/files/4.0/catCFDI.xlsx.xlsx packages/files/4.0/catCFDI.xlsx
```

**Manualmente**: abrir en Excel/Numbers, guardar como `.xlsx`, sobreescribir.

### 5. Regenerar

```bash
mix cfdi.catalogos.generate
```

### 6. Revisar el diff

```bash
git diff packages/cfdi/catalogos/lib/cfdi/catalogos/
```

Cosas a buscar:

- **Códigos nuevos** sin override: el codegen falla con `{:missing_atom_override, code}` para catálogos `:with_atoms`. Agregá el átomo a `priv/overrides/<catalog>.exs`.
- **Códigos eliminados** del XLSX: aparecen como `deprecated: true, label: ""`. Si querés conservar el label histórico, agregalo al `descriptions` del override.
- **Cambios en `inicio_vigencia`/`fin_vigencia`** de `RegimenFiscal`: pueden marcar nuevos regímenes como `deprecated: true` por la fecha.

### 7. Tests + commit

```bash
cd packages/cfdi/catalogos && mix test
cd packages/cfdi/catalogos_codegen && mix test --exclude network

git add packages/files/4.0/catCFDI.xlsx \
        packages/cfdi/catalogos/lib/cfdi/catalogos/ \
        packages/cfdi/catalogos_codegen/priv/overrides/ \
        packages/sat/recursos/lib/sat/recursos/sat_resources.ex
git commit -m "feat(catalogos): SAT release YYYY-MM-DD"
```

---

## Cómo agregar un catálogo nuevo

Si el SAT agrega un nuevo `simpleType` (digamos `c_NuevoCatalogo`):

1. **Agregar el spec** en `lib/cfdi/catalogos/codegen/catalogs.ex`:
   ```elixir
   %Spec{
     simpletype: "c_NuevoCatalogo",
     module_name: Cfdi.Catalogos.NuevoCatalogo,
     file_name: "nuevo_catalogo.ex",
     variant: :strings_only,    # o :with_atoms si necesita átomos
     code_pad_start: 0,         # ajustar según el shape del XLSX
     label_column: 1            # ajustar si la hoja tiene columnas intermedias
   }
   ```

2. **Inspeccionar el shape del XLSX** (con node + SheetJS o LibreOffice) para verificar:
   - ¿Necesita `code_pad_start`? (tipo de la columna del código)
   - ¿Necesita `label_column` distinto? (columnas intermedias)
   - ¿Necesita `extra_columns`? (campos adicionales como en RegimenFiscal)

3. **Si es `:with_atoms`**: crear `priv/overrides/nuevo_catalogo.exs` con todos los `enum_names`. Sin esto, el codegen falla.

4. **Regenerar y commitear**:
   ```bash
   mix cfdi.catalogos.generate
   ```

---

## Tests

```bash
# Recomendado en CI: excluir tests de red
mix test --exclude network

# Suite completa (descarga el XLSX real, requiere conexión)
mix test
```

Los tests `@tag :network` hacen una descarga real desde `omawww.sat.gob.mx` — útiles para validar end-to-end pero lentos y dependientes de red.

### Estructura de tests

| Layer | Cobertura |
|-------|-----------|
| Unit | Cada parser/validator/namer/renderer con inputs inline |
| Integration | `Codegen.generate/1` contra `test/fixtures/tiny.{xsd,xlsx}` |
| Mix task | `Mix.Tasks.Cfdi.Catalogos.Generate.run/1` con flags |
| Golden | Archivos `test/fixtures/golden_*.ex` byte-comparados contra renderer output |

Para regenerar la fixture `tiny.xlsx`, hay un helper en `test/support/xlsx_fixture.ex` (multi-sheet ZIP creado con `:zip.create/3`).

---

## Decisiones de diseño relevantes

- **Output commiteado**: los `.ex` generados viven en git en `packages/cfdi/catalogos/lib/cfdi/catalogos/`. NO se generan en compile-time. Esto da reproducibilidad, hace los diffs auditables en PRs y permite a `cfdi_catalogos` no tener `saxy` como dep.
- **`saxy` y no `xlsxir`**: `xlsxir` no se mantiene desde 2021. Para una lectura tan acotada (2 columnas de hojas conocidas) escribimos un parser propio sobre `:zip` + `Saxy` (~100 LOC).
- **Header banner sin timestamp**: idempotencia byte-a-byte. Si los inputs no cambian, regenerar produce diff cero.
- **No hay shims de compatibilidad**: cuando un cambio rompe la API (ej. `RegimenFiscal.value` int → string), arreglamos los call sites internos en el mismo PR. Es viable porque `cfdi_catalogos` no está publicado en Hex todavía.
- **`only: :dev, runtime: false`**: este paquete NO se carga en runtime. La advertencia de compilación sobre `Sat.Recursos.SatResources` desde otros paquetes es esperable mientras `cfdi_catalogos_codegen` no esté en su `deps`.

---

## Estructura del paquete

```
packages/cfdi/catalogos_codegen/
├── mix.exs                                  ← deps: [{:saxy, ...}, {:sat_recursos, path: "..."}]
├── README.md                                ← este archivo
├── lib/
│   ├── cfdi/catalogos/codegen.ex             ← Cfdi.Catalogos.Codegen.generate/1
│   ├── cfdi/catalogos/codegen/
│   │   ├── catalogs.ex                       ← specs/0 — la lista de los 15
│   │   ├── parsers/
│   │   │   ├── xsd.ex
│   │   │   ├── xlsx.ex                       ← :zip + Saxy
│   │   │   └── xlsx/
│   │   │       ├── shared_strings.ex         ← SAX handler
│   │   │       └── sheet.ex                  ← SAX handler
│   │   ├── overrides.ex                      ← Code.eval_file/1
│   │   ├── atom_namer.ex                     ← Spanish → snake_case
│   │   ├── cross_validator.ex                ← XSD ∩ XLSX ∩ overrides
│   │   └── renderer.ex                       ← 3 variantes
│   └── mix/tasks/cfdi.catalogos.generate.ex  ← Mix.Task
├── priv/overrides/                            ← .exs override files
│   ├── forma_pago.exs
│   ├── metodo_pago.exs
│   ├── tipo_comprobante.exs
│   ├── impuesto.exs
│   ├── uso_cfdi.exs
│   ├── exportacion.exs
│   ├── moneda.exs                             ← code-as-atom (ISO 4217)
│   ├── regimen_fiscal.exs                     ← solo descriptions
│   ├── tipo_relacion.exs                      ← solo descriptions
│   └── estado.exs                             ← solo descriptions
└── test/
    ├── fixtures/
    │   ├── tiny.xsd                           ← c_A + c_B
    │   ├── tiny.xlsx                          ← multi-sheet, generado por xlsx_fixture
    │   ├── golden_with_atoms.ex
    │   ├── golden_strings_only.ex
    │   ├── golden_regimen_fiscal.ex
    │   └── sample_override.exs
    ├── support/
    │   └── xlsx_fixture.ex                    ← :zip.create/3 helper
    └── cfdi/catalogos/codegen/...              ← tests por módulo
```

---

## Limitaciones conocidas

1. **No parsea `.xls` (BIFF) nativamente.** El SAT publica `.xls` y hay que convertirlo a `.xlsx` antes de correr el codegen. Ver workflow arriba.
2. **`Moneda` con 183 entries hardcoded en el override.** Si el SAT agrega una currency nueva, el codegen falla con `{:missing_atom_override, code}` — hay que actualizar `priv/overrides/moneda.exs`.
3. **El `@xlsx_last_verified` es manual.** Cada nueva URL del SAT requiere actualizar la fecha en `sat_resources.ex` para que el log warning sobre URL stale sea preciso.
4. **Sin versión multi-CFDI**: solo soporta CFDI 4.0. La estructura admite agregar 3.3 en el futuro pero no está en scope hoy.

---

## Referencia: equivalente Node.js

Este paquete es el port de [`@cfdi/catalogos-codegen`](../../../../../node-cfdi/packages/cfdi/catalogos-codegen) del monorepo `node-cfdi`. Decisiones de scope idénticas. Diferencias técnicas: usa Saxy + :zip en vez de SheetJS; las atom-overrides se cargan vía `Code.eval_file/1` en vez de `import`.
