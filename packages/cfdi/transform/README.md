# cfdi_transform

Parser XSLT y motor de **cadena original** para CFDI 4.0 (port Elixir de
[`@cfdi/transform`](https://github.com/MisaelMa/node-cfdi/tree/main/packages/cfdi/transform)).

No es un procesador XSLT general: implementa el subconjunto que usa el SAT en
`cadenaoriginal_4_0.xslt` (`xsl:include`, `xsl:template`, `Requerido`/`Opcional`,
`xsl:apply-templates`, `xsl:for-each`, `xsl:if`).

## Instalación

```elixir
def deps do
  [{:cfdi_transform, "~> 4.0"}]
end
```

## Uso rápido (XSLT incluido)

El paquete trae en `priv/` el `cadenaoriginal_4_0.xslt` oficial **ya localizado**:

```elixir
alias Cfdi.Transform.Transform

cadena =
  Transform.new()
  |> Transform.s("comprobante.xml")
  |> Transform.xsl(Cfdi.Transform.bundled_xslt())
  |> Transform.run!()
```

`Cfdi.Transform.bundled_xslt/0` devuelve la ruta del XSLT incluido
(`priv/xslt/4.0/cadenaoriginal_4_0.xslt`).

## IMPORTANTE: el XSLT debe estar LOCALIZADO

`Cfdi.Transform.XsltParser` solo sigue `xsl:include` con `href` **relativo**. El
`cadenaoriginal_4_0.xslt` que publica el SAT trae includes **remotos**:

```xml
<xsl:include href="http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xslt"/>
```

El parser NO descarga URLs. Si le das el XSLT del SAT tal cual, el complemento
(Pagos 2.0, Nómina 1.2, IEDU, Carta Porte, ...) entra al XML pero **no a la cadena
original** y el Sello resulta inválido.

Qué hace el parser con un include remoto:

| Modo | Comportamiento |
|------|----------------|
| por defecto | `Logger.warning` con el `href` ignorado y continúa |
| `strict: true` | devuelve `{:error, {:remote_include, href}}` (`Transform.xsl/3` levanta `include remoto no soportado: <href>`) |

```elixir
Cfdi.Transform.XsltParser.parse_file("cadenaoriginal_4_0.xslt", strict: true)
#=> {:error, {:remote_include, "http://www.sat.gob.mx/..."}}
```

### Cómo localizar el XSLT a mano

1. Descarga `http://www.sat.gob.mx/sitio_internet/cfd/4/cadenaoriginal_4_0/cadenaoriginal_4_0.xslt`.
2. Descarga cada XSLT referenciado en sus `xsl:include` a una carpeta `complementos/`.
3. Reescribe cada `href` remoto a una ruta relativa, p. ej. `./complementos/Pagos20.xslt`.
4. Apunta `Transform.xsl/2` al archivo principal.

### Cómo hacerlo automático: `mix cfdi.xslt.update`

```bash
mix cfdi.xslt.update                          # escribe en priv/xslt/4.0
mix cfdi.xslt.update --dest priv/sat/4.0      # otro destino (p. ej. en tu app)
mix cfdi.xslt.update --url <url-del-xslt>     # otra URL de origen
```

La tarea descarga el principal y todos los complementos, reescribe los includes y
solo escribe en disco si TODAS las descargas funcionan. Úsala en tu app si quieres
mantener tu propia copia actualizada.

## Verificar contra el SAT

Con los XSLT localizados, compara contra `xsltproc` (la cadena debe ser idéntica):

```bash
xsltproc priv/xslt/4.0/cadenaoriginal_4_0.xslt factura.xml
```

Los tests de este paquete lo hacen con fixtures por complemento
(`test/fixtures/parity/`, regenerables con `generate.sh`).

## Limitaciones conocidas

- Solo `http(s)` remoto no se sigue (ver arriba); los includes relativos sí.
- `xsl:if` soporta tests por atributo (`@a='v'`, `@a!='v'`, `@a`), por nodo
  (`./ns:Nodo`) y combinaciones con `and`/`or`; otras expresiones XPath no.
