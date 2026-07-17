defmodule Cfdi.Complementos.Ine do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "ine:INE",
    xmlns: "http://www.sat.gob.mx/ine",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/ine/ine11.xsd"
end
