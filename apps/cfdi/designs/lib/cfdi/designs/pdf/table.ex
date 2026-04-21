defmodule Cfdi.Designs.Pdf.Table do
  @moduledoc false
  defstruct [:columns, :rows, :style]

  @type t :: %__MODULE__{
          columns: [Cfdi.Designs.Pdf.Column.t()],
          rows: [Cfdi.Designs.Pdf.Row.t()],
          style: Cfdi.Designs.Pdf.Style.t() | nil
        }
end
