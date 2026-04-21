defmodule Cfdi.Complementos.Pago20 do
  @moduledoc false
  @behaviour Cfdi.Complementos.Complemento

  @key "pago20:Pagos"
  @xmlns "http://www.sat.gob.mx/Pagos20"
  @xsd "http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd"

  defstruct [:data]

  @type data :: map()
  @type t :: %__MODULE__{data: data()}

  @doc """
  Crea un builder del complemento a partir de un mapa (o struct, como mapa).
  """
  @spec new(map()) :: t()
  def new(data) when is_map(data), do: %__MODULE__{data: data}

  @impl Cfdi.Complementos.Complemento
  def get_complement(%__MODULE__{data: data}) do
    xmlns_key = @key |> String.split(":", parts: 2) |> hd()

    %{
      complement: data,
      key: @key,
      schema_location: @xmlns <> " " <> @xsd,
      xmlns: @xmlns,
      xmlns_key: xmlns_key
    }
  end
end
