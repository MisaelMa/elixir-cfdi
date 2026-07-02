# Genera los XML COMPLETOS que se envían al WS de Descarga Masiva del SAT y los
# escribe (formateados) en `docs/sat/ejemplos/*.xml` para poder inspeccionarlos
# a ojo y compararlos contra los PDFs oficiales de `docs/sat/`.
#
# Uso (desde packages/sat/cfdi_descarga):
#
#     mix run scripts/gen_ejemplos_xml.exs
#
# Firma con el CSD de PRUEBAS commiteado LAN7008173R5 (no es FIEL, pero para ver
# la ESTRUCTURA del XML da igual).

alias Sat.Certificados.Credential
alias Sat.Cfdi.Descarga.Masiva.Internal.SoapEnvelope
alias Sat.Cfdi.Descarga.Masiva.Types.SolicitudParams

certs = Path.expand("../../../files/certificados", __DIR__)
out = Path.expand("../docs/sat/ejemplos", __DIR__)
File.mkdir_p!(out)

{:ok, cred} =
  Credential.create(
    Path.join(certs, "LAN7008173R5.cer"),
    Path.join(certs, "LAN7008173R5.key"),
    "12345678a"
  )

rfc = "LAN7008173R5"

# Pretty-printer: un elemento por línea, indentado por profundidad.
pretty = fn xml ->
  xml
  |> String.replace("><", ">\n<")
  |> String.split("\n")
  |> Enum.reduce({[], 0}, fn line, {acc, depth} ->
    line = String.trim(line)

    cond do
      String.starts_with?(line, "<?") ->
        {[line | acc], depth}

      String.starts_with?(line, "</") ->
        d = max(depth - 1, 0)
        {[String.duplicate("  ", d) <> line | acc], d}

      String.match?(line, ~r|^<[^/].*</.+>$|) or String.ends_with?(line, "/>") ->
        {[String.duplicate("  ", depth) <> line | acc], depth}

      String.starts_with?(line, "<") ->
        {[String.duplicate("  ", depth) <> line | acc], depth + 1}

      true ->
        {[String.duplicate("  ", depth) <> line | acc], depth}
    end
  end)
  |> elem(0)
  |> Enum.reverse()
  |> Enum.join("\n")
end

samples = [
  {"autenticacion.xml",
   SoapEnvelope.build_autenticacion(cred, now: ~U[2025-01-01 00:00:00.000Z])},
  {"solicitud-emitidos.xml",
   SoapEnvelope.build_solicitud(
     cred,
     %SolicitudParams{
       rfc_solicitante: rfc,
       rfc_emisor: rfc,
       fecha_inicial: ~U[2025-01-01 00:00:00Z],
       fecha_final: ~U[2025-01-31 23:59:59Z],
       tipo_solicitud: :emitidos,
       tipo_comprobante: :i,
       estado_comprobante: :vigente
     },
     "fake-token",
     "SolicitaDescargaEmitidos"
   )},
  {"solicitud-recibidos.xml",
   SoapEnvelope.build_solicitud(
     cred,
     %SolicitudParams{
       rfc_solicitante: rfc,
       rfc_emisor: "AAA010101AAA",
       fecha_inicial: ~U[2025-02-01 00:00:00Z],
       fecha_final: ~U[2025-02-28 23:59:59Z],
       tipo_solicitud: :recibidos
     },
     "fake-token",
     "SolicitaDescargaRecibidos"
   )},
  {"solicitud-folio.xml",
   SoapEnvelope.build_solicitud(
     cred,
     %SolicitudParams{
       rfc_solicitante: rfc,
       tipo_solicitud: :folio,
       uuid: "5FB2822E-396D-4725-8521-CDC4BDD20CCF"
     },
     "fake-token",
     "SolicitaDescargaFolio"
   )},
  {"verificacion.xml",
   SoapEnvelope.build_verificacion(
     cred,
     rfc,
     "4E80345D-917F-40BB-A98F-4A73939343C5",
     "fake-token"
   )},
  {"descarga.xml",
   SoapEnvelope.build_descarga(
     cred,
     rfc,
     "4e80345d-917f-40bb-a98f-4a73939343c5_01",
     "fake-token"
   )}
]

for {name, xml} <- samples do
  File.write!(Path.join(out, name), pretty.(xml) <> "\n")
  IO.puts("✓ docs/sat/ejemplos/#{name}  (#{byte_size(xml)} bytes)")
end
