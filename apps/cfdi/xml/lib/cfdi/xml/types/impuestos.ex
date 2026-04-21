defmodule Cfdi.Xml.Types.Impuestos do
  @moduledoc false

  defstruct [
    :TotalImpuestosTrasladados,
    :TotalImpuestosRetenidos,
    :traslados,
    :retenciones
  ]

  @type t :: %__MODULE__{
          TotalImpuestosTrasladados: String.t() | nil,
          TotalImpuestosRetenidos: String.t() | nil,
          traslados: [Cfdi.Xml.Types.Traslado.t()] | nil,
          retenciones: [Cfdi.Xml.Types.Retencion.t()] | nil
        }
end

defmodule Cfdi.Xml.Types.Traslado do
  @moduledoc false

  defstruct [:Base, :Impuesto, :TipoFactor, :TasaOCuota, :Importe]

  @type t :: %__MODULE__{
          Base: String.t() | nil,
          Impuesto: String.t() | nil,
          TipoFactor: String.t() | nil,
          TasaOCuota: String.t() | nil,
          Importe: String.t() | nil
        }
end

defmodule Cfdi.Xml.Types.Retencion do
  @moduledoc false

  defstruct [:Base, :Impuesto, :TipoFactor, :TasaOCuota, :Importe]

  @type t :: %__MODULE__{
          Base: String.t() | nil,
          Impuesto: String.t() | nil,
          TipoFactor: String.t() | nil,
          TasaOCuota: String.t() | nil,
          Importe: String.t() | nil
        }
end
