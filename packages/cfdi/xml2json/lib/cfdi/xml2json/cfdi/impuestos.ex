defmodule Cfdi.Xml2Json.Cfdi.Impuestos do
  @moduledoc """
  Espejo de la clase `Impuestos` del paquete TypeScript: simplemente
  envuelve el mapa de datos provenientes del XML.
  """

  defstruct data: %{}

  @type t :: %__MODULE__{data: map()}

  @spec new(map()) :: t()
  def new(data) when is_map(data), do: %__MODULE__{data: data}
end
