# ─────────────────────────────────────────────────────────────
#  Generado por Cfdi.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Cfdi.Catalogos.Impuesto do
  @moduledoc "Catálogo c_Impuesto del SAT (CFDI 4.0)."

  @type t :: :isr | :iva | :ieps

  @entries [
    %{value: :isr, code: "001", label: "ISR", deprecated: false},
    %{value: :iva, code: "002", label: "IVA", deprecated: false},
    %{value: :ieps, code: "003", label: "IEPS", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:isr), do: "001"
  def value(:iva), do: "002"
  def value(:ieps), do: "003"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("001"), do: {:ok, %{value: :isr, code: "001", label: "ISR", deprecated: false}}
  def from_code("002"), do: {:ok, %{value: :iva, code: "002", label: "IVA", deprecated: false}}
  def from_code("003"), do: {:ok, %{value: :ieps, code: "003", label: "IEPS", deprecated: false}}
  def from_code(_), do: :error
end
