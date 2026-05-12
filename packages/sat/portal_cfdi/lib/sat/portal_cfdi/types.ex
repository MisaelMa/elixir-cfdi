defmodule Sat.PortalCfdi.Types do
  @moduledoc """
  Structs y tipos para el cliente del portal CFDI del SAT.
  """

  defmodule TipoAutenticacion do
    @moduledoc false
    def ciec, do: :ciec
    def fiel, do: :fiel
  end

  defmodule CredencialCIEC do
    @moduledoc "Credenciales CIEC (RFC + contrasena)."
    defstruct [:rfc, :password]

    @type t :: %__MODULE__{rfc: String.t(), password: String.t()}
  end

  defmodule CredencialFIEL do
    @moduledoc "Credenciales FIEL (rutas a .cer/.key + contrasena)."
    defstruct [:certificate_path, :private_key_path, :password]

    @type t :: %__MODULE__{
            certificate_path: String.t(),
            private_key_path: String.t(),
            password: String.t() | nil
          }
  end

  defmodule CredencialPortal do
    @moduledoc "Union de credenciales CIEC o FIEL para iniciar sesion."
    defstruct [:tipo, :ciec, :fiel]

    @type t :: %__MODULE__{
            tipo: :ciec | :fiel,
            ciec: CredencialCIEC.t() | nil,
            fiel: CredencialFIEL.t() | nil
          }
  end

  defmodule SesionSAT do
    @moduledoc "Estado de la sesion: cookies y metadatos."
    defstruct [:cookies, :rfc, :authenticated, :expires_at, :meta]

    @type t :: %__MODULE__{
            cookies: keyword() | map(),
            rfc: String.t() | nil,
            authenticated: boolean(),
            expires_at: DateTime.t() | nil,
            meta: map()
          }
  end

  defmodule ConsultaCfdiParams do
    @moduledoc "Parametros de consulta por rango de fechas."
    defstruct [:rfc, :fecha_inicio, :fecha_fin, :tipo, :rfc_receptor, :estado]

    @type t :: %__MODULE__{
            rfc: String.t() | nil,
            fecha_inicio: String.t() | nil,
            fecha_fin: String.t() | nil,
            tipo: :emitidos | :recibidos | nil,
            rfc_receptor: String.t() | nil,
            estado: :vigente | :cancelado | :todos | nil
          }
  end

  defmodule CfdiConsultaResult do
    @moduledoc "Metadato de un CFDI parseado de la tabla del portal."
    defstruct [
      :uuid,
      :rfc_emisor,
      :nombre_emisor,
      :rfc_receptor,
      :nombre_receptor,
      :fecha_emision,
      :fecha_certificacion,
      :total,
      :efecto,
      :estado
    ]

    @type t :: %__MODULE__{
            uuid: String.t(),
            rfc_emisor: String.t(),
            nombre_emisor: String.t(),
            rfc_receptor: String.t(),
            nombre_receptor: String.t(),
            fecha_emision: String.t(),
            fecha_certificacion: String.t(),
            total: float(),
            efecto: String.t(),
            estado: String.t()
          }
  end

  defmodule PortalConfig do
    @moduledoc "Configuracion del cliente HTTP."
    defstruct [:base_url, :timeout, :user_agent]

    @type t :: %__MODULE__{
            base_url: String.t(),
            timeout: pos_integer(),
            user_agent: String.t()
          }
  end
end
