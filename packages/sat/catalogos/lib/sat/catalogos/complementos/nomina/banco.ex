# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catNomina.xsd + catNomina.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Complementos.Nomina.Banco do
  @moduledoc "Catálogo c_Banco del complemento Nómina 1.2 del SAT."

  @type t :: %{value: String.t(), label: String.t(), deprecated: boolean()}

  @entries [
    %{value: "002", label: "BANAMEX", deprecated: false},
    %{value: "006", label: "BANCOMEXT", deprecated: false},
    %{value: "009", label: "BANOBRAS", deprecated: false},
    %{value: "012", label: "BBVA BANCOMER", deprecated: false},
    %{value: "014", label: "SANTANDER", deprecated: false},
    %{value: "019", label: "BANJERCITO", deprecated: false},
    %{value: "021", label: "HSBC", deprecated: false},
    %{value: "030", label: "BAJIO", deprecated: false},
    %{value: "032", label: "IXE", deprecated: false},
    %{value: "036", label: "INBURSA", deprecated: false},
    %{value: "037", label: "INTERACCIONES", deprecated: false},
    %{value: "042", label: "MIFEL", deprecated: false},
    %{value: "044", label: "SCOTIABANK", deprecated: false},
    %{value: "058", label: "BANREGIO", deprecated: false},
    %{value: "059", label: "INVEX", deprecated: false},
    %{value: "060", label: "BANSI", deprecated: false},
    %{value: "062", label: "AFIRME", deprecated: false},
    %{value: "072", label: "BANORTE/IXE", deprecated: false},
    %{value: "102", label: "THE ROYAL BANK", deprecated: false},
    %{value: "103", label: "AMERICAN EXPRESS", deprecated: false},
    %{value: "106", label: "BAMSA", deprecated: false},
    %{value: "108", label: "TOKYO", deprecated: false},
    %{value: "110", label: "JP MORGAN", deprecated: false},
    %{value: "112", label: "BMONEX", deprecated: false},
    %{value: "113", label: "VE POR MAS", deprecated: false},
    %{value: "116", label: "ING", deprecated: false},
    %{value: "124", label: "DEUTSCHE", deprecated: false},
    %{value: "126", label: "CREDIT SUISSE", deprecated: false},
    %{value: "127", label: "AZTECA", deprecated: false},
    %{value: "128", label: "AUTOFIN", deprecated: false},
    %{value: "129", label: "BARCLAYS", deprecated: false},
    %{value: "130", label: "COMPARTAMOS", deprecated: false},
    %{value: "131", label: "BANCO FAMSA", deprecated: false},
    %{value: "132", label: "BMULTIVA", deprecated: false},
    %{value: "133", label: "ACTINVER", deprecated: false},
    %{value: "134", label: "WAL-MART", deprecated: false},
    %{value: "135", label: "NAFIN", deprecated: false},
    %{value: "136", label: "INTERCAM BANCO", deprecated: false},
    %{value: "137", label: "BANCOPPEL", deprecated: false},
    %{value: "138", label: "ABC CAPITAL", deprecated: false},
    %{value: "139", label: "UBS BANK", deprecated: false},
    %{value: "140", label: "CONSUBANCO", deprecated: false},
    %{value: "141", label: "VOLKSWAGEN", deprecated: false},
    %{value: "143", label: "CIBANCO", deprecated: false},
    %{value: "145", label: "BBASE", deprecated: false},
    %{value: "147", label: "BANKAOOL", deprecated: false},
    %{value: "148", label: "PAGATODO", deprecated: false},
    %{value: "149", label: "FORJADORES", deprecated: false},
    %{value: "150", label: "INMOBILIARIO", deprecated: false},
    %{value: "151", label: "DONDÉ", deprecated: false},
    %{value: "152", label: "BANCREA", deprecated: false},
    %{value: "153", label: "PROGRESO", deprecated: false},
    %{value: "154", label: "BANCO FINTERRA", deprecated: false},
    %{value: "155", label: "ICBC", deprecated: false},
    %{value: "156", label: "SABADELL", deprecated: false},
    %{value: "157", label: "SHINHAN", deprecated: false},
    %{value: "158", label: "MIZUHO BANK", deprecated: false},
    %{value: "159", label: "BANK OF CHINA", deprecated: false},
    %{value: "160", label: "BANCO S3", deprecated: false},
    %{value: "166", label: "BANSEFI", deprecated: false},
    %{value: "168", label: "HIPOTECARIA FEDERAL", deprecated: false},
    %{value: "600", label: "MONEXCB", deprecated: false},
    %{value: "601", label: "GBM", deprecated: false},
    %{value: "602", label: "MASARI", deprecated: false},
    %{value: "605", label: "VALUE", deprecated: false},
    %{value: "606", label: "ESTRUCTURADORES", deprecated: false},
    %{value: "607", label: "TIBER", deprecated: false},
    %{value: "608", label: "VECTOR", deprecated: false},
    %{value: "610", label: "B&B", deprecated: false},
    %{value: "614", label: "ACCIVAL", deprecated: false},
    %{value: "615", label: "MERRILL LYNCH", deprecated: false},
    %{value: "616", label: "FINAMEX", deprecated: false},
    %{value: "617", label: "VALMEX", deprecated: false},
    %{value: "618", label: "UNICA", deprecated: false},
    %{value: "619", label: "MAPFRE", deprecated: false},
    %{value: "620", label: "PROFUTURO", deprecated: false},
    %{value: "621", label: "CB ACTINVER", deprecated: false},
    %{value: "622", label: "OACTIN", deprecated: false},
    %{value: "623", label: "SKANDIA", deprecated: false},
    %{value: "626", label: "CBDEUTSCHE", deprecated: false},
    %{value: "627", label: "ZURICH", deprecated: false},
    %{value: "628", label: "ZURICHVI", deprecated: false},
    %{value: "629", label: "SU CASITA", deprecated: false},
    %{value: "630", label: "CB INTERCAM", deprecated: false},
    %{value: "631", label: "CI BOLSA", deprecated: false},
    %{value: "632", label: "BULLTICK CB", deprecated: false},
    %{value: "633", label: "STERLING", deprecated: false},
    %{value: "634", label: "FINCOMUN", deprecated: false},
    %{value: "636", label: "HDI SEGUROS", deprecated: false},
    %{value: "637", label: "ORDER", deprecated: false},
    %{value: "638", label: "AKALA", deprecated: false},
    %{value: "640", label: "CB JPMORGAN", deprecated: false},
    %{value: "642", label: "REFORMA", deprecated: false},
    %{value: "646", label: "STP", deprecated: false},
    %{value: "647", label: "TELECOMM", deprecated: false},
    %{value: "648", label: "EVERCORE", deprecated: false},
    %{value: "649", label: "SKANDIA", deprecated: false},
    %{value: "651", label: "SEGMTY", deprecated: false},
    %{value: "652", label: "ASEA", deprecated: false},
    %{value: "653", label: "KUSPIT", deprecated: false},
    %{value: "655", label: "SOFIEXPRESS", deprecated: false},
    %{value: "656", label: "UNAGRA", deprecated: false},
    %{value: "659", label: "OPCIONES EMPRESARIALES DEL NOROESTE", deprecated: false},
    %{value: "670", label: "LIBERTAD", deprecated: false},
    %{value: "901", label: "CLS", deprecated: false},
    %{value: "902", label: "INDEVAL", deprecated: false}
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
