# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.RegimenFiscal do
  @moduledoc "Catálogo c_RegimenFiscal del SAT (CFDI 4.0)."

  @type t :: %{
          value: String.t(),
          label: String.t(),
          persona_fisica: boolean(),
          persona_moral: boolean(),
          inicio_vigencia: Date.t() | nil,
          fin_vigencia: Date.t() | nil,
          deprecated: boolean()
        }

  @entries [
    %{
      value: "601",
      label: "General de Ley Personas Morales",
      persona_fisica: false,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "603",
      label: "Personas Morales con Fines no Lucrativos",
      persona_fisica: false,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "605",
      label: "Sueldos y Salarios e Ingresos Asimilados a Salarios",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "606",
      label: "Arrendamiento",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "607",
      label: "Régimen de Enajenación o Adquisición de Bienes",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "608",
      label: "Demás ingresos",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "609",
      label: "Consolidación",
      persona_fisica: false,
      persona_moral: false,
      inicio_vigencia: nil,
      fin_vigencia: nil,
      deprecated: true
    },
    %{
      value: "610",
      label: "Residentes en el Extranjero sin Establecimiento Permanente en México",
      persona_fisica: true,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "611",
      label: "Ingresos por Dividendos (socios y accionistas)",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "612",
      label: "Personas Físicas con Actividades Empresariales y Profesionales",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "614",
      label: "Ingresos por intereses",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "615",
      label: "Régimen de los ingresos por obtención de premios",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "616",
      label: "Sin obligaciones fiscales",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "620",
      label: "Sociedades Cooperativas de Producción que optan por diferir sus ingresos",
      persona_fisica: false,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "621",
      label: "Incorporación Fiscal",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "622",
      label: "Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras",
      persona_fisica: false,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "623",
      label: "Opcional para Grupos de Sociedades",
      persona_fisica: false,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "624",
      label: "Coordinados",
      persona_fisica: false,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "625",
      label:
        "Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas",
      persona_fisica: true,
      persona_moral: false,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "626",
      label: "Régimen Simplificado de Confianza",
      persona_fisica: true,
      persona_moral: true,
      inicio_vigencia: ~D[2022-01-01],
      fin_vigencia: nil,
      deprecated: false
    },
    %{
      value: "628",
      label: "Hidrocarburos",
      persona_fisica: false,
      persona_moral: false,
      inicio_vigencia: nil,
      fin_vigencia: nil,
      deprecated: true
    },
    %{
      value: "629",
      label: "De los Regímenes Fiscales Preferentes y de las Empresas Multinacionales",
      persona_fisica: false,
      persona_moral: false,
      inicio_vigencia: nil,
      fin_vigencia: nil,
      deprecated: true
    },
    %{
      value: "630",
      label: "Enajenación de acciones en bolsa de valores",
      persona_fisica: false,
      persona_moral: false,
      inicio_vigencia: nil,
      fin_vigencia: nil,
      deprecated: true
    }
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
