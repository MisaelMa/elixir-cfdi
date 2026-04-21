defmodule Cfdi.Designs.Pdf.PDF do
  @moduledoc false
  defstruct [:pages, :meta]

  @type t :: %__MODULE__{pages: list(), meta: map()}
end
