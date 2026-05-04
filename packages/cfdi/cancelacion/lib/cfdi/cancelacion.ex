defmodule Cfdi.Cancelacion do
  @moduledoc """
  Cliente SOAP para cancelación y aceptación/rechazo de CFDI ante el SAT.
  """

  @doc false
  def version, do: Application.spec(:cfdi_cancelacion, :vsn)
end
