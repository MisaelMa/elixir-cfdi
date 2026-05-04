defmodule Cfdi.Designs do
  @moduledoc """
  PDF layout toolkit for CFDI.

  Default layout: `Cfdi.Designs.PDF117`.
  """

  def pdf117, do: Cfdi.Designs.PDF117

  @doc false
  def version, do: Application.spec(:cfdi_designs, :vsn)
end
