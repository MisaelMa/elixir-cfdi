defmodule Cfdi.Csf do
  @moduledoc """
  Parsing helpers for CSF PDF text (`Cfdi.Csf.Parser`).
  """

  @doc false
  def version, do: Application.spec(:cfdi_csf, :vsn)
end
