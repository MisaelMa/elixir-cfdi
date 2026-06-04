defmodule Sat.Cfdi.Descarga do
  @moduledoc """
  Cliente del Web Service oficial de Descarga Masiva del SAT.

  Ver `Sat.Cfdi.Descarga.Masiva` para el flujo completo.
  """

  @doc false
  def version, do: Application.spec(:sat_cfdi_descarga, :vsn)
end
