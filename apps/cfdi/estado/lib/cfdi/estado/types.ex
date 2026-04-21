defmodule Cfdi.Estado.Types do
  @moduledoc """
  Types for CFDI status consultation.
  """

  defmodule ConsultaParams do
    @moduledoc false
    defstruct [:rfc_emisor, :rfc_receptor, :total, :uuid]

    @type t :: %__MODULE__{
            rfc_emisor: String.t(),
            rfc_receptor: String.t(),
            total: String.t(),
            uuid: String.t()
          }
  end

  defmodule ConsultaResult do
    @moduledoc false
    defstruct [
      :codigo_estatus,
      :es_cancelable,
      :estado,
      :estatus_cancelacion,
      :validacion_efos,
      activo: false,
      cancelado: false,
      no_encontrado: false
    ]

    @type t :: %__MODULE__{
            codigo_estatus: String.t(),
            es_cancelable: String.t(),
            estado: String.t(),
            estatus_cancelacion: String.t(),
            validacion_efos: String.t(),
            activo: boolean(),
            cancelado: boolean(),
            no_encontrado: boolean()
          }
  end
end
