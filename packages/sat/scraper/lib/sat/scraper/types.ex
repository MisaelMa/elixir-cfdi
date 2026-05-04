defmodule Sat.Scraper.Types do
  @moduledoc false

  defmodule TipoAutenticacion do
    @moduledoc false
    def ciec, do: :ciec
    def fiel, do: :fiel
  end

  defmodule CredencialCIEC do
    @moduledoc false
    defstruct [:rfc, :password]

    @type t :: %__MODULE__{rfc: String.t(), password: String.t()}
  end

  defmodule CredencialFIEL do
    @moduledoc false
    defstruct [:certificate_path, :private_key_path, :password]

    @type t :: %__MODULE__{
            certificate_path: String.t(),
            private_key_path: String.t(),
            password: String.t() | nil
          }
  end

  defmodule CredencialPortal do
    @moduledoc false
    defstruct [:tipo, :ciec, :fiel]

    @type t :: %__MODULE__{
            tipo: :ciec | :fiel,
            ciec: CredencialCIEC.t() | nil,
            fiel: CredencialFIEL.t() | nil
          }
  end

  defmodule SesionSAT do
    @moduledoc false
    defstruct [:cookies, :meta]

    @type t :: %__MODULE__{cookies: keyword() | map(), meta: map()}
  end

  defmodule ConsultaCfdiParams do
    @moduledoc false
    defstruct [:rfc, :fecha_inicio, :fecha_fin, :tipo]

    @type t :: %__MODULE__{
            rfc: String.t(),
            fecha_inicio: String.t() | nil,
            fecha_fin: String.t() | nil,
            tipo: atom() | nil
          }
  end

  defmodule CfdiConsultaResult do
    @moduledoc false
    defstruct [:items, :raw]

    @type t :: %__MODULE__{items: list(), raw: map()}
  end

  defmodule ScraperConfig do
    @moduledoc false
    defstruct [:base_url, :timeout, :user_agent]

    @type t :: %__MODULE__{
            base_url: String.t(),
            timeout: pos_integer(),
            user_agent: String.t()
          }
  end
end
