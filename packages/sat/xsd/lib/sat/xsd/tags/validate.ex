defmodule Sat.Xsd.Validate do
  @moduledoc false

  @doc """
  Valida `data` contra un esquema ya resuelto con `ExJsonSchema.Schema.resolve/1`.
  """
  @spec validate(ExJsonSchema.Schema.root(), map()) :: :ok | {:error, list()}
  def validate(schema, data) when is_map(data) do
    case ExJsonSchema.Validator.validate(schema, data) do
      :ok -> :ok
      {:error, errors} -> {:error, errors}
    end
  end

  def validate(_schema, _), do: {:error, :invalid_data_type}
end
