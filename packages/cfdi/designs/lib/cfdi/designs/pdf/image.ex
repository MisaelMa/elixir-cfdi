defmodule Cfdi.Designs.Pdf.Image do
  @moduledoc false
  defstruct [:path, :data, :width, :height]

  @type t :: %__MODULE__{
          path: String.t() | nil,
          data: binary() | nil,
          width: number() | nil,
          height: number() | nil
        }
end
