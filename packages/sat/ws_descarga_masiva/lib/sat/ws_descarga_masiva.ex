defmodule Sat.WsDescargaMasiva do
  @moduledoc """
  Cliente del Web Service oficial de Descarga Masiva del SAT.

  Endpoint base: `https://cfdidescargamasiva.clouda.sat.gob.mx`.

  El flujo oficial consta de 4 pasos:

    1. **Autenticacion** (`Sat.WsDescargaMasiva.Autenticacion`) — obtiene un
       token Bearer firmando con FIEL.
    2. **Solicita descarga** (`Sat.WsDescargaMasiva.Solicitud`) — registra
       una solicitud por rango de fechas, RFC emisor/receptor, tipo, etc.
       Retorna un `IdSolicitud`.
    3. **Verifica solicitud** (`Sat.WsDescargaMasiva.Verificacion`) — consulta
       el estado del job (en proceso, terminado, error). Cuando esta listo
       devuelve los `IdsPaquetes` disponibles.
    4. **Descarga paquete** (`Sat.WsDescargaMasiva.Descarga`) — descarga cada
       paquete (ZIP base64). El llamador puede extraer XMLs con
       `Sat.WsDescargaMasiva.PackageReader`.

  Opcionalmente, `Sat.WsDescargaMasiva.Cliente` orquesta los 4 pasos y expone
  un stream de XMLs para ocultar el ZIP al consumidor.
  """

  @doc false
  def version, do: Application.spec(:sat_ws_descarga_masiva, :vsn)
end
