defmodule Sat.Csf.Document do
  @moduledoc """
  Estructura del resultado de parsear una Constancia de Situación Fiscal (CSF)
  emitida por el SAT.

  Los sub-structs viven en este mismo módulo (`Identificacion`, `Domicilio`,
  `ActividadEconomica`, `Regimen`, `Obligacion`) para mantener el árbol de
  archivos plano.
  """

  alias Sat.Csf.{Identificacion, Domicilio, ActividadEconomica, Regimen, Obligacion}

  @type t :: %__MODULE__{
          identificacion: Identificacion.t(),
          domicilio: Domicilio.t(),
          actividades_economicas: [ActividadEconomica.t()],
          regimenes: [Regimen.t()],
          obligaciones: [Obligacion.t()]
        }

  defstruct identificacion: nil,
            domicilio: nil,
            actividades_economicas: [],
            regimenes: [],
            obligaciones: []
end

defmodule Sat.Csf.Identificacion do
  @moduledoc "Datos de identificación del contribuyente."

  @type t :: %__MODULE__{
          rfc: String.t() | nil,
          curp: String.t() | nil,
          nombre: String.t() | nil,
          primer_apellido: String.t() | nil,
          segundo_apellido: String.t() | nil,
          fecha_inicio_operaciones: String.t() | nil,
          estatus_padron: String.t() | nil,
          fecha_ultimo_cambio_estado: String.t() | nil,
          nombre_comercial: String.t() | nil
        }

  defstruct [
    :rfc,
    :curp,
    :nombre,
    :primer_apellido,
    :segundo_apellido,
    :fecha_inicio_operaciones,
    :estatus_padron,
    :fecha_ultimo_cambio_estado,
    :nombre_comercial
  ]
end

defmodule Sat.Csf.Domicilio do
  @moduledoc "Datos del domicilio registrado."

  @type t :: %__MODULE__{
          codigo_postal: String.t() | nil,
          tipo_vialidad: String.t() | nil,
          nombre_vialidad: String.t() | nil,
          numero_exterior: String.t() | nil,
          numero_interior: String.t() | nil,
          colonia: String.t() | nil,
          localidad: String.t() | nil,
          municipio_demarcacion_territorial: String.t() | nil,
          entidad_federativa: String.t() | nil,
          entre_calle: String.t() | nil,
          y_calle: String.t() | nil
        }

  defstruct [
    :codigo_postal,
    :tipo_vialidad,
    :nombre_vialidad,
    :numero_exterior,
    :numero_interior,
    :colonia,
    :localidad,
    :municipio_demarcacion_territorial,
    :entidad_federativa,
    :entre_calle,
    :y_calle
  ]
end

defmodule Sat.Csf.ActividadEconomica do
  @moduledoc "Fila de la tabla `Actividades Económicas`."

  @type t :: %__MODULE__{
          orden: pos_integer(),
          actividad_economica: String.t(),
          porcentaje: integer(),
          fecha_inicio: String.t() | nil,
          fecha_fin: String.t() | nil
        }

  defstruct [:orden, :actividad_economica, :porcentaje, :fecha_inicio, :fecha_fin]
end

defmodule Sat.Csf.Regimen do
  @moduledoc """
  Fila de la tabla `Regímenes`.

  `:codigo` se enriquece desde `Sat.Catalogos.RegimenFiscal` cuando hay match.
  Es `nil` cuando el label del PDF no corresponde a ninguna entrada del catálogo.
  """

  @type t :: %__MODULE__{
          regimen: String.t(),
          codigo: String.t() | nil,
          fecha_inicio: String.t() | nil,
          fecha_fin: String.t() | nil
        }

  defstruct [:regimen, :codigo, :fecha_inicio, :fecha_fin]
end

defmodule Sat.Csf.Obligacion do
  @moduledoc "Fila de la tabla `Obligaciones`."

  @type t :: %__MODULE__{
          descripcion_obligacion: String.t(),
          descripcion_vencimiento: String.t(),
          fecha_inicio: String.t() | nil,
          fecha_fin: String.t() | nil
        }

  defstruct [:descripcion_obligacion, :descripcion_vencimiento, :fecha_inicio, :fecha_fin]
end
