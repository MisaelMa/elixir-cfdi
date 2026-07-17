defmodule Cfdi.Complementos.Donat do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "donat:Donatarias",
    xmlns: "http://www.sat.gob.mx/donat",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/donat/donat11.xsd"
end
