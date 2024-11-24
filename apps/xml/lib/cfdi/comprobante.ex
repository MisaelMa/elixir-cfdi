defmodule Sat.Cfdi.Comprobante do
  defstruct xsi: %{
              xmlns: nil,
              schemaLocation: []
            },
            Version: nil,
            Serie: nil,
            Folio: nil,
            Fecha: :string,
            # FormaPago
            FormaPago: :string,
            CondicionesDePago: :string,
            SubTotal: :string,
            Descuento: nil,
            Moneda: :string,
            TipoCambio: nil,
            Total: :string,
            # TipoComprobante | TypeComprobante;
            TipoDeComprobante: :string,
            # ExportacionEnum | ExportacionType | string;
            Exportacion: :string,
            # MetodoPago | MetodoPagoType;
            MetodoPago: nil,
            LugarExpedicion: :string,
            Confirmacion: nil
end
