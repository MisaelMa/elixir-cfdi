defmodule Cfdi.Complementos.LeyendasFisc do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "leyendasFisc:LeyendasFiscales",
    xmlns: "http://www.sat.gob.mx/leyendasFiscales",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/leyendasFiscales/leyendasFisc.xsd"
end
