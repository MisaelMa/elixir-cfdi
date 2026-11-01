# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.TipoRegimen do
  @moduledoc "Catálogo c_TipoRegimen del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{
      value: "02",
      label: "Sueldos (Incluye ingresos señalados en la fracción I del artículo 94 de LISR)",
      deprecated: false
    },
    %{value: "03", label: "Jubilados", deprecated: false},
    %{value: "04", label: "Pensionados", deprecated: false},
    %{
      value: "05",
      label: "Asimilados Miembros Sociedades Cooperativas Produccion",
      deprecated: false
    },
    %{
      value: "06",
      label: "Asimilados Integrantes Sociedades Asociaciones Civiles",
      deprecated: false
    },
    %{value: "07", label: "Asimilados Miembros consejos", deprecated: false},
    %{value: "08", label: "Asimilados comisionistas", deprecated: false},
    %{value: "09", label: "Asimilados Honorarios", deprecated: false},
    %{value: "10", label: "Asimilados acciones", deprecated: false},
    %{value: "11", label: "Asimilados otros", deprecated: false},
    %{value: "12", label: "Jubilados o Pensionados", deprecated: false},
    %{value: "13", label: "Indemnización o Separación", deprecated: false},
    %{value: "99", label: "Otro Regimen", deprecated: false}
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
