defmodule Cfdi.Types.Impuestos do
  @moduledoc """
  Nodo `cfdi:Impuestos` del comprobante: totales y listas de traslados y retenciones.
  """

  defstruct [
    :TotalImpuestosTrasladados,
    :TotalImpuestosRetenidos,
    :traslados,
    :retenciones
  ]

  @type t :: %__MODULE__{
          TotalImpuestosTrasladados: String.t() | nil,
          TotalImpuestosRetenidos: String.t() | nil,
          traslados: [Cfdi.Types.Traslado.t()] | nil,
          retenciones: [Cfdi.Types.Retencion.t()] | nil
        }
end

defmodule Cfdi.Types.Traslado do
  @moduledoc """
  Traslado de impuestos (comprobante o concepto).
  """

  defstruct [:Base, :Impuesto, :TipoFactor, :TasaOCuota, :Importe]

  @type t :: %__MODULE__{
          Base: String.t() | nil,
          Impuesto: String.t() | nil,
          TipoFactor: String.t() | nil,
          TasaOCuota: String.t() | nil,
          Importe: String.t() | nil
        }
end

defmodule Cfdi.Types.Retencion do
  @moduledoc """
  Retención de impuestos (comprobante o concepto).
  """

  defstruct [:Base, :Impuesto, :TipoFactor, :TasaOCuota, :Importe]

  @type t :: %__MODULE__{
          Base: String.t() | nil,
          Impuesto: String.t() | nil,
          TipoFactor: String.t() | nil,
          TasaOCuota: String.t() | nil,
          Importe: String.t() | nil
        }
end
