defmodule Cfdi.Complementos.Gceh do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "gceh:GastosHidrocarburos",
    xmlns: "http://www.sat.gob.mx/GastosHidrocarburos10",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/GastosHidrocarburos10/GastosHidrocarburos10.xsd"
end
