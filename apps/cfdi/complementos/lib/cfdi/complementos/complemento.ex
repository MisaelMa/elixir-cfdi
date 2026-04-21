defmodule Cfdi.Complementos.Complemento do
  @moduledoc """
  Estructura base y comportamiento común de los complementos SAT.

  Cada complemento concreto define `new/1` y `get_complement/1`, devolviendo
  metadatos (`key`, `xmlns`, `schema_location`, `xmlns_key`) junto con la
  carga útil (`complement`).
  """

  defstruct [:key, :xmlns, :xsd, :data]

  @type t :: %__MODULE__{
          key: String.t() | nil,
          xmlns: String.t() | nil,
          xsd: String.t() | nil,
          data: term() | nil
        }

  @typedoc """
  Mapa estándar para ensamblar `cfdi:Complemento` y `xsi:schemaLocation`.
  """
  @type complement_result :: %{
          complement: term(),
          key: String.t(),
          schema_location: String.t(),
          xmlns: String.t(),
          xmlns_key: String.t()
        }

  @callback get_complement(term()) :: complement_result()
end
