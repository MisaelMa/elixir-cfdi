defmodule Cfdi.Designs.Pdf.Row do
  @moduledoc false
  defstruct [:cells]

  @type t :: %__MODULE__{cells: [Cfdi.Designs.Pdf.Cell.t()]}
end
