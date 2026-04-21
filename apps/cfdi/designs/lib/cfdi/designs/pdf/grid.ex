defmodule Cfdi.Designs.Pdf.Grid do
  @moduledoc false
  defstruct [:rows, :columns, :cells]

  @type t :: %__MODULE__{
          rows: pos_integer(),
          columns: pos_integer(),
          cells: [Cfdi.Designs.Pdf.Cell.t()]
        }
end
