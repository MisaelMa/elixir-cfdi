defmodule Cfdi.Designs.PDF117 do
  @moduledoc """
  Default CFDI printable layout (A117-style). Rendering is not wired until a PDF engine is added.
  """

  @behaviour Cfdi.Designs.GeneradorPdf

  @impl true
  def generate(_comprobante, _opts) do
    {:error, "PDF117.generate/2 requires a PDF engine dependency"}
  end
end
