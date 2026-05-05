defmodule Sat.Xsd.Comprobante do
  @moduledoc false

  alias Sat.Xsd.Validate

  @doc """
  Valida el mapa de un comprobante (nodo raíz y metadatos esperados por el SAT).
  """
  @spec validate(ExJsonSchema.Schema.root(), map()) :: :ok | {:error, term()}
  def validate(schema, data) do
    Validate.validate(schema, data)
  end
end
