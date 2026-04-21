defmodule Cfdi.Types.Receptor do
  @moduledoc """
  Atributos del elemento `cfdi:Receptor`.
  """

  defstruct [
    :Rfc,
    :Nombre,
    :UsoCFDI,
    :DomicilioFiscalReceptor,
    :ResidenciaFiscal,
    :NumRegIdTrib,
    :RegimenFiscalReceptor
  ]

  @type t :: %__MODULE__{
          Rfc: String.t() | nil,
          Nombre: String.t() | nil,
          UsoCFDI: String.t() | nil,
          DomicilioFiscalReceptor: String.t() | nil,
          ResidenciaFiscal: String.t() | nil,
          NumRegIdTrib: String.t() | nil,
          RegimenFiscalReceptor: String.t() | nil
        }
end
