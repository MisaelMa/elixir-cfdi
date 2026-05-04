defmodule Cfdi.Xsd.SchemaKey do
  @moduledoc false

  @cfdi "cfdi"
  @concepto "concepto"
  @comprobante "Comprobante"
  @timbre "TimbreFiscalDigital"

  def cfdi, do: @cfdi
  def concepto, do: @concepto
  def comprobante, do: @comprobante
  def timbre, do: @timbre

  @doc false
  def schema_filename(:cfdi), do: "cfdi.json"
  def schema_filename(:concepto), do: "concepto.json"
end
