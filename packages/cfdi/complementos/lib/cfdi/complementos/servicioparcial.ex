defmodule Cfdi.Complementos.ServicioParcial do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "servicioparcial:parcialesconstruccion",
    xmlns: "http://www.sat.gob.mx/servicioparcialconstruccion",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/servicioparcialconstruccion/servicioparcialconstruccion.xsd"
end
