defmodule Cfdi.Complementos.RegistroFiscal do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "registrofiscal:CFDIRegistroFiscal",
    xmlns: "http://www.sat.gob.mx/registrofiscal",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/cfdiregistrofiscal/cfdiregistrofiscal.xsd"
end
