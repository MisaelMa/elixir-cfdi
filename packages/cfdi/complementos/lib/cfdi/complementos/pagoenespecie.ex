defmodule Cfdi.Complementos.PagoEnEspecie do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "pagoenespecie:PagoEnEspecie",
    xmlns: "http://www.sat.gob.mx/pagoenespecie",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/pagoenespecie/pagoenespecie.xsd"
end
