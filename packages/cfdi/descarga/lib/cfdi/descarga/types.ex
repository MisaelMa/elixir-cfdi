defmodule Cfdi.Descarga.Types do
  @moduledoc false

  defmodule TipoSolicitud do
    @moduledoc false
    def cfdi, do: "CFDI"
    def metadata, do: "Metadata"
  end

  defmodule TipoDescarga do
    @moduledoc false
    def emitidos, do: "RfcEmisor"
    def recibidos, do: "RfcReceptor"
  end

  defmodule EstadoSolicitud do
    @moduledoc false
    def aceptada, do: 1
    def en_proceso, do: 2
    def terminada, do: 3
    def error, do: 4
    def rechazada, do: 5
    def vencida, do: 6

    @spec descripcion(integer()) :: String.t()
    def descripcion(1), do: "Aceptada"
    def descripcion(2), do: "En proceso"
    def descripcion(3), do: "Terminada"
    def descripcion(4), do: "Error"
    def descripcion(5), do: "Rechazada"
    def descripcion(6), do: "Vencida"
    def descripcion(_), do: "Desconocido"
  end

  defmodule EstadoComprobante do
    @moduledoc false
    def cancelado, do: "0"
    def vigente, do: "1"
  end

  defmodule SolicitudParams do
    @moduledoc false
    defstruct [
      :rfc_solicitante,
      :fecha_inicio,
      :fecha_fin,
      :tipo_solicitud,
      :tipo_descarga,
      :rfc_emisor,
      :rfc_receptor,
      :estado_comprobante
    ]

    @type t :: %__MODULE__{
            rfc_solicitante: String.t(),
            fecha_inicio: String.t(),
            fecha_fin: String.t(),
            tipo_solicitud: String.t(),
            tipo_descarga: String.t(),
            rfc_emisor: String.t() | nil,
            rfc_receptor: String.t() | nil,
            estado_comprobante: String.t() | nil
          }
  end

  defmodule SolicitudResult do
    @moduledoc false
    defstruct [:id_solicitud, :cod_estatus, :mensaje]

    @type t :: %__MODULE__{
            id_solicitud: String.t(),
            cod_estatus: String.t(),
            mensaje: String.t()
          }
  end

  defmodule VerificacionResult do
    @moduledoc false
    defstruct [
      :estado,
      :estado_descripcion,
      :cod_estatus,
      :mensaje,
      :ids_paquetes,
      :numero_cfdis
    ]

    @type t :: %__MODULE__{
            estado: integer(),
            estado_descripcion: String.t(),
            cod_estatus: String.t(),
            mensaje: String.t(),
            ids_paquetes: [String.t()],
            numero_cfdis: integer()
          }
  end
end
