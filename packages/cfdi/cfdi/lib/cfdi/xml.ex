defmodule Cfdi.Xml do
  @moduledoc """
  Orquestación de la generación de XML CFDI 4.0: comprobante, complementos,
  cadena original y firma.

  La API principal vive en `Cfdi.Xml.Cfdi`. Los elementos CFDI (struct +
  serialización XML) se definen con el macro `Cfdi.Xml.Element` y viven
  bajo `Cfdi.*` (ej. `Cfdi.Comprobante`, `Cfdi.Emisor`, `Cfdi.Concepto`).
  """

end
