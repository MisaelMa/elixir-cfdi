defmodule Cfdi.Complementos.NotariosPublicos do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "notariospublicos:NotariosPublicos",
    xmlns: "http://www.sat.gob.mx/notariospublicos",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/notariospublicos/notariospublicos.xsd"
end
