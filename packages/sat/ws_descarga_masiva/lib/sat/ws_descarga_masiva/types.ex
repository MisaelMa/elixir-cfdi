defmodule Sat.WsDescargaMasiva.Types do
  @moduledoc """
  Structs y tipos para el WS de Descarga Masiva del SAT.
  """

  defmodule Token do
    @moduledoc "Token Bearer obtenido por la autenticacion."
    defstruct [:value, :issued_at, :expires_at]

    @type t :: %__MODULE__{
            value: String.t(),
            issued_at: DateTime.t(),
            expires_at: DateTime.t()
          }
  end

  defmodule SolicitudParams do
    @moduledoc "Parametros para registrar una solicitud de descarga."
    defstruct [
      :rfc_solicitante,
      :rfc_emisor,
      :rfc_receptor,
      :fecha_inicial,
      :fecha_final,
      :tipo_solicitud,
      :tipo_comprobante,
      :estado_comprobante,
      :rfc_a_cuenta_terceros,
      :complemento,
      :uuid
    ]

    @type tipo_solicitud :: :metadata | :cfdi
    @type tipo_comprobante :: :null | :i | :e | :t | :n | :p
    @type estado_comprobante :: :todos | :cancelado | :vigente

    @type t :: %__MODULE__{
            rfc_solicitante: String.t(),
            rfc_emisor: String.t() | nil,
            rfc_receptor: String.t() | [String.t()] | nil,
            fecha_inicial: DateTime.t() | String.t(),
            fecha_final: DateTime.t() | String.t(),
            tipo_solicitud: tipo_solicitud(),
            tipo_comprobante: tipo_comprobante() | nil,
            estado_comprobante: estado_comprobante() | nil,
            rfc_a_cuenta_terceros: String.t() | nil,
            complemento: String.t() | nil,
            uuid: String.t() | nil
          }
  end

  defmodule SolicitudResult do
    @moduledoc "Resultado del paso `SolicitaDescarga`."
    defstruct [:id_solicitud, :cod_estatus, :mensaje]

    @type t :: %__MODULE__{
            id_solicitud: String.t() | nil,
            cod_estatus: String.t(),
            mensaje: String.t()
          }
  end

  defmodule VerificacionResult do
    @moduledoc "Resultado del paso `VerificaSolicitudDescarga`."
    defstruct [
      :id_solicitud,
      :estado_solicitud,
      :codigo_estado_solicitud,
      :numero_cfdis,
      :mensaje,
      :ids_paquetes
    ]

    @type estado_solicitud ::
            :aceptada | :en_proceso | :terminada | :error | :rechazada | :vencida

    @type t :: %__MODULE__{
            id_solicitud: String.t(),
            estado_solicitud: estado_solicitud() | non_neg_integer(),
            codigo_estado_solicitud: String.t(),
            numero_cfdis: non_neg_integer(),
            mensaje: String.t() | nil,
            ids_paquetes: [String.t()]
          }
  end

  defmodule Paquete do
    @moduledoc "Paquete descargado (ZIP en bytes) listo para extraer."
    defstruct [:id, :content, :size]

    @type t :: %__MODULE__{
            id: String.t(),
            content: binary(),
            size: non_neg_integer()
          }
  end
end
