defmodule Cfdi.Complementos.Tfd do
  @moduledoc false

  use Cfdi.Complementos.Complemento,
    key: "tfd:TimbreFiscalDigital",
    xmlns: "http://www.sat.gob.mx/TimbreFiscalDigital",
    xsd: "http://www.sat.gob.mx/sitio_internet/cfd/TimbreFiscalDigital/TimbreFiscalDigitalv11.xsd"
end
