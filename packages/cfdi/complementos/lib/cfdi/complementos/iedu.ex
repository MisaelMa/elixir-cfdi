defmodule Cfdi.Complementos.Iedu do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "iedu:instEducativas",
    xmlns: "http://www.sat.gob.mx/iedu",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/iedu/iedu.xsd"
end
