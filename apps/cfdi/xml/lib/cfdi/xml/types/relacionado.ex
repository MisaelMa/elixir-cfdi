defmodule Cfdi.Xml.Types.Relacionado do
  @moduledoc false

  defstruct [:UUID, :TipoRelacion]

  @type t :: %__MODULE__{
          UUID: String.t() | nil,
          TipoRelacion: String.t() | nil
        }
end
