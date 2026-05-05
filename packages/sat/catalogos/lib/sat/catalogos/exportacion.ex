# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Exportacion do
  @moduledoc "Catálogo c_Exportacion del SAT (CFDI 4.0)."

  @type t :: :no_aplica | :definitiva | :temporal | :definitiva_distinta_a1

  @entries [
    %{value: :no_aplica, code: "01", label: "No aplica", deprecated: false},
    %{value: :definitiva, code: "02", label: "Definitiva con clave A1", deprecated: false},
    %{value: :temporal, code: "03", label: "Temporal", deprecated: false},
    %{
      value: :definitiva_distinta_a1,
      code: "04",
      label:
        "Definitiva con clave distinta a A1 o cuando no existe enajenación en términos del CFF",
      deprecated: false
    }
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:no_aplica), do: "01"
  def value(:definitiva), do: "02"
  def value(:temporal), do: "03"
  def value(:definitiva_distinta_a1), do: "04"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("01"),
    do: {:ok, %{value: :no_aplica, code: "01", label: "No aplica", deprecated: false}}

  def from_code("02"),
    do:
      {:ok,
       %{value: :definitiva, code: "02", label: "Definitiva con clave A1", deprecated: false}}

  def from_code("03"),
    do: {:ok, %{value: :temporal, code: "03", label: "Temporal", deprecated: false}}

  def from_code("04"),
    do:
      {:ok,
       %{
         value: :definitiva_distinta_a1,
         code: "04",
         label:
           "Definitiva con clave distinta a A1 o cuando no existe enajenación en términos del CFF",
         deprecated: false
       }}

  def from_code(_), do: :error
end
