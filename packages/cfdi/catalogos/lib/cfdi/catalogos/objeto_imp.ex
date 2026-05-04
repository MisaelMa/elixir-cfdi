# ─────────────────────────────────────────────────────────────
#  Generado por Cfdi.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Cfdi.Catalogos.ObjetoImp do
  @moduledoc "Catálogo c_ObjetoImp del SAT (CFDI 4.0)."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "01", label: "No objeto de impuesto.", deprecated: false},
    %{value: "02", label: "Sí objeto de impuesto.", deprecated: false},
    %{value: "03", label: "Sí objeto del impuesto y no obligado al desglose.", deprecated: false},
    %{value: "04", label: "Sí objeto del impuesto y no causa impuesto.", deprecated: false},
    %{value: "05", label: "Sí objeto del impuesto, IVA crédito PODEBI.", deprecated: false},
    %{value: "06", label: "Sí objeto del IVA, No traslado IVA.", deprecated: false},
    %{value: "07", label: "No traslado del IVA, Sí desglose IEPS.", deprecated: false},
    %{value: "08", label: "No traslado del IVA, No desglose IEPS.", deprecated: false}
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
