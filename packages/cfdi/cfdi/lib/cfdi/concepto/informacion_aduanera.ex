defmodule Cfdi.Concepto.InformacionAduanera do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:InformacionAduanera"

  attribute :NumeroPedimento, :string
end
