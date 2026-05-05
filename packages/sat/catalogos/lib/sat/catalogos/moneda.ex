# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.Moneda do
  @moduledoc "Catálogo c_Moneda del SAT (CFDI 4.0)."

  @type t ::
          :AED
          | :AFN
          | :ALL
          | :AMD
          | :ANG
          | :AOA
          | :ARS
          | :AUD
          | :AWG
          | :AZN
          | :BAM
          | :BBD
          | :BDT
          | :BGN
          | :BHD
          | :BIF
          | :BMD
          | :BND
          | :BOB
          | :BOV
          | :BRL
          | :BSD
          | :BTN
          | :BWP
          | :BYR
          | :BZD
          | :CAD
          | :CDF
          | :CHE
          | :CHF
          | :CHW
          | :CLF
          | :CLP
          | :CNH
          | :CNY
          | :COP
          | :COU
          | :CRC
          | :CUC
          | :CUP
          | :CVE
          | :CZK
          | :DJF
          | :DKK
          | :DOP
          | :DZD
          | :EGP
          | :ERN
          | :ESD
          | :ETB
          | :EUR
          | :FJD
          | :FKP
          | :GBP
          | :GEL
          | :GHS
          | :GIP
          | :GMD
          | :GNF
          | :GTQ
          | :GYD
          | :HKD
          | :HNL
          | :HRK
          | :HTG
          | :HUF
          | :IDR
          | :ILS
          | :INR
          | :IQD
          | :IRR
          | :ISK
          | :JMD
          | :JOD
          | :JPY
          | :KES
          | :KGS
          | :KHR
          | :KMF
          | :KPW
          | :KRW
          | :KWD
          | :KYD
          | :KZT
          | :LAK
          | :LBP
          | :LKR
          | :LRD
          | :LSL
          | :LYD
          | :MAD
          | :MDL
          | :MGA
          | :MKD
          | :MMK
          | :MNT
          | :MOP
          | :MRO
          | :MUR
          | :MVR
          | :MWK
          | :MXN
          | :MXV
          | :MYR
          | :MZN
          | :NAD
          | :NGN
          | :NIC
          | :NIO
          | :NOK
          | :NPR
          | :NZD
          | :OMR
          | :PAB
          | :PEN
          | :PGK
          | :PHP
          | :PKR
          | :PLN
          | :PYG
          | :QAR
          | :RON
          | :RSD
          | :RUB
          | :RWF
          | :SAR
          | :SBD
          | :SCR
          | :SDG
          | :SEK
          | :SGD
          | :SHP
          | :SLL
          | :SOS
          | :SRD
          | :SSP
          | :STD
          | :SVC
          | :SYP
          | :SZL
          | :THB
          | :TJS
          | :TMT
          | :TND
          | :TOP
          | :TRY
          | :TTD
          | :TWD
          | :TZS
          | :UAH
          | :UGX
          | :USD
          | :USN
          | :UYI
          | :UYP
          | :UYU
          | :UZS
          | :VEF
          | :VES
          | :VND
          | :VUV
          | :WST
          | :XAF
          | :XAG
          | :XAU
          | :XBA
          | :XBB
          | :XBC
          | :XBD
          | :XCD
          | :XDR
          | :XOF
          | :XPD
          | :XPF
          | :XPT
          | :XSU
          | :XTS
          | :XUA
          | :XXX
          | :YER
          | :ZAR
          | :ZMW
          | :ZWL

  @entries [
    %{value: :AED, code: "AED", label: "Dirham de EAU", deprecated: false},
    %{value: :AFN, code: "AFN", label: "Afghani", deprecated: false},
    %{value: :ALL, code: "ALL", label: "Lek", deprecated: false},
    %{value: :AMD, code: "AMD", label: "Dram armenio", deprecated: false},
    %{value: :ANG, code: "ANG", label: "Florín antillano neerlandés", deprecated: false},
    %{value: :AOA, code: "AOA", label: "Kwanza", deprecated: false},
    %{value: :ARS, code: "ARS", label: "Peso Argentino", deprecated: false},
    %{value: :AUD, code: "AUD", label: "Dólar Australiano", deprecated: false},
    %{value: :AWG, code: "AWG", label: "Aruba Florin", deprecated: false},
    %{value: :AZN, code: "AZN", label: "Azerbaijanian Manat", deprecated: false},
    %{value: :BAM, code: "BAM", label: "Convertibles marca", deprecated: false},
    %{value: :BBD, code: "BBD", label: "Dólar de Barbados", deprecated: false},
    %{value: :BDT, code: "BDT", label: "Taka", deprecated: false},
    %{value: :BGN, code: "BGN", label: "Lev búlgaro", deprecated: false},
    %{value: :BHD, code: "BHD", label: "Dinar de Bahrein", deprecated: false},
    %{value: :BIF, code: "BIF", label: "Burundi Franc", deprecated: false},
    %{value: :BMD, code: "BMD", label: "Dólar de Bermudas", deprecated: false},
    %{value: :BND, code: "BND", label: "Dólar de Brunei", deprecated: false},
    %{value: :BOB, code: "BOB", label: "Boliviano", deprecated: false},
    %{value: :BOV, code: "BOV", label: "Mvdol", deprecated: false},
    %{value: :BRL, code: "BRL", label: "Real brasileño", deprecated: false},
    %{value: :BSD, code: "BSD", label: "Dólar de las Bahamas", deprecated: false},
    %{value: :BTN, code: "BTN", label: "Ngultrum", deprecated: false},
    %{value: :BWP, code: "BWP", label: "Pula", deprecated: false},
    %{value: :BYR, code: "BYR", label: "Rublo bielorruso", deprecated: false},
    %{value: :BZD, code: "BZD", label: "Dólar de Belice", deprecated: false},
    %{value: :CAD, code: "CAD", label: "Dólar Canadiense", deprecated: false},
    %{value: :CDF, code: "CDF", label: "Franco congoleño", deprecated: false},
    %{value: :CHE, code: "CHE", label: "WIR Euro", deprecated: false},
    %{value: :CHF, code: "CHF", label: "Franco Suizo", deprecated: false},
    %{value: :CHW, code: "CHW", label: "Franc WIR", deprecated: false},
    %{value: :CLF, code: "CLF", label: "Unidad de Fomento", deprecated: false},
    %{value: :CLP, code: "CLP", label: "Peso chileno", deprecated: false},
    %{value: :CNH, code: "CNH", label: "Yuan extracontinental (China )", deprecated: false},
    %{value: :CNY, code: "CNY", label: "Yuan Renminbi", deprecated: false},
    %{value: :COP, code: "COP", label: "Peso Colombiano", deprecated: false},
    %{value: :COU, code: "COU", label: "Unidad de Valor real", deprecated: false},
    %{value: :CRC, code: "CRC", label: "Colón costarricense", deprecated: false},
    %{value: :CUC, code: "CUC", label: "Peso Convertible", deprecated: false},
    %{value: :CUP, code: "CUP", label: "Peso Cubano", deprecated: false},
    %{value: :CVE, code: "CVE", label: "Cabo Verde Escudo", deprecated: false},
    %{value: :CZK, code: "CZK", label: "Corona checa", deprecated: false},
    %{value: :DJF, code: "DJF", label: "Franco de Djibouti", deprecated: false},
    %{value: :DKK, code: "DKK", label: "Corona danesa", deprecated: false},
    %{value: :DOP, code: "DOP", label: "Peso Dominicano", deprecated: false},
    %{value: :DZD, code: "DZD", label: "Dinar argelino", deprecated: false},
    %{value: :EGP, code: "EGP", label: "Libra egipcia", deprecated: false},
    %{value: :ERN, code: "ERN", label: "Nakfa", deprecated: false},
    %{value: :ESD, code: "ESD", label: "Dólar de Ecuador", deprecated: false},
    %{value: :ETB, code: "ETB", label: "Birr etíope", deprecated: false},
    %{value: :EUR, code: "EUR", label: "Euro", deprecated: false},
    %{value: :FJD, code: "FJD", label: "Dólar de Fiji", deprecated: false},
    %{value: :FKP, code: "FKP", label: "Libra malvinense", deprecated: false},
    %{value: :GBP, code: "GBP", label: "Libra Esterlina", deprecated: false},
    %{value: :GEL, code: "GEL", label: "Lari", deprecated: false},
    %{value: :GHS, code: "GHS", label: "Cedi de Ghana", deprecated: false},
    %{value: :GIP, code: "GIP", label: "Libra de Gibraltar", deprecated: false},
    %{value: :GMD, code: "GMD", label: "Dalasi", deprecated: false},
    %{value: :GNF, code: "GNF", label: "Franco guineano", deprecated: false},
    %{value: :GTQ, code: "GTQ", label: "Quetzal", deprecated: false},
    %{value: :GYD, code: "GYD", label: "Dólar guyanés", deprecated: false},
    %{value: :HKD, code: "HKD", label: "Dólar De Hong Kong", deprecated: false},
    %{value: :HNL, code: "HNL", label: "Lempira", deprecated: false},
    %{value: :HRK, code: "HRK", label: "Kuna", deprecated: false},
    %{value: :HTG, code: "HTG", label: "Gourde", deprecated: false},
    %{value: :HUF, code: "HUF", label: "Florín", deprecated: false},
    %{value: :IDR, code: "IDR", label: "Rupia", deprecated: false},
    %{value: :ILS, code: "ILS", label: "Nuevo Shekel Israelí", deprecated: false},
    %{value: :INR, code: "INR", label: "Rupia india", deprecated: false},
    %{value: :IQD, code: "IQD", label: "Dinar iraquí", deprecated: false},
    %{value: :IRR, code: "IRR", label: "Rial iraní", deprecated: false},
    %{value: :ISK, code: "ISK", label: "Corona islandesa", deprecated: false},
    %{value: :JMD, code: "JMD", label: "Dólar Jamaiquino", deprecated: false},
    %{value: :JOD, code: "JOD", label: "Dinar jordano", deprecated: false},
    %{value: :JPY, code: "JPY", label: "Yen", deprecated: false},
    %{value: :KES, code: "KES", label: "Chelín keniano", deprecated: false},
    %{value: :KGS, code: "KGS", label: "Som", deprecated: false},
    %{value: :KHR, code: "KHR", label: "Riel", deprecated: false},
    %{value: :KMF, code: "KMF", label: "Franco Comoro", deprecated: false},
    %{value: :KPW, code: "KPW", label: "Corea del Norte ganó", deprecated: false},
    %{value: :KRW, code: "KRW", label: "Won", deprecated: false},
    %{value: :KWD, code: "KWD", label: "Dinar kuwaití", deprecated: false},
    %{value: :KYD, code: "KYD", label: "Dólar de las Islas Caimán", deprecated: false},
    %{value: :KZT, code: "KZT", label: "Tenge", deprecated: false},
    %{value: :LAK, code: "LAK", label: "Kip", deprecated: false},
    %{value: :LBP, code: "LBP", label: "Libra libanesa", deprecated: false},
    %{value: :LKR, code: "LKR", label: "Rupia de Sri Lanka", deprecated: false},
    %{value: :LRD, code: "LRD", label: "Dólar liberiano", deprecated: false},
    %{value: :LSL, code: "LSL", label: "Loti", deprecated: false},
    %{value: :LYD, code: "LYD", label: "Dinar libio", deprecated: false},
    %{value: :MAD, code: "MAD", label: "Dirham marroquí", deprecated: false},
    %{value: :MDL, code: "MDL", label: "Leu moldavo", deprecated: false},
    %{value: :MGA, code: "MGA", label: "Ariary malgache", deprecated: false},
    %{value: :MKD, code: "MKD", label: "Denar", deprecated: false},
    %{value: :MMK, code: "MMK", label: "Kyat", deprecated: false},
    %{value: :MNT, code: "MNT", label: "Tugrik", deprecated: false},
    %{value: :MOP, code: "MOP", label: "Pataca", deprecated: false},
    %{value: :MRO, code: "MRO", label: "Ouguiya", deprecated: false},
    %{value: :MUR, code: "MUR", label: "Rupia de Mauricio", deprecated: false},
    %{value: :MVR, code: "MVR", label: "Rupia", deprecated: false},
    %{value: :MWK, code: "MWK", label: "Kwacha", deprecated: false},
    %{value: :MXN, code: "MXN", label: "Peso Mexicano", deprecated: false},
    %{value: :MXV, code: "MXV", label: "México Unidad de Inversión (UDI)", deprecated: false},
    %{value: :MYR, code: "MYR", label: "Ringgit malayo", deprecated: false},
    %{value: :MZN, code: "MZN", label: "Mozambique Metical", deprecated: false},
    %{value: :NAD, code: "NAD", label: "Dólar de Namibia", deprecated: false},
    %{value: :NGN, code: "NGN", label: "Naira", deprecated: false},
    %{value: :NIC, code: "NIC", label: "Córdoba (Nicaragua)", deprecated: false},
    %{value: :NIO, code: "NIO", label: "Córdoba Oro", deprecated: false},
    %{value: :NOK, code: "NOK", label: "Corona noruega", deprecated: false},
    %{value: :NPR, code: "NPR", label: "Rupia nepalí", deprecated: false},
    %{value: :NZD, code: "NZD", label: "Dólar de Nueva Zelanda", deprecated: false},
    %{value: :OMR, code: "OMR", label: "Rial omaní", deprecated: false},
    %{value: :PAB, code: "PAB", label: "Balboa", deprecated: false},
    %{value: :PEN, code: "PEN", label: "Nuevo Sol", deprecated: false},
    %{value: :PGK, code: "PGK", label: "Kina", deprecated: false},
    %{value: :PHP, code: "PHP", label: "Peso filipino", deprecated: false},
    %{value: :PKR, code: "PKR", label: "Rupia de Pakistán", deprecated: false},
    %{value: :PLN, code: "PLN", label: "Zloty", deprecated: false},
    %{value: :PYG, code: "PYG", label: "Guaraní", deprecated: false},
    %{value: :QAR, code: "QAR", label: "Qatar Rial", deprecated: false},
    %{value: :RON, code: "RON", label: "Leu rumano", deprecated: false},
    %{value: :RSD, code: "RSD", label: "Dinar serbio", deprecated: false},
    %{value: :RUB, code: "RUB", label: "Rublo ruso", deprecated: false},
    %{value: :RWF, code: "RWF", label: "Franco ruandés", deprecated: false},
    %{value: :SAR, code: "SAR", label: "Riyal saudí", deprecated: false},
    %{value: :SBD, code: "SBD", label: "Dólar de las Islas Salomón", deprecated: false},
    %{value: :SCR, code: "SCR", label: "Rupia de Seychelles", deprecated: false},
    %{value: :SDG, code: "SDG", label: "Libra sudanesa", deprecated: false},
    %{value: :SEK, code: "SEK", label: "Corona sueca", deprecated: false},
    %{value: :SGD, code: "SGD", label: "Dólar De Singapur", deprecated: false},
    %{value: :SHP, code: "SHP", label: "Libra de Santa Helena", deprecated: false},
    %{value: :SLL, code: "SLL", label: "Leona", deprecated: false},
    %{value: :SOS, code: "SOS", label: "Chelín somalí", deprecated: false},
    %{value: :SRD, code: "SRD", label: "Dólar de Suriname", deprecated: false},
    %{value: :SSP, code: "SSP", label: "Libra sudanesa Sur", deprecated: false},
    %{value: :STD, code: "STD", label: "Dobra", deprecated: false},
    %{value: :SVC, code: "SVC", label: "Colon El Salvador", deprecated: false},
    %{value: :SYP, code: "SYP", label: "Libra Siria", deprecated: false},
    %{value: :SZL, code: "SZL", label: "Lilangeni", deprecated: false},
    %{value: :THB, code: "THB", label: "Baht", deprecated: false},
    %{value: :TJS, code: "TJS", label: "Somoni", deprecated: false},
    %{value: :TMT, code: "TMT", label: "Turkmenistán nuevo manat", deprecated: false},
    %{value: :TND, code: "TND", label: "Dinar tunecino", deprecated: false},
    %{value: :TOP, code: "TOP", label: "Pa'anga", deprecated: false},
    %{value: :TRY, code: "TRY", label: "Lira turca", deprecated: false},
    %{value: :TTD, code: "TTD", label: "Dólar de Trinidad y Tobago", deprecated: false},
    %{value: :TWD, code: "TWD", label: "Nuevo dólar de Taiwán", deprecated: false},
    %{value: :TZS, code: "TZS", label: "Shilling tanzano", deprecated: false},
    %{value: :UAH, code: "UAH", label: "Hryvnia", deprecated: false},
    %{value: :UGX, code: "UGX", label: "Shilling de Uganda", deprecated: false},
    %{value: :USD, code: "USD", label: "Dólar americano", deprecated: false},
    %{value: :USN, code: "USN", label: "Dólar estadounidense (día siguiente)", deprecated: false},
    %{
      value: :UYI,
      code: "UYI",
      label: "Peso Uruguay en Unidades Indexadas (URUIURUI)",
      deprecated: false
    },
    %{value: :UYP, code: "UYP", label: "Uruguay (Peso)", deprecated: false},
    %{value: :UYU, code: "UYU", label: "Peso Uruguayo", deprecated: false},
    %{value: :UZS, code: "UZS", label: "Uzbekistán Sum", deprecated: false},
    %{value: :VEF, code: "VEF", label: "Bolívar", deprecated: false},
    %{value: :VES, code: "VES", label: "Bolívar digital  (Venezuela)", deprecated: false},
    %{value: :VND, code: "VND", label: "Dong", deprecated: false},
    %{value: :VUV, code: "VUV", label: "Vatu", deprecated: false},
    %{value: :WST, code: "WST", label: "Tala", deprecated: false},
    %{value: :XAF, code: "XAF", label: "Franco CFA BEAC", deprecated: false},
    %{value: :XAG, code: "XAG", label: "Plata", deprecated: false},
    %{value: :XAU, code: "XAU", label: "Oro", deprecated: false},
    %{
      value: :XBA,
      code: "XBA",
      label: "Unidad de Mercados de Bonos Unidad Europea Composite (EURCO)",
      deprecated: false
    },
    %{
      value: :XBB,
      code: "XBB",
      label: "Unidad Monetaria de Bonos de Mercados Unidad Europea (UEM-6)",
      deprecated: false
    },
    %{
      value: :XBC,
      code: "XBC",
      label: "Mercados de Bonos Unidad Europea unidad de cuenta a 9 (UCE-9)",
      deprecated: false
    },
    %{
      value: :XBD,
      code: "XBD",
      label: "Mercados de Bonos Unidad Europea unidad de cuenta a 17 (UCE-17)",
      deprecated: false
    },
    %{value: :XCD, code: "XCD", label: "Dólar del Caribe Oriental", deprecated: false},
    %{value: :XDR, code: "XDR", label: "DEG (Derechos Especiales de Giro)", deprecated: false},
    %{value: :XOF, code: "XOF", label: "Franco CFA BCEAO", deprecated: false},
    %{value: :XPD, code: "XPD", label: "Paladio", deprecated: false},
    %{value: :XPF, code: "XPF", label: "Franco CFP", deprecated: false},
    %{value: :XPT, code: "XPT", label: "Platino", deprecated: false},
    %{value: :XSU, code: "XSU", label: "Sucre", deprecated: false},
    %{
      value: :XTS,
      code: "XTS",
      label: "Códigos reservados específicamente para propósitos de prueba",
      deprecated: false
    },
    %{value: :XUA, code: "XUA", label: "Unidad ADB de Cuenta", deprecated: false},
    %{
      value: :XXX,
      code: "XXX",
      label: "Los códigos asignados para las transacciones en que intervenga ninguna moneda",
      deprecated: false
    },
    %{value: :YER, code: "YER", label: "Rial yemení", deprecated: false},
    %{value: :ZAR, code: "ZAR", label: "Rand", deprecated: false},
    %{value: :ZMW, code: "ZMW", label: "Kwacha zambiano", deprecated: false},
    %{value: :ZWL, code: "ZWL", label: "Zimbabwe Dólar", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:AED), do: "AED"
  def value(:AFN), do: "AFN"
  def value(:ALL), do: "ALL"
  def value(:AMD), do: "AMD"
  def value(:ANG), do: "ANG"
  def value(:AOA), do: "AOA"
  def value(:ARS), do: "ARS"
  def value(:AUD), do: "AUD"
  def value(:AWG), do: "AWG"
  def value(:AZN), do: "AZN"
  def value(:BAM), do: "BAM"
  def value(:BBD), do: "BBD"
  def value(:BDT), do: "BDT"
  def value(:BGN), do: "BGN"
  def value(:BHD), do: "BHD"
  def value(:BIF), do: "BIF"
  def value(:BMD), do: "BMD"
  def value(:BND), do: "BND"
  def value(:BOB), do: "BOB"
  def value(:BOV), do: "BOV"
  def value(:BRL), do: "BRL"
  def value(:BSD), do: "BSD"
  def value(:BTN), do: "BTN"
  def value(:BWP), do: "BWP"
  def value(:BYR), do: "BYR"
  def value(:BZD), do: "BZD"
  def value(:CAD), do: "CAD"
  def value(:CDF), do: "CDF"
  def value(:CHE), do: "CHE"
  def value(:CHF), do: "CHF"
  def value(:CHW), do: "CHW"
  def value(:CLF), do: "CLF"
  def value(:CLP), do: "CLP"
  def value(:CNH), do: "CNH"
  def value(:CNY), do: "CNY"
  def value(:COP), do: "COP"
  def value(:COU), do: "COU"
  def value(:CRC), do: "CRC"
  def value(:CUC), do: "CUC"
  def value(:CUP), do: "CUP"
  def value(:CVE), do: "CVE"
  def value(:CZK), do: "CZK"
  def value(:DJF), do: "DJF"
  def value(:DKK), do: "DKK"
  def value(:DOP), do: "DOP"
  def value(:DZD), do: "DZD"
  def value(:EGP), do: "EGP"
  def value(:ERN), do: "ERN"
  def value(:ESD), do: "ESD"
  def value(:ETB), do: "ETB"
  def value(:EUR), do: "EUR"
  def value(:FJD), do: "FJD"
  def value(:FKP), do: "FKP"
  def value(:GBP), do: "GBP"
  def value(:GEL), do: "GEL"
  def value(:GHS), do: "GHS"
  def value(:GIP), do: "GIP"
  def value(:GMD), do: "GMD"
  def value(:GNF), do: "GNF"
  def value(:GTQ), do: "GTQ"
  def value(:GYD), do: "GYD"
  def value(:HKD), do: "HKD"
  def value(:HNL), do: "HNL"
  def value(:HRK), do: "HRK"
  def value(:HTG), do: "HTG"
  def value(:HUF), do: "HUF"
  def value(:IDR), do: "IDR"
  def value(:ILS), do: "ILS"
  def value(:INR), do: "INR"
  def value(:IQD), do: "IQD"
  def value(:IRR), do: "IRR"
  def value(:ISK), do: "ISK"
  def value(:JMD), do: "JMD"
  def value(:JOD), do: "JOD"
  def value(:JPY), do: "JPY"
  def value(:KES), do: "KES"
  def value(:KGS), do: "KGS"
  def value(:KHR), do: "KHR"
  def value(:KMF), do: "KMF"
  def value(:KPW), do: "KPW"
  def value(:KRW), do: "KRW"
  def value(:KWD), do: "KWD"
  def value(:KYD), do: "KYD"
  def value(:KZT), do: "KZT"
  def value(:LAK), do: "LAK"
  def value(:LBP), do: "LBP"
  def value(:LKR), do: "LKR"
  def value(:LRD), do: "LRD"
  def value(:LSL), do: "LSL"
  def value(:LYD), do: "LYD"
  def value(:MAD), do: "MAD"
  def value(:MDL), do: "MDL"
  def value(:MGA), do: "MGA"
  def value(:MKD), do: "MKD"
  def value(:MMK), do: "MMK"
  def value(:MNT), do: "MNT"
  def value(:MOP), do: "MOP"
  def value(:MRO), do: "MRO"
  def value(:MUR), do: "MUR"
  def value(:MVR), do: "MVR"
  def value(:MWK), do: "MWK"
  def value(:MXN), do: "MXN"
  def value(:MXV), do: "MXV"
  def value(:MYR), do: "MYR"
  def value(:MZN), do: "MZN"
  def value(:NAD), do: "NAD"
  def value(:NGN), do: "NGN"
  def value(:NIC), do: "NIC"
  def value(:NIO), do: "NIO"
  def value(:NOK), do: "NOK"
  def value(:NPR), do: "NPR"
  def value(:NZD), do: "NZD"
  def value(:OMR), do: "OMR"
  def value(:PAB), do: "PAB"
  def value(:PEN), do: "PEN"
  def value(:PGK), do: "PGK"
  def value(:PHP), do: "PHP"
  def value(:PKR), do: "PKR"
  def value(:PLN), do: "PLN"
  def value(:PYG), do: "PYG"
  def value(:QAR), do: "QAR"
  def value(:RON), do: "RON"
  def value(:RSD), do: "RSD"
  def value(:RUB), do: "RUB"
  def value(:RWF), do: "RWF"
  def value(:SAR), do: "SAR"
  def value(:SBD), do: "SBD"
  def value(:SCR), do: "SCR"
  def value(:SDG), do: "SDG"
  def value(:SEK), do: "SEK"
  def value(:SGD), do: "SGD"
  def value(:SHP), do: "SHP"
  def value(:SLL), do: "SLL"
  def value(:SOS), do: "SOS"
  def value(:SRD), do: "SRD"
  def value(:SSP), do: "SSP"
  def value(:STD), do: "STD"
  def value(:SVC), do: "SVC"
  def value(:SYP), do: "SYP"
  def value(:SZL), do: "SZL"
  def value(:THB), do: "THB"
  def value(:TJS), do: "TJS"
  def value(:TMT), do: "TMT"
  def value(:TND), do: "TND"
  def value(:TOP), do: "TOP"
  def value(:TRY), do: "TRY"
  def value(:TTD), do: "TTD"
  def value(:TWD), do: "TWD"
  def value(:TZS), do: "TZS"
  def value(:UAH), do: "UAH"
  def value(:UGX), do: "UGX"
  def value(:USD), do: "USD"
  def value(:USN), do: "USN"
  def value(:UYI), do: "UYI"
  def value(:UYP), do: "UYP"
  def value(:UYU), do: "UYU"
  def value(:UZS), do: "UZS"
  def value(:VEF), do: "VEF"
  def value(:VES), do: "VES"
  def value(:VND), do: "VND"
  def value(:VUV), do: "VUV"
  def value(:WST), do: "WST"
  def value(:XAF), do: "XAF"
  def value(:XAG), do: "XAG"
  def value(:XAU), do: "XAU"
  def value(:XBA), do: "XBA"
  def value(:XBB), do: "XBB"
  def value(:XBC), do: "XBC"
  def value(:XBD), do: "XBD"
  def value(:XCD), do: "XCD"
  def value(:XDR), do: "XDR"
  def value(:XOF), do: "XOF"
  def value(:XPD), do: "XPD"
  def value(:XPF), do: "XPF"
  def value(:XPT), do: "XPT"
  def value(:XSU), do: "XSU"
  def value(:XTS), do: "XTS"
  def value(:XUA), do: "XUA"
  def value(:XXX), do: "XXX"
  def value(:YER), do: "YER"
  def value(:ZAR), do: "ZAR"
  def value(:ZMW), do: "ZMW"
  def value(:ZWL), do: "ZWL"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("AED"),
    do: {:ok, %{value: :AED, code: "AED", label: "Dirham de EAU", deprecated: false}}

  def from_code("AFN"),
    do: {:ok, %{value: :AFN, code: "AFN", label: "Afghani", deprecated: false}}

  def from_code("ALL"), do: {:ok, %{value: :ALL, code: "ALL", label: "Lek", deprecated: false}}

  def from_code("AMD"),
    do: {:ok, %{value: :AMD, code: "AMD", label: "Dram armenio", deprecated: false}}

  def from_code("ANG"),
    do:
      {:ok, %{value: :ANG, code: "ANG", label: "Florín antillano neerlandés", deprecated: false}}

  def from_code("AOA"), do: {:ok, %{value: :AOA, code: "AOA", label: "Kwanza", deprecated: false}}

  def from_code("ARS"),
    do: {:ok, %{value: :ARS, code: "ARS", label: "Peso Argentino", deprecated: false}}

  def from_code("AUD"),
    do: {:ok, %{value: :AUD, code: "AUD", label: "Dólar Australiano", deprecated: false}}

  def from_code("AWG"),
    do: {:ok, %{value: :AWG, code: "AWG", label: "Aruba Florin", deprecated: false}}

  def from_code("AZN"),
    do: {:ok, %{value: :AZN, code: "AZN", label: "Azerbaijanian Manat", deprecated: false}}

  def from_code("BAM"),
    do: {:ok, %{value: :BAM, code: "BAM", label: "Convertibles marca", deprecated: false}}

  def from_code("BBD"),
    do: {:ok, %{value: :BBD, code: "BBD", label: "Dólar de Barbados", deprecated: false}}

  def from_code("BDT"), do: {:ok, %{value: :BDT, code: "BDT", label: "Taka", deprecated: false}}

  def from_code("BGN"),
    do: {:ok, %{value: :BGN, code: "BGN", label: "Lev búlgaro", deprecated: false}}

  def from_code("BHD"),
    do: {:ok, %{value: :BHD, code: "BHD", label: "Dinar de Bahrein", deprecated: false}}

  def from_code("BIF"),
    do: {:ok, %{value: :BIF, code: "BIF", label: "Burundi Franc", deprecated: false}}

  def from_code("BMD"),
    do: {:ok, %{value: :BMD, code: "BMD", label: "Dólar de Bermudas", deprecated: false}}

  def from_code("BND"),
    do: {:ok, %{value: :BND, code: "BND", label: "Dólar de Brunei", deprecated: false}}

  def from_code("BOB"),
    do: {:ok, %{value: :BOB, code: "BOB", label: "Boliviano", deprecated: false}}

  def from_code("BOV"), do: {:ok, %{value: :BOV, code: "BOV", label: "Mvdol", deprecated: false}}

  def from_code("BRL"),
    do: {:ok, %{value: :BRL, code: "BRL", label: "Real brasileño", deprecated: false}}

  def from_code("BSD"),
    do: {:ok, %{value: :BSD, code: "BSD", label: "Dólar de las Bahamas", deprecated: false}}

  def from_code("BTN"),
    do: {:ok, %{value: :BTN, code: "BTN", label: "Ngultrum", deprecated: false}}

  def from_code("BWP"), do: {:ok, %{value: :BWP, code: "BWP", label: "Pula", deprecated: false}}

  def from_code("BYR"),
    do: {:ok, %{value: :BYR, code: "BYR", label: "Rublo bielorruso", deprecated: false}}

  def from_code("BZD"),
    do: {:ok, %{value: :BZD, code: "BZD", label: "Dólar de Belice", deprecated: false}}

  def from_code("CAD"),
    do: {:ok, %{value: :CAD, code: "CAD", label: "Dólar Canadiense", deprecated: false}}

  def from_code("CDF"),
    do: {:ok, %{value: :CDF, code: "CDF", label: "Franco congoleño", deprecated: false}}

  def from_code("CHE"),
    do: {:ok, %{value: :CHE, code: "CHE", label: "WIR Euro", deprecated: false}}

  def from_code("CHF"),
    do: {:ok, %{value: :CHF, code: "CHF", label: "Franco Suizo", deprecated: false}}

  def from_code("CHW"),
    do: {:ok, %{value: :CHW, code: "CHW", label: "Franc WIR", deprecated: false}}

  def from_code("CLF"),
    do: {:ok, %{value: :CLF, code: "CLF", label: "Unidad de Fomento", deprecated: false}}

  def from_code("CLP"),
    do: {:ok, %{value: :CLP, code: "CLP", label: "Peso chileno", deprecated: false}}

  def from_code("CNH"),
    do:
      {:ok,
       %{value: :CNH, code: "CNH", label: "Yuan extracontinental (China )", deprecated: false}}

  def from_code("CNY"),
    do: {:ok, %{value: :CNY, code: "CNY", label: "Yuan Renminbi", deprecated: false}}

  def from_code("COP"),
    do: {:ok, %{value: :COP, code: "COP", label: "Peso Colombiano", deprecated: false}}

  def from_code("COU"),
    do: {:ok, %{value: :COU, code: "COU", label: "Unidad de Valor real", deprecated: false}}

  def from_code("CRC"),
    do: {:ok, %{value: :CRC, code: "CRC", label: "Colón costarricense", deprecated: false}}

  def from_code("CUC"),
    do: {:ok, %{value: :CUC, code: "CUC", label: "Peso Convertible", deprecated: false}}

  def from_code("CUP"),
    do: {:ok, %{value: :CUP, code: "CUP", label: "Peso Cubano", deprecated: false}}

  def from_code("CVE"),
    do: {:ok, %{value: :CVE, code: "CVE", label: "Cabo Verde Escudo", deprecated: false}}

  def from_code("CZK"),
    do: {:ok, %{value: :CZK, code: "CZK", label: "Corona checa", deprecated: false}}

  def from_code("DJF"),
    do: {:ok, %{value: :DJF, code: "DJF", label: "Franco de Djibouti", deprecated: false}}

  def from_code("DKK"),
    do: {:ok, %{value: :DKK, code: "DKK", label: "Corona danesa", deprecated: false}}

  def from_code("DOP"),
    do: {:ok, %{value: :DOP, code: "DOP", label: "Peso Dominicano", deprecated: false}}

  def from_code("DZD"),
    do: {:ok, %{value: :DZD, code: "DZD", label: "Dinar argelino", deprecated: false}}

  def from_code("EGP"),
    do: {:ok, %{value: :EGP, code: "EGP", label: "Libra egipcia", deprecated: false}}

  def from_code("ERN"), do: {:ok, %{value: :ERN, code: "ERN", label: "Nakfa", deprecated: false}}

  def from_code("ESD"),
    do: {:ok, %{value: :ESD, code: "ESD", label: "Dólar de Ecuador", deprecated: false}}

  def from_code("ETB"),
    do: {:ok, %{value: :ETB, code: "ETB", label: "Birr etíope", deprecated: false}}

  def from_code("EUR"), do: {:ok, %{value: :EUR, code: "EUR", label: "Euro", deprecated: false}}

  def from_code("FJD"),
    do: {:ok, %{value: :FJD, code: "FJD", label: "Dólar de Fiji", deprecated: false}}

  def from_code("FKP"),
    do: {:ok, %{value: :FKP, code: "FKP", label: "Libra malvinense", deprecated: false}}

  def from_code("GBP"),
    do: {:ok, %{value: :GBP, code: "GBP", label: "Libra Esterlina", deprecated: false}}

  def from_code("GEL"), do: {:ok, %{value: :GEL, code: "GEL", label: "Lari", deprecated: false}}

  def from_code("GHS"),
    do: {:ok, %{value: :GHS, code: "GHS", label: "Cedi de Ghana", deprecated: false}}

  def from_code("GIP"),
    do: {:ok, %{value: :GIP, code: "GIP", label: "Libra de Gibraltar", deprecated: false}}

  def from_code("GMD"), do: {:ok, %{value: :GMD, code: "GMD", label: "Dalasi", deprecated: false}}

  def from_code("GNF"),
    do: {:ok, %{value: :GNF, code: "GNF", label: "Franco guineano", deprecated: false}}

  def from_code("GTQ"),
    do: {:ok, %{value: :GTQ, code: "GTQ", label: "Quetzal", deprecated: false}}

  def from_code("GYD"),
    do: {:ok, %{value: :GYD, code: "GYD", label: "Dólar guyanés", deprecated: false}}

  def from_code("HKD"),
    do: {:ok, %{value: :HKD, code: "HKD", label: "Dólar De Hong Kong", deprecated: false}}

  def from_code("HNL"),
    do: {:ok, %{value: :HNL, code: "HNL", label: "Lempira", deprecated: false}}

  def from_code("HRK"), do: {:ok, %{value: :HRK, code: "HRK", label: "Kuna", deprecated: false}}
  def from_code("HTG"), do: {:ok, %{value: :HTG, code: "HTG", label: "Gourde", deprecated: false}}
  def from_code("HUF"), do: {:ok, %{value: :HUF, code: "HUF", label: "Florín", deprecated: false}}
  def from_code("IDR"), do: {:ok, %{value: :IDR, code: "IDR", label: "Rupia", deprecated: false}}

  def from_code("ILS"),
    do: {:ok, %{value: :ILS, code: "ILS", label: "Nuevo Shekel Israelí", deprecated: false}}

  def from_code("INR"),
    do: {:ok, %{value: :INR, code: "INR", label: "Rupia india", deprecated: false}}

  def from_code("IQD"),
    do: {:ok, %{value: :IQD, code: "IQD", label: "Dinar iraquí", deprecated: false}}

  def from_code("IRR"),
    do: {:ok, %{value: :IRR, code: "IRR", label: "Rial iraní", deprecated: false}}

  def from_code("ISK"),
    do: {:ok, %{value: :ISK, code: "ISK", label: "Corona islandesa", deprecated: false}}

  def from_code("JMD"),
    do: {:ok, %{value: :JMD, code: "JMD", label: "Dólar Jamaiquino", deprecated: false}}

  def from_code("JOD"),
    do: {:ok, %{value: :JOD, code: "JOD", label: "Dinar jordano", deprecated: false}}

  def from_code("JPY"), do: {:ok, %{value: :JPY, code: "JPY", label: "Yen", deprecated: false}}

  def from_code("KES"),
    do: {:ok, %{value: :KES, code: "KES", label: "Chelín keniano", deprecated: false}}

  def from_code("KGS"), do: {:ok, %{value: :KGS, code: "KGS", label: "Som", deprecated: false}}
  def from_code("KHR"), do: {:ok, %{value: :KHR, code: "KHR", label: "Riel", deprecated: false}}

  def from_code("KMF"),
    do: {:ok, %{value: :KMF, code: "KMF", label: "Franco Comoro", deprecated: false}}

  def from_code("KPW"),
    do: {:ok, %{value: :KPW, code: "KPW", label: "Corea del Norte ganó", deprecated: false}}

  def from_code("KRW"), do: {:ok, %{value: :KRW, code: "KRW", label: "Won", deprecated: false}}

  def from_code("KWD"),
    do: {:ok, %{value: :KWD, code: "KWD", label: "Dinar kuwaití", deprecated: false}}

  def from_code("KYD"),
    do: {:ok, %{value: :KYD, code: "KYD", label: "Dólar de las Islas Caimán", deprecated: false}}

  def from_code("KZT"), do: {:ok, %{value: :KZT, code: "KZT", label: "Tenge", deprecated: false}}
  def from_code("LAK"), do: {:ok, %{value: :LAK, code: "LAK", label: "Kip", deprecated: false}}

  def from_code("LBP"),
    do: {:ok, %{value: :LBP, code: "LBP", label: "Libra libanesa", deprecated: false}}

  def from_code("LKR"),
    do: {:ok, %{value: :LKR, code: "LKR", label: "Rupia de Sri Lanka", deprecated: false}}

  def from_code("LRD"),
    do: {:ok, %{value: :LRD, code: "LRD", label: "Dólar liberiano", deprecated: false}}

  def from_code("LSL"), do: {:ok, %{value: :LSL, code: "LSL", label: "Loti", deprecated: false}}

  def from_code("LYD"),
    do: {:ok, %{value: :LYD, code: "LYD", label: "Dinar libio", deprecated: false}}

  def from_code("MAD"),
    do: {:ok, %{value: :MAD, code: "MAD", label: "Dirham marroquí", deprecated: false}}

  def from_code("MDL"),
    do: {:ok, %{value: :MDL, code: "MDL", label: "Leu moldavo", deprecated: false}}

  def from_code("MGA"),
    do: {:ok, %{value: :MGA, code: "MGA", label: "Ariary malgache", deprecated: false}}

  def from_code("MKD"), do: {:ok, %{value: :MKD, code: "MKD", label: "Denar", deprecated: false}}
  def from_code("MMK"), do: {:ok, %{value: :MMK, code: "MMK", label: "Kyat", deprecated: false}}
  def from_code("MNT"), do: {:ok, %{value: :MNT, code: "MNT", label: "Tugrik", deprecated: false}}
  def from_code("MOP"), do: {:ok, %{value: :MOP, code: "MOP", label: "Pataca", deprecated: false}}

  def from_code("MRO"),
    do: {:ok, %{value: :MRO, code: "MRO", label: "Ouguiya", deprecated: false}}

  def from_code("MUR"),
    do: {:ok, %{value: :MUR, code: "MUR", label: "Rupia de Mauricio", deprecated: false}}

  def from_code("MVR"), do: {:ok, %{value: :MVR, code: "MVR", label: "Rupia", deprecated: false}}
  def from_code("MWK"), do: {:ok, %{value: :MWK, code: "MWK", label: "Kwacha", deprecated: false}}

  def from_code("MXN"),
    do: {:ok, %{value: :MXN, code: "MXN", label: "Peso Mexicano", deprecated: false}}

  def from_code("MXV"),
    do:
      {:ok,
       %{value: :MXV, code: "MXV", label: "México Unidad de Inversión (UDI)", deprecated: false}}

  def from_code("MYR"),
    do: {:ok, %{value: :MYR, code: "MYR", label: "Ringgit malayo", deprecated: false}}

  def from_code("MZN"),
    do: {:ok, %{value: :MZN, code: "MZN", label: "Mozambique Metical", deprecated: false}}

  def from_code("NAD"),
    do: {:ok, %{value: :NAD, code: "NAD", label: "Dólar de Namibia", deprecated: false}}

  def from_code("NGN"), do: {:ok, %{value: :NGN, code: "NGN", label: "Naira", deprecated: false}}

  def from_code("NIC"),
    do: {:ok, %{value: :NIC, code: "NIC", label: "Córdoba (Nicaragua)", deprecated: false}}

  def from_code("NIO"),
    do: {:ok, %{value: :NIO, code: "NIO", label: "Córdoba Oro", deprecated: false}}

  def from_code("NOK"),
    do: {:ok, %{value: :NOK, code: "NOK", label: "Corona noruega", deprecated: false}}

  def from_code("NPR"),
    do: {:ok, %{value: :NPR, code: "NPR", label: "Rupia nepalí", deprecated: false}}

  def from_code("NZD"),
    do: {:ok, %{value: :NZD, code: "NZD", label: "Dólar de Nueva Zelanda", deprecated: false}}

  def from_code("OMR"),
    do: {:ok, %{value: :OMR, code: "OMR", label: "Rial omaní", deprecated: false}}

  def from_code("PAB"), do: {:ok, %{value: :PAB, code: "PAB", label: "Balboa", deprecated: false}}

  def from_code("PEN"),
    do: {:ok, %{value: :PEN, code: "PEN", label: "Nuevo Sol", deprecated: false}}

  def from_code("PGK"), do: {:ok, %{value: :PGK, code: "PGK", label: "Kina", deprecated: false}}

  def from_code("PHP"),
    do: {:ok, %{value: :PHP, code: "PHP", label: "Peso filipino", deprecated: false}}

  def from_code("PKR"),
    do: {:ok, %{value: :PKR, code: "PKR", label: "Rupia de Pakistán", deprecated: false}}

  def from_code("PLN"), do: {:ok, %{value: :PLN, code: "PLN", label: "Zloty", deprecated: false}}

  def from_code("PYG"),
    do: {:ok, %{value: :PYG, code: "PYG", label: "Guaraní", deprecated: false}}

  def from_code("QAR"),
    do: {:ok, %{value: :QAR, code: "QAR", label: "Qatar Rial", deprecated: false}}

  def from_code("RON"),
    do: {:ok, %{value: :RON, code: "RON", label: "Leu rumano", deprecated: false}}

  def from_code("RSD"),
    do: {:ok, %{value: :RSD, code: "RSD", label: "Dinar serbio", deprecated: false}}

  def from_code("RUB"),
    do: {:ok, %{value: :RUB, code: "RUB", label: "Rublo ruso", deprecated: false}}

  def from_code("RWF"),
    do: {:ok, %{value: :RWF, code: "RWF", label: "Franco ruandés", deprecated: false}}

  def from_code("SAR"),
    do: {:ok, %{value: :SAR, code: "SAR", label: "Riyal saudí", deprecated: false}}

  def from_code("SBD"),
    do: {:ok, %{value: :SBD, code: "SBD", label: "Dólar de las Islas Salomón", deprecated: false}}

  def from_code("SCR"),
    do: {:ok, %{value: :SCR, code: "SCR", label: "Rupia de Seychelles", deprecated: false}}

  def from_code("SDG"),
    do: {:ok, %{value: :SDG, code: "SDG", label: "Libra sudanesa", deprecated: false}}

  def from_code("SEK"),
    do: {:ok, %{value: :SEK, code: "SEK", label: "Corona sueca", deprecated: false}}

  def from_code("SGD"),
    do: {:ok, %{value: :SGD, code: "SGD", label: "Dólar De Singapur", deprecated: false}}

  def from_code("SHP"),
    do: {:ok, %{value: :SHP, code: "SHP", label: "Libra de Santa Helena", deprecated: false}}

  def from_code("SLL"), do: {:ok, %{value: :SLL, code: "SLL", label: "Leona", deprecated: false}}

  def from_code("SOS"),
    do: {:ok, %{value: :SOS, code: "SOS", label: "Chelín somalí", deprecated: false}}

  def from_code("SRD"),
    do: {:ok, %{value: :SRD, code: "SRD", label: "Dólar de Suriname", deprecated: false}}

  def from_code("SSP"),
    do: {:ok, %{value: :SSP, code: "SSP", label: "Libra sudanesa Sur", deprecated: false}}

  def from_code("STD"), do: {:ok, %{value: :STD, code: "STD", label: "Dobra", deprecated: false}}

  def from_code("SVC"),
    do: {:ok, %{value: :SVC, code: "SVC", label: "Colon El Salvador", deprecated: false}}

  def from_code("SYP"),
    do: {:ok, %{value: :SYP, code: "SYP", label: "Libra Siria", deprecated: false}}

  def from_code("SZL"),
    do: {:ok, %{value: :SZL, code: "SZL", label: "Lilangeni", deprecated: false}}

  def from_code("THB"), do: {:ok, %{value: :THB, code: "THB", label: "Baht", deprecated: false}}
  def from_code("TJS"), do: {:ok, %{value: :TJS, code: "TJS", label: "Somoni", deprecated: false}}

  def from_code("TMT"),
    do: {:ok, %{value: :TMT, code: "TMT", label: "Turkmenistán nuevo manat", deprecated: false}}

  def from_code("TND"),
    do: {:ok, %{value: :TND, code: "TND", label: "Dinar tunecino", deprecated: false}}

  def from_code("TOP"),
    do: {:ok, %{value: :TOP, code: "TOP", label: "Pa'anga", deprecated: false}}

  def from_code("TRY"),
    do: {:ok, %{value: :TRY, code: "TRY", label: "Lira turca", deprecated: false}}

  def from_code("TTD"),
    do: {:ok, %{value: :TTD, code: "TTD", label: "Dólar de Trinidad y Tobago", deprecated: false}}

  def from_code("TWD"),
    do: {:ok, %{value: :TWD, code: "TWD", label: "Nuevo dólar de Taiwán", deprecated: false}}

  def from_code("TZS"),
    do: {:ok, %{value: :TZS, code: "TZS", label: "Shilling tanzano", deprecated: false}}

  def from_code("UAH"),
    do: {:ok, %{value: :UAH, code: "UAH", label: "Hryvnia", deprecated: false}}

  def from_code("UGX"),
    do: {:ok, %{value: :UGX, code: "UGX", label: "Shilling de Uganda", deprecated: false}}

  def from_code("USD"),
    do: {:ok, %{value: :USD, code: "USD", label: "Dólar americano", deprecated: false}}

  def from_code("USN"),
    do:
      {:ok,
       %{
         value: :USN,
         code: "USN",
         label: "Dólar estadounidense (día siguiente)",
         deprecated: false
       }}

  def from_code("UYI"),
    do:
      {:ok,
       %{
         value: :UYI,
         code: "UYI",
         label: "Peso Uruguay en Unidades Indexadas (URUIURUI)",
         deprecated: false
       }}

  def from_code("UYP"),
    do: {:ok, %{value: :UYP, code: "UYP", label: "Uruguay (Peso)", deprecated: false}}

  def from_code("UYU"),
    do: {:ok, %{value: :UYU, code: "UYU", label: "Peso Uruguayo", deprecated: false}}

  def from_code("UZS"),
    do: {:ok, %{value: :UZS, code: "UZS", label: "Uzbekistán Sum", deprecated: false}}

  def from_code("VEF"),
    do: {:ok, %{value: :VEF, code: "VEF", label: "Bolívar", deprecated: false}}

  def from_code("VES"),
    do:
      {:ok, %{value: :VES, code: "VES", label: "Bolívar digital  (Venezuela)", deprecated: false}}

  def from_code("VND"), do: {:ok, %{value: :VND, code: "VND", label: "Dong", deprecated: false}}
  def from_code("VUV"), do: {:ok, %{value: :VUV, code: "VUV", label: "Vatu", deprecated: false}}
  def from_code("WST"), do: {:ok, %{value: :WST, code: "WST", label: "Tala", deprecated: false}}

  def from_code("XAF"),
    do: {:ok, %{value: :XAF, code: "XAF", label: "Franco CFA BEAC", deprecated: false}}

  def from_code("XAG"), do: {:ok, %{value: :XAG, code: "XAG", label: "Plata", deprecated: false}}
  def from_code("XAU"), do: {:ok, %{value: :XAU, code: "XAU", label: "Oro", deprecated: false}}

  def from_code("XBA"),
    do:
      {:ok,
       %{
         value: :XBA,
         code: "XBA",
         label: "Unidad de Mercados de Bonos Unidad Europea Composite (EURCO)",
         deprecated: false
       }}

  def from_code("XBB"),
    do:
      {:ok,
       %{
         value: :XBB,
         code: "XBB",
         label: "Unidad Monetaria de Bonos de Mercados Unidad Europea (UEM-6)",
         deprecated: false
       }}

  def from_code("XBC"),
    do:
      {:ok,
       %{
         value: :XBC,
         code: "XBC",
         label: "Mercados de Bonos Unidad Europea unidad de cuenta a 9 (UCE-9)",
         deprecated: false
       }}

  def from_code("XBD"),
    do:
      {:ok,
       %{
         value: :XBD,
         code: "XBD",
         label: "Mercados de Bonos Unidad Europea unidad de cuenta a 17 (UCE-17)",
         deprecated: false
       }}

  def from_code("XCD"),
    do: {:ok, %{value: :XCD, code: "XCD", label: "Dólar del Caribe Oriental", deprecated: false}}

  def from_code("XDR"),
    do:
      {:ok,
       %{value: :XDR, code: "XDR", label: "DEG (Derechos Especiales de Giro)", deprecated: false}}

  def from_code("XOF"),
    do: {:ok, %{value: :XOF, code: "XOF", label: "Franco CFA BCEAO", deprecated: false}}

  def from_code("XPD"),
    do: {:ok, %{value: :XPD, code: "XPD", label: "Paladio", deprecated: false}}

  def from_code("XPF"),
    do: {:ok, %{value: :XPF, code: "XPF", label: "Franco CFP", deprecated: false}}

  def from_code("XPT"),
    do: {:ok, %{value: :XPT, code: "XPT", label: "Platino", deprecated: false}}

  def from_code("XSU"), do: {:ok, %{value: :XSU, code: "XSU", label: "Sucre", deprecated: false}}

  def from_code("XTS"),
    do:
      {:ok,
       %{
         value: :XTS,
         code: "XTS",
         label: "Códigos reservados específicamente para propósitos de prueba",
         deprecated: false
       }}

  def from_code("XUA"),
    do: {:ok, %{value: :XUA, code: "XUA", label: "Unidad ADB de Cuenta", deprecated: false}}

  def from_code("XXX"),
    do:
      {:ok,
       %{
         value: :XXX,
         code: "XXX",
         label: "Los códigos asignados para las transacciones en que intervenga ninguna moneda",
         deprecated: false
       }}

  def from_code("YER"),
    do: {:ok, %{value: :YER, code: "YER", label: "Rial yemení", deprecated: false}}

  def from_code("ZAR"), do: {:ok, %{value: :ZAR, code: "ZAR", label: "Rand", deprecated: false}}

  def from_code("ZMW"),
    do: {:ok, %{value: :ZMW, code: "ZMW", label: "Kwacha zambiano", deprecated: false}}

  def from_code("ZWL"),
    do: {:ok, %{value: :ZWL, code: "ZWL", label: "Zimbabwe Dólar", deprecated: false}}

  def from_code(_), do: :error
end
