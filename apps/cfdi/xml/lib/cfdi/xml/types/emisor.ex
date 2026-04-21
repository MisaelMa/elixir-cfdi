defmodule Cfdi.Xml.Types.Emisor do
  @moduledoc false

  defstruct [:Rfc, :Nombre, :RegimenFiscal, :FacAtrAdquirente]

  @type t :: %__MODULE__{
          Rfc: String.t() | nil,
          Nombre: String.t() | nil,
          RegimenFiscal: String.t() | nil,
          FacAtrAdquirente: String.t() | nil
        }
end
