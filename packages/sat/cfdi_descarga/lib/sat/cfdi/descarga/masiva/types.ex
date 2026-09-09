defmodule Sat.Cfdi.Descarga.Masiva.Types do
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
      :tipo_descarga,
      :tipo_comprobante,
      :estado_comprobante,
      :rfc_a_cuenta_terceros,
      :complemento,
      :uuid
    ]

    # `tipo_solicitud` = DIRECCIÓN (operación SOAP): :emitidos | :recibidos | :folio.
    # `tipo_descarga`  = TIPO de contenido (atributo TipoSolicitud): :cfdi | :metadata.
    # Antes ambos ejes se mezclaban en `tipo_solicitud` (por eso :metadata/:cfdi
    # siguen aceptándose como legacy y se infiere `tipo_descarga`). Separarlos
    # permite pedir Metadata de RECIBIDOS (no solo emitidos).
    @type tipo_solicitud :: :emitidos | :recibidos | :folio | :metadata | :cfdi
    @type tipo_descarga :: :cfdi | :metadata
    @type tipo_comprobante :: :null | :i | :e | :t | :n | :p
    @type estado_comprobante :: :todos | :cancelado | :vigente

    @type t :: %__MODULE__{
            rfc_solicitante: String.t(),
            rfc_emisor: String.t() | nil,
            rfc_receptor: String.t() | [String.t()] | nil,
            fecha_inicial: DateTime.t() | String.t(),
            fecha_final: DateTime.t() | String.t(),
            tipo_solicitud: tipo_solicitud(),
            tipo_descarga: tipo_descarga() | nil,
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
    @moduledoc """
    Resultado del paso `VerificaSolicitudDescarga`.

    Ojo con los DOS codigos, que no son lo mismo:

      * `cod_estatus` — `CodEstatus`: como le fue a la LLAMADA. `"5000"` = ok;
        `"404"` = error no controlado (p. ej. el `IdSolicitud` no existe o no
        es de ese RFC); `"305"` = certificado invalido, etc.
      * `codigo_estado_solicitud` — `CodigoEstadoSolicitud`: como le fue a la
        SOLICITUD ya registrada (`"5000"` ok, `"5004"` sin datos...).

    Cuando `cod_estatus` trae un error, el SAT responde SIN
    `CodigoEstadoSolicitud`, sin `IdsPaquetes` y con `EstadoSolicitud="0"`
    (que no es un estado valido). Revisa `cod_estatus` ANTES que
    `estado_solicitud`.
    """
    defstruct [
      :id_solicitud,
      :estado_solicitud,
      :cod_estatus,
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
            cod_estatus: String.t(),
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
