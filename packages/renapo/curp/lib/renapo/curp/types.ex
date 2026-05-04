defmodule Renapo.Curp.Types do
  @moduledoc false

  defmodule Mexican do
    @moduledoc false
    defstruct [:primer_apellido, :segundo_apellido, :nombre, :sexo, :fecha_nacimiento, :entidad]

    @type t :: %__MODULE__{
            primer_apellido: String.t(),
            segundo_apellido: String.t() | nil,
            nombre: String.t(),
            sexo: :hombre | :mujer,
            fecha_nacimiento: Date.t(),
            entidad: String.t()
          }
  end

  defmodule Renapo do
    @moduledoc false
    defstruct [:curp, :datos, :status]

    @type t :: %__MODULE__{
            curp: String.t(),
            datos: map(),
            status: String.t() | nil
          }
  end

  defmodule DocProbatorio do
    @moduledoc false
    defstruct [:tipo, :descripcion]

    @type t :: %__MODULE__{tipo: String.t(), descripcion: String.t() | nil}
  end

  defmodule Registro do
    @moduledoc false
    defstruct [:curp, :status, :documentos]

    @type t :: %__MODULE__{
            curp: String.t(),
            status: String.t() | nil,
            documentos: [DocProbatorio.t()]
          }
  end
end
