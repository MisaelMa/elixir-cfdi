# sat_catalogos

Catálogos oficiales del SAT para CFDI 4.0, generados automáticamente desde `catCFDI.xsd` y `catCFDI.xlsx`.

> **Estos archivos son auto-generados por [`sat_catalogos_codegen`](../catalogos_codegen). NO EDITAR a mano.**

## Catálogos disponibles

| SimpleType SAT       | Módulo Elixir                        | Variante        | Átomos | Extras |
|----------------------|--------------------------------------|-----------------|--------|--------|
| `c_FormaPago`        | `Sat.Catalogos.FormaPago`           | `:with_atoms`   | Sí     |        |
| `c_MetodoPago`       | `Sat.Catalogos.MetodoPago`          | `:with_atoms`   | Sí     |        |
| `c_TipoDeComprobante`| `Sat.Catalogos.TipoComprobante`     | `:with_atoms`   | Sí     |        |
| `c_Impuesto`         | `Sat.Catalogos.Impuesto`            | `:with_atoms`   | Sí     |        |
| `c_UsoCFDI`          | `Sat.Catalogos.UsoCFDI`             | `:with_atoms`   | Sí     |        |
| `c_Exportacion`      | `Sat.Catalogos.Exportacion`         | `:with_atoms`   | Sí     |        |
| `c_Moneda`           | `Sat.Catalogos.Moneda`              | `:with_atoms`   | Sí     |        |
| `c_RegimenFiscal`    | `Sat.Catalogos.RegimenFiscal`       | `:regimen_fiscal`| No    | `persona_fisica`, `persona_moral`, `inicio_vigencia`, `fin_vigencia` |
| `c_Periodicidad`     | `Sat.Catalogos.Periodicidad`        | `:strings_only` | No     |        |
| `c_Meses`            | `Sat.Catalogos.Meses`               | `:strings_only` | No     |        |
| `c_TipoRelacion`     | `Sat.Catalogos.TipoRelacion`        | `:strings_only` | No     |        |
| `c_ObjetoImp`        | `Sat.Catalogos.ObjetoImp`           | `:strings_only` | No     |        |
| `c_TipoFactor`       | `Sat.Catalogos.TipoFactor`          | `:strings_only` | No     |        |
| `c_Pais`             | `Sat.Catalogos.Pais`                | `:strings_only` | No     |        |
| `c_Estado`           | `Sat.Catalogos.Estado`              | `:strings_only` | No     |        |

## API

### Catálogos con átomos (`FormaPago`, `MetodoPago`, `TipoComprobante`, `Impuesto`, `UsoCFDI`, `Exportacion`, `Moneda`)

```elixir
# Todos los registros
list/0  :: [%{value: atom(), code: String.t(), label: String.t(), deprecated: boolean()}]

# ¿Existe este código SAT?
valid?/1 :: (String.t()) -> boolean()   # solo acepta string; atom/integer → false

# Átomo → código SAT string
value/1  :: (atom()) -> String.t() | nil

# Código SAT string → mapa completo
from_code/1 :: (String.t()) -> {:ok, %{value: atom(), code: String.t(), label: String.t(), deprecated: boolean()}} | :error
```

### Catálogos string-only (`RegimenFiscal`, `Periodicidad`, `Meses`, `TipoRelacion`, `ObjetoImp`, `TipoFactor`, `Pais`, `Estado`)

```elixir
# Todos los registros
list/0  :: [%{value: String.t(), label: String.t(), deprecated: boolean(), ...extras}]

# ¿Existe este código SAT?
valid?/1 :: (String.t()) -> boolean()   # no hay value/1 en estos módulos

# Código SAT string → mapa completo
from_code/1 :: (String.t()) -> {:ok, %{value: String.t(), label: String.t(), deprecated: boolean(), ...extras}} | :error
```

> Nota: los catálogos string-only **no exponen `value/1`**. El campo `:value` de cada entrada es directamente el código SAT como string.

## Ejemplos

```elixir
alias Sat.Catalogos.{FormaPago, MetodoPago, RegimenFiscal, Pais, TipoFactor}

# Átomo → código SAT
FormaPago.value(:efectivo)
# => "01"

# Código SAT → mapa completo
FormaPago.from_code("01")
# => {:ok, %{value: :efectivo, code: "01", label: "Efectivo", deprecated: false}}

# Validación por código string
FormaPago.valid?("01")   # => true
FormaPago.valid?("ZZ")   # => false
FormaPago.valid?(:efectivo)  # => false (solo acepta string)

# MetodoPago (atom-bearing)
MetodoPago.from_code("PUE")
# => {:ok, %{value: :pago_en_una_exhibicion, code: "PUE", label: "Pago en una sola exhibición", deprecated: false}}

# RegimenFiscal (string-only con extras)
RegimenFiscal.from_code("601")
# => {:ok, %{value: "601", label: "General de Ley Personas Morales",
#            persona_fisica: false, persona_moral: true,
#            inicio_vigencia: ~D[2022-01-01], fin_vigencia: nil, deprecated: false}}

RegimenFiscal.valid?("626")  # RESICO => true
RegimenFiscal.valid?(601)    # integer => false

# TipoFactor (string-only; el código ES el valor)
TipoFactor.valid?("Tasa")   # => true
TipoFactor.from_code("Tasa")
# => {:ok, %{value: "Tasa", label: "Tasa", deprecated: false}}

# Pais
Pais.valid?("MEX")  # => true
Pais.from_code("MEX")
# => {:ok, %{value: "MEX", label: "México", deprecated: false}}
```

## Campos en entradas deprecadas

Las entradas deprecadas siguen siendo accesibles y retornan `deprecated: true`. Esto permite validar CFDIs históricos. Para filtrar solo activos:

```elixir
FormaPago.list() |> Enum.reject(& &1.deprecated)
```
