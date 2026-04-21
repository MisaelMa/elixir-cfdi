defmodule Sat.Opinion.Types do
  @moduledoc false

  defmodule ResultadoOpinion do
    @moduledoc false
    defstruct [:positiva, :detalle, :fecha_consulta]

    @type t :: %__MODULE__{
            positiva: boolean() | nil,
            detalle: String.t() | nil,
            fecha_consulta: DateTime.t() | nil
          }
  end

  defmodule ObligacionFiscal do
    @moduledoc false
    defstruct [:clave, :descripcion, :cumple]

    @type t :: %__MODULE__{
            clave: String.t(),
            descripcion: String.t(),
            cumple: boolean() | nil
          }
  end

  defmodule OpinionCumplimiento do
    @moduledoc false
    defstruct [:resultado, :obligaciones]

    @type t :: %__MODULE__{
            resultado: ResultadoOpinion.t() | nil,
            obligaciones: [ObligacionFiscal.t()]
          }
  end

  defmodule OpinionConfig do
    @moduledoc false
    defstruct [:base_url, :timeout]

    @type t :: %__MODULE__{base_url: String.t(), timeout: pos_integer()}
  end

  @typedoc """
  Session-like struct with cookies or bearer token for authenticated portal calls.
  """
  @type sesion_portal_like :: term()
end
