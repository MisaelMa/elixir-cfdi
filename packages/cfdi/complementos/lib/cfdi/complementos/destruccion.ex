defmodule Cfdi.Complementos.Destruccion do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "destruccion:certificadodedestruccion",
    xmlns: "http://www.sat.gob.mx/certificadodestruccion",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/certificadodestruccion/certificadodedestruccion.xsd"
end
