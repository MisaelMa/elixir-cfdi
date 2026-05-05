# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.FormaPago do
  @moduledoc "Catálogo c_FormaPago del SAT (CFDI 4.0)."

  @type t :: :efectivo | :cheque_nominativo

  @entries [
    %{value: :efectivo, code: "01", label: "Efectivo", deprecated: false},
    %{value: :cheque_nominativo, code: "02", label: "Cheque nominativo", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:efectivo), do: "01"
  def value(:cheque_nominativo), do: "02"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("01"),
    do: {:ok, %{value: :efectivo, code: "01", label: "Efectivo", deprecated: false}}

  def from_code("02"),
    do:
      {:ok,
       %{value: :cheque_nominativo, code: "02", label: "Cheque nominativo", deprecated: false}}

  def from_code(_), do: :error
end
