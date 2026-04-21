defmodule Cfdi.Types.Comprobante do
  @moduledoc """
  Atributos del elemento `cfdi:Comprobante` (CFDI 4.0).
  """

  defstruct [
    :Version,
    :Serie,
    :Folio,
    :Fecha,
    :FormaPago,
    :CondicionesDePago,
    :SubTotal,
    :Descuento,
    :Moneda,
    :TipoCambio,
    :Total,
    :TipoDeComprobante,
    :Exportacion,
    :MetodoPago,
    :LugarExpedicion,
    :Confirmacion,
    :NoCertificado,
    :Certificado,
    :Sello
  ]

  @type t :: %__MODULE__{
          Version: String.t() | nil,
          Serie: String.t() | nil,
          Folio: String.t() | nil,
          Fecha: String.t() | nil,
          FormaPago: String.t() | nil,
          CondicionesDePago: String.t() | nil,
          SubTotal: String.t() | nil,
          Descuento: String.t() | nil,
          Moneda: String.t() | nil,
          TipoCambio: String.t() | nil,
          Total: String.t() | nil,
          TipoDeComprobante: String.t() | nil,
          Exportacion: String.t() | nil,
          MetodoPago: String.t() | nil,
          LugarExpedicion: String.t() | nil,
          Confirmacion: String.t() | nil,
          NoCertificado: String.t() | nil,
          Certificado: String.t() | nil,
          Sello: String.t() | nil
        }
end
