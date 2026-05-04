defmodule Cfdi.Designs.GeneradorPdf do
  @moduledoc false

  @doc """
  Generates a PDF for the given comprobante payload (map/struct) and options.
  """
  @callback generate(term(), keyword()) :: {:ok, binary()} | {:error, term()}
end
