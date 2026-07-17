defmodule Cfdi.Complementos.Decreto do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "decreto:renovacionysustitucionvehiculos",
    xmlns: "http://www.sat.gob.mx/renovacionysustitucionvehiculos",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/renovacionysustitucionvehiculos/renovacionysustitucionvehiculos.xsd"
end
