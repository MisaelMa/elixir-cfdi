defmodule Cfdi.Designs.Pdf.Column do
  @moduledoc false
  defstruct [:width, :align]

  @type t :: %__MODULE__{
          width: number() | nil,
          align: :left | :center | :right | nil
        }
end
