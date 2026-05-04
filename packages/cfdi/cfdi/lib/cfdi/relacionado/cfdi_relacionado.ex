defmodule Cfdi.Relacionado.CfdiRelacionado do
  @moduledoc """
  UUID individual dentro de un grupo `cfdi:CfdiRelacionados`.
  """

  use Cfdi.Xml.Element, tag: "cfdi:CfdiRelacionado"

  attribute :UUID, :string
end
