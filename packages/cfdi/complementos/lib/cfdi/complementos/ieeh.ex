defmodule Cfdi.Complementos.Ieeh do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "ieeh:IngresosHidrocarburos",
    xmlns: "http://www.sat.gob.mx/IngresosHidrocarburos10",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/IngresosHidrocarburos10/IngresosHidrocarburos.xsd"
end
