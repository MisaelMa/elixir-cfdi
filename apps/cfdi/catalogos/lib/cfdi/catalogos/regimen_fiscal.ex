defmodule Cfdi.Catalogos.RegimenFiscal do
  @moduledoc """
  Catálogo de regímenes fiscales del SAT (c_RegimenFiscal).
  """

  @type regimen_fiscal_code :: String.t()

  @spec list() :: [map()]
  def list do
    [
      %{value: 601, descripcion: "General de Ley Personas Morales", person_type: %{fisica: false, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 603, descripcion: "Personas Morales con Fines no Lucrativos", person_type: %{fisica: false, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 605, descripcion: "Sueldos y Salarios e Ingresos Asimilados a Salarios", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 606, descripcion: "Arrendamiento", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 607, descripcion: "Régimen de Enajenación o Adquisición de Bienes", person_type: %{fisica: false, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 608, descripcion: "Demás ingresos", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 609, descripcion: "Consolidación", person_type: %{fisica: false, moral: true}, start_date: "12/11/2016", ending_date: "31/12/2019"},
      %{value: 610, descripcion: "Residentes en el Extranjero sin Establecimiento Permanente en México", person_type: %{fisica: true, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 611, descripcion: "Ingresos por Dividendos (socios y accionistas)", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 612, descripcion: "Personas Físicas con Actividades Empresariales y Profesionales", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 614, descripcion: "Ingresos por intereses", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 615, descripcion: "Régimen de los ingresos por obtención de premios", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 616, descripcion: "Sin obligaciones fiscales", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 620, descripcion: "Sociedades Cooperativas de Producción que optan por diferir sus ingresos", person_type: %{fisica: false, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 621, descripcion: "Incorporación Fiscal", person_type: %{fisica: true, moral: false}, start_date: "12/11/2016", ending_date: ""},
      %{value: 622, descripcion: "Actividades Agrícolas, Ganaderas, Silvícolas y Pesqueras", person_type: %{fisica: true, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 623, descripcion: "Opcional para Grupos de Sociedades", person_type: %{fisica: false, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 624, descripcion: "Coordinados", person_type: %{fisica: false, moral: true}, start_date: "12/11/2016", ending_date: ""},
      %{value: 625, descripcion: "Régimen de las Actividades Empresariales con ingresos a través de Plataformas Tecnológicas", person_type: %{fisica: true, moral: false}, start_date: "01/06/2020", ending_date: ""},
      %{value: 628, descripcion: "Hidrocarburos", person_type: %{fisica: false, moral: true}, start_date: "01/01/2024", ending_date: ""},
      %{value: 629, descripcion: "De los Regímenes Fiscales Preferentes y de las Empresas Multinacionales", person_type: %{fisica: true, moral: false}, start_date: "01/01/2024", ending_date: ""},
      %{value: 630, descripcion: "Enajenación de acciones en bolsa de valores", person_type: %{fisica: true, moral: false}, start_date: "01/01/2024", ending_date: ""}
    ]
  end

  @valid_codes ~w(601 603 605 606 607 608 609 610 611 612 614 615 616 620 621 622 623 624 625 628 629 630)

  @spec valid?(String.t() | integer()) :: boolean()
  def valid?(code) when is_integer(code), do: Integer.to_string(code) in @valid_codes
  def valid?(code) when is_binary(code), do: code in @valid_codes

  @spec descripcion(integer() | String.t()) :: String.t() | nil
  def descripcion(code) do
    code_int = if is_binary(code), do: String.to_integer(code), else: code

    case Enum.find(list(), fn r -> r.value == code_int end) do
      nil -> nil
      regimen -> regimen.descripcion
    end
  end
end
