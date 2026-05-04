# ─────────────────────────────────────────────────────────────
#  Generado por Cfdi.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Cfdi.Catalogos.TipoRelacion do
  @moduledoc "Catálogo c_TipoRelacion del SAT (CFDI 4.0)."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "01", label: "Nota de crédito de los documentos relacionados", deprecated: false},
    %{value: "02", label: "Nota de débito de los documentos relacionados", deprecated: false},
    %{
      value: "03",
      label: "Devolución de mercancía sobre facturas o traslados previos",
      deprecated: false
    },
    %{value: "04", label: "Sustitución de los CFDI previos", deprecated: false},
    %{value: "05", label: "Traslados de mercancías facturados previamente", deprecated: false},
    %{value: "06", label: "Factura generada por los traslados previos", deprecated: false},
    %{value: "07", label: "CFDI por aplicación de anticipo", deprecated: false},
    %{value: "08", label: "Factura generada por pagos en parcialidades", deprecated: true},
    %{value: "09", label: "Factura generada por pagos diferidos", deprecated: true}
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
