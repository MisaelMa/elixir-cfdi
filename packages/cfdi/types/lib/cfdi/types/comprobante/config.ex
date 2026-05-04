defmodule Cfdi.Types.Config do
  @moduledoc """
  Configuración para validación, transformación o serialización de CFDI.

  Campos alineados con herramientas que requieren rutas a esquemas XSD, modo
  depuración, ejecutable Saxon y hojas XSLT por complemento o proceso.
  """

  defstruct [
    :schema_path,
    :debug,
    :saxon_path,
    :xslt_sheets
  ]

  @type xslt_sheets :: %{optional(String.t()) => String.t()}

  @type t :: %__MODULE__{
          schema_path: String.t() | nil,
          debug: boolean() | nil,
          saxon_path: String.t() | nil,
          xslt_sheets: xslt_sheets() | nil
        }
end
