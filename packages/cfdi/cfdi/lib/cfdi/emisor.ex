defmodule Cfdi.Emisor do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Emisor"

  attribute :Rfc, :string
  attribute :Nombre, :string
  attribute :RegimenFiscal, :string
  attribute :FacAtrAdquirente, :string
end
