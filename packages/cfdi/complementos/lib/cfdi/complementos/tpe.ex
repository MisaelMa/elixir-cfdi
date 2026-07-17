defmodule Cfdi.Complementos.Tpe do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "tpe:TuristaPasajeroExtranjero",
    xmlns: "http://www.sat.gob.mx/TuristaPasajeroExtranjero",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/TuristaPasajeroExtranjero/TuristaPasajeroExtranjero.xsd"
end
