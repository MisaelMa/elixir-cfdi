defmodule Cfdi.Concepto.ACuentaTerceros do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:ACuentaTerceros"

  attribute :RfcACuentaTerceros, :string
  attribute :NombreACuentaTerceros, :string
  attribute :RegimenFiscalACuentaTerceros, :string
  attribute :DomicilioFiscalACuentaTerceros, :string
end
