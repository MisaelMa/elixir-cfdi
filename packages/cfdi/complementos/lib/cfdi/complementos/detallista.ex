defmodule Cfdi.Complementos.Detallista do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "detallista:detallista",
    xmlns: "http://www.sat.gob.mx/detallista",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/detallista/detallista.xsd"
end
