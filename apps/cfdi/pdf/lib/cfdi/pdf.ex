defmodule Cfdi.Pdf do
  @moduledoc """
  Tipos y opciones para generación de PDF de CFDI.
  """

  @pdf_version "1.0"

  @spec pdf_version() :: String.t()
  def pdf_version, do: @pdf_version
end
