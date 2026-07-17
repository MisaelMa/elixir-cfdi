defmodule Cfdi.Complementos.ObrasArte do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "obrasarte:obrasarteantiguedades",
    xmlns: "http://www.sat.gob.mx/arteantiguedades",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/arteantiguedades/obrasarteantiguedades.xsd"
end
