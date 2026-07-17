defmodule Cfdi.Complementos.CartaPorte31 do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "cartaporte31:CartaPorte",
    xmlns: "http://www.sat.gob.mx/CartaPorte31",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/CartaPorte/CartaPorte31.xsd"
end
