defmodule Cfdi.Catalogos.FormaPago do
  @moduledoc """
  Catálogo de formas de pago del SAT (c_FormaPago).
  """

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
          | :por_definir

  @values %{
    efectivo: "01",
    cheque_nominativo: "02",
    transferencia_electronica: "03",
    tarjeta_de_credito: "04",
    monedero_electronico: "05",
    dinero_electronico: "06",
    vales_de_despensa: "08",
    dacion_en_pago: "12",
    subrogacion: "13",
    consignacion: "14",
    condonacion: "15",
    compensacion: "17",
    novacion: "23",
    confusion: "24",
    remision_de_deuda: "25",
    prescripcion_o_caducidad: "26",
    a_satisfaccion_del_acreedor: "27",
    tarjeta_de_debito: "28",
    tarjeta_de_servicios: "29",
    por_definir: "99"
  }

  @type forma_pago_code :: String.t()

  @spec value(t()) :: forma_pago_code()
  def value(key), do: Map.fetch!(@values, key)

  @spec list() :: [%{label: String.t(), value: String.t()}]
  def list do
    [
      %{label: "Efectivo", value: "01"},
      %{label: "Cheque nominativo", value: "02"},
      %{label: "Transferencia electrónica de fondos", value: "03"},
      %{label: "Tarjeta de crédito", value: "04"},
      %{label: "Monedero electrónico", value: "05"},
      %{label: "Dinero electrónico", value: "06"},
      %{label: "Vales de despensa", value: "08"},
      %{label: "Dación en pago", value: "12"},
      %{label: "Pago por subrogación", value: "13"},
      %{label: "Pago por consignación", value: "14"},
      %{label: "Condonación", value: "15"},
      %{label: "Compensación", value: "17"},
      %{label: "Novación", value: "23"},
      %{label: "Confusión", value: "24"},
      %{label: "Remisión de deuda", value: "25"},
      %{label: "Prescripción o caducidad", value: "26"},
      %{label: "A satisfacción del acreedor", value: "27"},
      %{label: "Tarjeta de débito", value: "28"},
      %{label: "Tarjeta de servicios", value: "29"},
      %{label: "Por definir", value: "99"}
    ]
  end

  @spec valid?(String.t()) :: boolean()
  def valid?(code), do: code in Map.values(@values)

  @spec from_code(String.t()) :: {:ok, t()} | :error
  def from_code(code) do
    case Enum.find(@values, fn {_k, v} -> v == code end) do
      {key, _} -> {:ok, key}
      nil -> :error
    end
  end
end
