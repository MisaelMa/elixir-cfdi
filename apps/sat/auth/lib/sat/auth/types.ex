defmodule Sat.Auth.Types do
  @moduledoc """
  Types for SAT authentication tokens and credential duck-typing.
  """

  defmodule SatToken do
    @moduledoc false
    defstruct [:value, :created, :expires]

    @type t :: %__MODULE__{
            value: String.t(),
            created: DateTime.t(),
            expires: DateTime.t()
          }
  end

  @typedoc """
  Any struct that can supply a certificate and sign UTF-8/XML fragments with RSA-SHA256 (Base64).

  Typically `%Cfdi.Csd.Credential{}`.
  """
  @type credential_like :: Cfdi.Csd.Credential.t() | term()
end
