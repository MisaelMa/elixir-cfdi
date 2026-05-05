defmodule Cfdi.Xml.Comprobante do
  @moduledoc """
  Acceso de alto nivel al CFDI parseado, espejo de la clase `CFDI` del
  paquete TypeScript.

  Tras `Cfdi.Xml.Comprobante.new/2` el árbol completo queda accesible vía
  `cfdi.comprobante`, que es el mapa raíz del CFDI. Desde ahí se llega a
  todo:

      cfdi = Cfdi.Xml.Comprobante.new(xml)
      cfdi.comprobante["Emisor"]      #=> %{"Nombre" => ..., "Rfc" => ...}
      cfdi.comprobante["Receptor"]    #=> %{...}
      cfdi.comprobante["Conceptos"]   #=> [%{...}, %{...}]
      cfdi.comprobante["Impuestos"]   #=> %{...}
      cfdi.comprobante["Complemento"] #=> %{...}

  Por defecto las claves son cadenas. Pasa `keys: :atom` para que todo el
  árbol use átomos:

      cfdi = Cfdi.Xml.Comprobante.new(xml, keys: :atom)
      cfdi.comprobante[:Emisor][:Nombre]
  """

  alias Cfdi.Xml.Parser

  defstruct [:json, :comprobante, keys: :string]

  @type t :: %__MODULE__{
          json: map(),
          comprobante: map() | nil,
          keys: :string | :atom
        }

  @spec new(String.t(), Parser.opts()) :: t()
  def new(xml, opts \\ []) do
    keys = Keyword.get(opts, :keys, :string)
    json = Parser.parse(xml, opts)

    %__MODULE__{json: json, comprobante: root_value(json), keys: keys}
  end

  defp root_value(json) when is_map(json) do
    case Map.values(json) do
      [single] -> single
      _ -> nil
    end
  end

  defp root_value(_), do: nil
end
