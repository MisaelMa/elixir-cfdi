defmodule Cfdi.Descarga do
  @moduledoc """
  Cliente SOAP para *Descarga Masiva* de CFDI del SAT (`Cfdi.Descarga.DescargaMasiva`).
  """

  @doc false
  def version, do: Application.spec(:cfdi_descarga, :vsn)
end
