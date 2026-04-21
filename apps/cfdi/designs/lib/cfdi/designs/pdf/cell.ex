defmodule Cfdi.Designs.Pdf.Cell do
  @moduledoc false
  defstruct [:content, :colspan, :rowspan, :style]

  @type t :: %__MODULE__{
          content: Cfdi.Designs.Pdf.Text.t() | String.t() | nil,
          colspan: pos_integer(),
          rowspan: pos_integer(),
          style: Cfdi.Designs.Pdf.Style.t() | nil
        }
end
