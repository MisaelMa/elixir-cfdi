defmodule Cfdi.Pdf.Types do
  @moduledoc """
  Type definitions for PDF generation options.
  """

  defmodule Logo do
    @moduledoc false
    defstruct [:width, :image, :height]

    @type t :: %__MODULE__{
            width: number() | String.t(),
            image: String.t(),
            height: number() | String.t()
          }
  end

  defmodule OptionsPdf do
    @moduledoc false
    defstruct [:logo, :lugar_expedicion, :fonts]

    @type t :: %__MODULE__{
            logo: String.t() | Logo.t() | nil,
            lugar_expedicion: String.t() | nil,
            fonts: map() | nil
          }
  end
end
