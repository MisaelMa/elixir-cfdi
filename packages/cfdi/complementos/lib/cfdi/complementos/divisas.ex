defmodule Cfdi.Complementos.Divisas do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "divisas:Divisas",
    xmlns: "http://www.sat.gob.mx/divisas",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/divisas/divisas.xsd"
end
