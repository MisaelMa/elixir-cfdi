defmodule Cfdi.Types.Emisor do
  @moduledoc """
  Atributos del elemento `cfdi:Emisor`.
  """

  defstruct [:Rfc, :Nombre, :RegimenFiscal, :FacAtrAdquirente]

  @type t :: %__MODULE__{
          Rfc: String.t() | nil,
          Nombre: String.t() | nil,
          RegimenFiscal: String.t() | nil,
          FacAtrAdquirente: String.t() | nil
        }
end
