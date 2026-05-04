defmodule Cfdi.Schema.Common.ProcessorFactory do
  @moduledoc false

  alias Cfdi.Schema.Common.{JsonProcessor, XsdProcessor}

  @spec detect(String.t()) :: {:ok, :json | :xsd} | {:error, :unknown_schema_type}
  def detect(name) do
    ext = name |> Path.extname() |> String.downcase()

    cond do
      ext in [".json"] -> {:ok, :json}
      ext in [".xsd", ".xs"] -> {:ok, :xsd}
      true -> {:error, :unknown_schema_type}
    end
  end

  def processor_for(:json), do: JsonProcessor
  def processor_for(:xsd), do: XsdProcessor
end
