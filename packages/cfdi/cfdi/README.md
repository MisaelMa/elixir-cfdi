# cfdi

Construcción, sellado y timbrado de CFDI 4.0 en Elixir. Réplica de
[node-cfdi](https://github.com/MisaelMa/node-cfdi).

## Cadena original: el XSLT debe estar LOCALIZADO

`CFDI.xslt/2` y `CFDI.generar_cadena_original/2` aplican un XSLT con
`cfdi_transform`, cuyo `Cfdi.Transform.XsltParser` **solo sigue los
`xsl:include` con `href` relativo** e **ignora en silencio los remotos**
(`http://www.sat.gob.mx/...`).

El `cadenaoriginal_4_0.xslt` que publica el SAT trae includes remotos. Usado
tal cual, los complementos (Pagos 2.0, Nómina 1.2, IEDU, Carta Porte…) entran
al XML pero NO a la cadena original, y el Sello sale inválido.

### Procedimiento para localizar el XSLT

1. Descarga `cadenaoriginal_4_0.xslt` del SAT a un directorio de trabajo.
2. Por cada `<xsl:include href="http://www.sat.gob.mx/..."/>`, descarga ese
   XSLT del complemento al mismo directorio (o a un subdirectorio).
3. Reescribe cada `href` remoto a una ruta relativa local, por ejemplo:

   ```xml
   <!-- antes -->
   <xsl:include href="http://www.sat.gob.mx/sitio_internet/cfd/nomina/nomina12.xslt"/>
   <!-- después -->
   <xsl:include href="./nomina12.xslt"/>
   ```

   Repite si los XSLT descargados incluyen a su vez otros remotos (p. ej.
   `utilerias.xslt`).
4. Verifica contra el procesador de referencia. La cadena de `xsltproc` y la
   del motor deben ser idénticas:

   ```bash
   xsltproc cadenaoriginal_4_0.xslt factura.xml
   ```

   ```elixir
   cfdi = CFDI.xslt(cfdi, "ruta/a/cadenaoriginal_4_0.xslt")
   {:ok, cadena} = CFDI.generar_cadena_original(cfdi)
   # `cadena` debe ser igual a la salida de xsltproc
   ```

Limitación conocida: `xsl:if` solo condiciona reglas de nodos hijos, no
`call-template` de atributos.

Ver el README de `cfdi_transform` (XSLT localizado incluido y tarea para
actualizarlo).
