# ─────────────────────────────────────────────────────────────
#  Generado por Cfdi.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Cfdi.Catalogos.Meses do
  @moduledoc "Catálogo c_Meses del SAT (CFDI 4.0)."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "01", label: "Enero", deprecated: false},
    %{value: "02", label: "Febrero", deprecated: false},
    %{value: "03", label: "Marzo", deprecated: false},
    %{value: "04", label: "Abril", deprecated: false},
    %{value: "05", label: "Mayo", deprecated: false},
    %{value: "06", label: "Junio", deprecated: false},
    %{value: "07", label: "Julio", deprecated: false},
    %{value: "08", label: "Agosto", deprecated: false},
    %{value: "09", label: "Septiembre", deprecated: false},
    %{value: "10", label: "Octubre", deprecated: false},
    %{value: "11", label: "Noviembre", deprecated: false},
    %{value: "12", label: "Diciembre", deprecated: false},
    %{value: "13", label: "Enero-Febrero", deprecated: false},
    %{value: "14", label: "Marzo-Abril", deprecated: false},
    %{value: "15", label: "Mayo-Junio", deprecated: false},
    %{value: "16", label: "Julio-Agosto", deprecated: false},
    %{value: "17", label: "Septiembre-Octubre", deprecated: false},
    %{value: "18", label: "Noviembre-Diciembre", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.value == code))
  def valid?(_), do: false

  @doc "Busca una entrada por su código."
  def from_code(code) when is_binary(code) do
    case Enum.find(@entries, &(&1.value == code)) do
      nil -> :error
      entry -> {:ok, entry}
    end
  end
end
