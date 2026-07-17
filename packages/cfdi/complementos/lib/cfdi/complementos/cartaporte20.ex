defmodule Cfdi.Complementos.CartaPorte20 do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "cartaporte20:CartaPorte",
    xmlns: "http://www.sat.gob.mx/CartaPorte20",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/CartaPorte/CartaPorte20.xsd"
end
