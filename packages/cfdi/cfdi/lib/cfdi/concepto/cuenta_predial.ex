defmodule Cfdi.Concepto.CuentaPredial do
  @moduledoc false

  use Cfdi.Xml.Element, tag: "cfdi:CuentaPredial"

  attribute :Numero, :string
end
