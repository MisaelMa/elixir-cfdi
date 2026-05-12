defmodule Sat.PortalCfdi do
  @moduledoc """
  Cliente del portal CFDI del SAT (`portalcfdi.facturaelectronica.sat.gob.mx`).

  Permite iniciar sesion (CIEC con captcha o FIEL con challenge SAML),
  consultar CFDIs por rango de fechas y descargar el XML de cada uno
  individualmente (sin paquete ZIP).

  Modulos principales:
    * `Sat.PortalCfdi.Portal` — fachada con `login/1`, `consultar_cfdis/2`,
      `descargar_xml/2`, `logout/1`
    * `Sat.PortalCfdi.Types` — structs para credenciales, sesion, parametros
      de consulta y resultados.
  """

  @doc false
  def version, do: Application.spec(:sat_portal_cfdi, :vsn)
end
