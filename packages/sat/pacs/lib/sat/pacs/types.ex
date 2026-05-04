defmodule Sat.Pacs.Types do
  @moduledoc false

  defmodule PacProviderType do
    @moduledoc false
    def finkok, do: :finkok
    def custom, do: :custom
  end

  defmodule PacConfig do
    @moduledoc false
    defstruct [:provider, :base_url, :username, :password, :timeout]

    @type t :: %__MODULE__{
            provider: atom(),
            base_url: String.t(),
            username: String.t() | nil,
            password: String.t() | nil,
            timeout: pos_integer()
          }
  end

  defmodule TimbradoRequest do
    @moduledoc false
    defstruct [:xml, :extras]

    @type t :: %__MODULE__{xml: String.t(), extras: map()}
  end

  defmodule TimbradoResult do
    @moduledoc false
    defstruct [:xml, :uuid, :codigo, :mensaje]

    @type t :: %__MODULE__{
            xml: String.t() | nil,
            uuid: String.t() | nil,
            codigo: String.t() | nil,
            mensaje: String.t() | nil
          }
  end

  defmodule CancelacionPacResult do
    @moduledoc false
    defstruct [:uuid, :codigo, :mensaje, :estatus]

    @type t :: %__MODULE__{
            uuid: String.t() | nil,
            codigo: String.t() | nil,
            mensaje: String.t() | nil,
            estatus: String.t() | nil
          }
  end

  defmodule ConsultaEstatusResult do
    @moduledoc false
    defstruct [:uuid, :codigo, :mensaje, :cancelable]

    @type t :: %__MODULE__{
            uuid: String.t() | nil,
            codigo: String.t() | nil,
            mensaje: String.t() | nil,
            cancelable: boolean() | nil
          }
  end
end
