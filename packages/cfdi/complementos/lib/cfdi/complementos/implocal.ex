defmodule Cfdi.Complementos.ImpLocal do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "implocal:ImpuestosLocales",
    xmlns: "http://www.sat.gob.mx/implocal",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/implocal/implocal.xsd"
end
