defmodule Cfdi.Complementos.Ecc12 do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "ecc12:EstadoDeCuentaCombustible",
    xmlns: "http://www.sat.gob.mx/EstadoDeCuentaCombustible12",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/EstadoDeCuentaCombustible/ecc12.xsd"
end
