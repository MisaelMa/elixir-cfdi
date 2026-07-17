defmodule Cfdi.Complementos.Pago20 do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "pago20:Pagos",
    xmlns: "http://www.sat.gob.mx/Pagos20",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd"
end
