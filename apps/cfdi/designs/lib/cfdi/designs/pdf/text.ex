defmodule Cfdi.Designs.Pdf.Text do
  @moduledoc false
  defstruct [:content, :style]

  @type t :: %__MODULE__{
          content: String.t(),
          style: Cfdi.Designs.Pdf.Style.t() | nil
        }
end
