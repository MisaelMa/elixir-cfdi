defmodule Cfdi.Cancelacion.Types do
  @moduledoc false

  defmodule MotivoCancelacion do
    @moduledoc false
    def con_relacion, do: "01"
    def sin_relacion, do: "02"
    def no_operacion, do: "03"
    def factura_global, do: "04"
  end

  @type estatus_cancelacion :: :en_proceso | :cancelado | :rechazada | :plazo

  defmodule CancelacionParams do
    @moduledoc false
    defstruct [:rfc_emisor, :uuid, :motivo, :folio_sustitucion]

    @type t :: %__MODULE__{
            rfc_emisor: String.t() | nil,
            uuid: String.t(),
            motivo: String.t(),
            folio_sustitucion: String.t() | nil
          }
  end

  defmodule CancelacionResult do
    @moduledoc false
    defstruct [:uuid, :estatus, :cod_estatus, :mensaje]

    @type t :: %__MODULE__{
            uuid: String.t(),
            estatus: Cfdi.Cancelacion.Types.estatus_cancelacion(),
            cod_estatus: String.t(),
            mensaje: String.t()
          }
  end

  defmodule RespuestaAceptacionRechazo do
    @moduledoc false
    def aceptacion, do: "Aceptacion"
    def rechazo, do: "Rechazo"
  end

  defmodule AceptacionRechazoParams do
    @moduledoc false
    defstruct [:rfc_receptor, :uuid, :respuesta]

    @type t :: %__MODULE__{
            rfc_receptor: String.t(),
            uuid: String.t(),
            respuesta: String.t()
          }
  end

  defmodule AceptacionRechazoResult do
    @moduledoc false
    defstruct [:uuid, :cod_estatus, :mensaje]

    @type t :: %__MODULE__{
            uuid: String.t(),
            cod_estatus: String.t(),
            mensaje: String.t()
          }
  end

  defmodule PendientesResult do
    @moduledoc false
    defstruct [:uuid, :rfc_emisor, :fecha_solicitud]

    @type t :: %__MODULE__{
            uuid: String.t(),
            rfc_emisor: String.t(),
            fecha_solicitud: String.t()
          }
  end
end
