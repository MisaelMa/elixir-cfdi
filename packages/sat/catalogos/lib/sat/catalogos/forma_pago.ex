# ─────────────────────────────────────────────────────────────
#  Generado por Sat.Catalogos.Codegen — NO EDITAR.
#  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
# ─────────────────────────────────────────────────────────────
defmodule Sat.Catalogos.FormaPago do
  @moduledoc "Catálogo c_FormaPago del SAT (CFDI 4.0)."

  @type t ::
          :efectivo
          | :cheque_nominativo
          | :transferencia_electronica
          | :tarjeta_de_credito
          | :monedero_electronico
          | :dinero_electronico
          | :vales_de_despensa
          | :dacion_en_pago
          | :subrogacion
          | :consignacion
          | :condonacion
          | :compensacion
          | :novacion
          | :confusion
          | :remision_de_deuda
          | :prescripcion_o_caducidad
          | :a_satisfaccion_del_acreedor
          | :tarjeta_de_debito
          | :tarjeta_de_servicios
          | :aplicacion_de_anticipos
          | :intermediario_pagos
          | :por_definir

  @entries [
    %{value: :efectivo, code: "01", label: "Efectivo", deprecated: false},
    %{value: :cheque_nominativo, code: "02", label: "Cheque nominativo", deprecated: false},
    %{
      value: :transferencia_electronica,
      code: "03",
      label: "Transferencia electrónica de fondos",
      deprecated: false
    },
    %{value: :tarjeta_de_credito, code: "04", label: "Tarjeta de crédito", deprecated: false},
    %{value: :monedero_electronico, code: "05", label: "Monedero electrónico", deprecated: false},
    %{value: :dinero_electronico, code: "06", label: "Dinero electrónico", deprecated: false},
    %{value: :vales_de_despensa, code: "08", label: "Vales de despensa", deprecated: false},
    %{value: :dacion_en_pago, code: "12", label: "Dación en pago", deprecated: false},
    %{value: :subrogacion, code: "13", label: "Pago por subrogación", deprecated: false},
    %{value: :consignacion, code: "14", label: "Pago por consignación", deprecated: false},
    %{value: :condonacion, code: "15", label: "Condonación", deprecated: false},
    %{value: :compensacion, code: "17", label: "Compensación", deprecated: false},
    %{value: :novacion, code: "23", label: "Novación", deprecated: false},
    %{value: :confusion, code: "24", label: "Confusión", deprecated: false},
    %{value: :remision_de_deuda, code: "25", label: "Remisión de deuda", deprecated: false},
    %{
      value: :prescripcion_o_caducidad,
      code: "26",
      label: "Prescripción o caducidad",
      deprecated: false
    },
    %{
      value: :a_satisfaccion_del_acreedor,
      code: "27",
      label: "A satisfacción del acreedor",
      deprecated: false
    },
    %{value: :tarjeta_de_debito, code: "28", label: "Tarjeta de débito", deprecated: false},
    %{value: :tarjeta_de_servicios, code: "29", label: "Tarjeta de servicios", deprecated: false},
    %{
      value: :aplicacion_de_anticipos,
      code: "30",
      label: "Aplicación de anticipos",
      deprecated: false
    },
    %{value: :intermediario_pagos, code: "31", label: "Intermediario pagos", deprecated: false},
    %{value: :por_definir, code: "99", label: "Por definir", deprecated: false}
  ]

  @doc "Lista completa del catálogo."
  def list, do: @entries

  @doc "Devuelve true si el código existe en el catálogo."
  def valid?(code) when is_binary(code), do: Enum.any?(@entries, &(&1.code == code))
  def valid?(_), do: false

  @doc "Convierte un átomo del enum al código string del SAT."
  def value(:efectivo), do: "01"
  def value(:cheque_nominativo), do: "02"
  def value(:transferencia_electronica), do: "03"
  def value(:tarjeta_de_credito), do: "04"
  def value(:monedero_electronico), do: "05"
  def value(:dinero_electronico), do: "06"
  def value(:vales_de_despensa), do: "08"
  def value(:dacion_en_pago), do: "12"
  def value(:subrogacion), do: "13"
  def value(:consignacion), do: "14"
  def value(:condonacion), do: "15"
  def value(:compensacion), do: "17"
  def value(:novacion), do: "23"
  def value(:confusion), do: "24"
  def value(:remision_de_deuda), do: "25"
  def value(:prescripcion_o_caducidad), do: "26"
  def value(:a_satisfaccion_del_acreedor), do: "27"
  def value(:tarjeta_de_debito), do: "28"
  def value(:tarjeta_de_servicios), do: "29"
  def value(:aplicacion_de_anticipos), do: "30"
  def value(:intermediario_pagos), do: "31"
  def value(:por_definir), do: "99"
  def value(_), do: nil

  @doc "Busca una entrada por su código."
  def from_code("01"),
    do: {:ok, %{value: :efectivo, code: "01", label: "Efectivo", deprecated: false}}

  def from_code("02"),
    do:
      {:ok,
       %{value: :cheque_nominativo, code: "02", label: "Cheque nominativo", deprecated: false}}

  def from_code("03"),
    do:
      {:ok,
       %{
         value: :transferencia_electronica,
         code: "03",
         label: "Transferencia electrónica de fondos",
         deprecated: false
       }}

  def from_code("04"),
    do:
      {:ok,
       %{value: :tarjeta_de_credito, code: "04", label: "Tarjeta de crédito", deprecated: false}}

  def from_code("05"),
    do:
      {:ok,
       %{
         value: :monedero_electronico,
         code: "05",
         label: "Monedero electrónico",
         deprecated: false
       }}

  def from_code("06"),
    do:
      {:ok,
       %{value: :dinero_electronico, code: "06", label: "Dinero electrónico", deprecated: false}}

  def from_code("08"),
    do:
      {:ok,
       %{value: :vales_de_despensa, code: "08", label: "Vales de despensa", deprecated: false}}

  def from_code("12"),
    do: {:ok, %{value: :dacion_en_pago, code: "12", label: "Dación en pago", deprecated: false}}

  def from_code("13"),
    do:
      {:ok, %{value: :subrogacion, code: "13", label: "Pago por subrogación", deprecated: false}}

  def from_code("14"),
    do:
      {:ok,
       %{value: :consignacion, code: "14", label: "Pago por consignación", deprecated: false}}

  def from_code("15"),
    do: {:ok, %{value: :condonacion, code: "15", label: "Condonación", deprecated: false}}

  def from_code("17"),
    do: {:ok, %{value: :compensacion, code: "17", label: "Compensación", deprecated: false}}

  def from_code("23"),
    do: {:ok, %{value: :novacion, code: "23", label: "Novación", deprecated: false}}

  def from_code("24"),
    do: {:ok, %{value: :confusion, code: "24", label: "Confusión", deprecated: false}}

  def from_code("25"),
    do:
      {:ok,
       %{value: :remision_de_deuda, code: "25", label: "Remisión de deuda", deprecated: false}}

  def from_code("26"),
    do:
      {:ok,
       %{
         value: :prescripcion_o_caducidad,
         code: "26",
         label: "Prescripción o caducidad",
         deprecated: false
       }}

  def from_code("27"),
    do:
      {:ok,
       %{
         value: :a_satisfaccion_del_acreedor,
         code: "27",
         label: "A satisfacción del acreedor",
         deprecated: false
       }}

  def from_code("28"),
    do:
      {:ok,
       %{value: :tarjeta_de_debito, code: "28", label: "Tarjeta de débito", deprecated: false}}

  def from_code("29"),
    do:
      {:ok,
       %{
         value: :tarjeta_de_servicios,
         code: "29",
         label: "Tarjeta de servicios",
         deprecated: false
       }}

  def from_code("30"),
    do:
      {:ok,
       %{
         value: :aplicacion_de_anticipos,
         code: "30",
         label: "Aplicación de anticipos",
         deprecated: false
       }}

  def from_code("31"),
    do:
      {:ok,
       %{value: :intermediario_pagos, code: "31", label: "Intermediario pagos", deprecated: false}}

  def from_code("99"),
    do: {:ok, %{value: :por_definir, code: "99", label: "Por definir", deprecated: false}}

  def from_code(_), do: :error
end
