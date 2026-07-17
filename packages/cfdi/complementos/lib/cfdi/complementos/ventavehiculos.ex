defmodule Cfdi.Complementos.VentaVehiculos do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "ventavehiculos:VentaVehiculos",
    xmlns: "http://www.sat.gob.mx/ventavehiculos",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/ventavehiculos/ventavehiculos11.xsd"
end
