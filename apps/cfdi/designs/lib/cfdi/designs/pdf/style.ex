defmodule Cfdi.Designs.Pdf.Style do
  @moduledoc false
  defstruct [:font_size, :bold, :align]

  @type t :: %__MODULE__{
          font_size: number() | nil,
          bold: boolean() | nil,
          align: :left | :center | :right | nil
        }
end
