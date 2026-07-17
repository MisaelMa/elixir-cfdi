defmodule Cfdi.Complementos.Pfic do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "pfic:PFintegranteCoordinado",
    xmlns: "http://www.sat.gob.mx/pfic",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/pfic/pfic.xsd"
end
