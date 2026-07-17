defmodule Cfdi.Complementos.Aerolineas do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "aerolineas:Aerolineas",
    xmlns: "http://www.sat.gob.mx/aerolineas",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/aerolineas/aerolineas.xsd"
end
