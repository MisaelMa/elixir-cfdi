defmodule Cfdi.InformacionGlobal do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:InformacionGlobal"

  attribute :Periodicidad, :string
  attribute :Meses, :string
  attribute :Año, :string
end
