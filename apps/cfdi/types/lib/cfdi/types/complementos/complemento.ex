defmodule Cfdi.Types.Complemento do
  @moduledoc """
  Metadatos y carga útil de un complemento CFDI (namespace, XSD y datos).
  """

  defstruct [:key, :xmlns, :xsd, :data]

  @type t :: %__MODULE__{
          key: String.t(),
          xmlns: String.t(),
          xsd: String.t(),
          data: term()
        }

  @doc """
  Devuelve mapa con datos del complemento y metadatos para `schemaLocation` y xmlns.
  """
  @spec get_complement(t()) :: %{
          complement: term(),
          key: String.t(),
          schema_location: String.t(),
          xmlns: String.t(),
          xmlns_key: String.t()
        }
  def get_complement(%__MODULE__{key: key, xmlns: xmlns, xsd: xsd, data: data}) do
    xmlns_key = key |> String.split(":", parts: 2) |> hd()

    %{
      complement: data,
      key: key,
      schema_location: "#{xmlns} #{xsd}",
      xmlns: xmlns,
      xmlns_key: xmlns_key
    }
  end
end
