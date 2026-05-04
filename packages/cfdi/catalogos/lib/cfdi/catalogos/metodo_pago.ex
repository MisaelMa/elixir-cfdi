# ─────────────────────────────────────────────────────────────
#  Generado por Cfdi.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Cfdi.Catalogos.MetodoPago do
  @moduledoc "Catálogo c_MetodoPago del SAT (CFDI 4.0)."

  @type t :: :pago_en_una_exhibicion | :pago_en_parcialidades_diferido

  @entries [
    %{
      value: :pago_en_una_exhibicion,
      code: "PUE",
      label: "Pago en una sola exhibición",
      deprecated: false
    },
    %{
      value: :pago_en_parcialidades_diferido,
      code: "PPD",
      label: "Pago en parcialidades o diferido",
      deprecated: false
    }
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:pago_en_una_exhibicion), do: "PUE"
  def value(:pago_en_parcialidades_diferido), do: "PPD"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("PUE"),
    do:
      {:ok,
       %{
         value: :pago_en_una_exhibicion,
         code: "PUE",
         label: "Pago en una sola exhibición",
         deprecated: false
       }}

  def from_code("PPD"),
    do:
      {:ok,
       %{
         value: :pago_en_parcialidades_diferido,
         code: "PPD",
         label: "Pago en parcialidades o diferido",
         deprecated: false
       }}

  def from_code(_), do: :error
end
