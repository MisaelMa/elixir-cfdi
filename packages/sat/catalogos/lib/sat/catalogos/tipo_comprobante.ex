# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.TipoComprobante do
  @moduledoc "Catálogo c_TipoDeComprobante del SAT (CFDI 4.0)."

  @type t :: :ingreso | :egreso | :traslado | :nomina | :pago

  @entries [
    %{value: :ingreso, code: "I", label: "Ingreso", deprecated: false},
    %{value: :egreso, code: "E", label: "Egreso", deprecated: false},
    %{value: :traslado, code: "T", label: "Traslado", deprecated: false},
    %{value: :nomina, code: "N", label: "Nómina", deprecated: false},
    %{value: :pago, code: "P", label: "Pago", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:ingreso), do: "I"
  def value(:egreso), do: "E"
  def value(:traslado), do: "T"
  def value(:nomina), do: "N"
  def value(:pago), do: "P"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("I"),
    do: {:ok, %{value: :ingreso, code: "I", label: "Ingreso", deprecated: false}}

  def from_code("E"), do: {:ok, %{value: :egreso, code: "E", label: "Egreso", deprecated: false}}

  def from_code("T"),
    do: {:ok, %{value: :traslado, code: "T", label: "Traslado", deprecated: false}}

  def from_code("N"), do: {:ok, %{value: :nomina, code: "N", label: "Nómina", deprecated: false}}
  def from_code("P"), do: {:ok, %{value: :pago, code: "P", label: "Pago", deprecated: false}}
  def from_code(_), do: :error
end
