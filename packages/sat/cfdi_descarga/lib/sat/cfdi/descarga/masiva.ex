defmodule Sat.Cfdi.Descarga.Masiva do
  @moduledoc """
  Web Service de Descarga Masiva del SAT.

  Endpoint base: `https://cfdidescargamasivasolicitud.clouda.sat.gob.mx`.

  El flujo oficial consta de 4 pasos:

    1. **Autenticacion** (`Sat.Cfdi.Descarga.Masiva.Autenticacion`) — obtiene un
       token Bearer firmando con FIEL.
    2. **Solicitud** (`Sat.Cfdi.Descarga.Masiva.Solicitud`) — registra
       una solicitud por rango de fechas, RFC emisor/receptor, tipo, etc.
       Retorna un `IdSolicitud`.
    3. **Verificacion** (`Sat.Cfdi.Descarga.Masiva.Verificacion`) — consulta
       el estado del job (en proceso, terminado, error). Cuando esta listo
       devuelve los `IdsPaquetes` disponibles.
    4. **Paquete** (`Sat.Cfdi.Descarga.Masiva.Paquete`) — descarga cada
       paquete (ZIP base64). El llamador puede extraer XMLs con
       `Sat.Cfdi.Descarga.Masiva.Paquete.Reader`.

  Para el flujo completo sincronico, ver `Sat.Cfdi.Descarga.Masiva.Pipeline`.
  """
end
