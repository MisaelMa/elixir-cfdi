defmodule Cfdi.Receptor do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:Receptor"

  attribute :Rfc, :string
  attribute :Nombre, :string
  attribute :UsoCFDI, :string
  attribute :DomicilioFiscalReceptor, :string
  attribute :ResidenciaFiscal, :string
  attribute :NumRegIdTrib, :string
  attribute :RegimenFiscalReceptor, :string
end
