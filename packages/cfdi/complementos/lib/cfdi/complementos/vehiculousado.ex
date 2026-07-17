defmodule Cfdi.Complementos.VehiculoUsado do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "vehiculousado:VehiculoUsado",
    xmlns: "http://www.sat.gob.mx/vehiculousado",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/vehiculousado/vehiculousado.xsd"
end
