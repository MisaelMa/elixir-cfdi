defmodule Cfdi.Complementos.ValesDeDespensa do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "valesdedespensa:ValesDeDespensa",
    xmlns: "http://www.sat.gob.mx/valesdedespensa",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/valesdedespensa/valesdedespensa.xsd"
end
