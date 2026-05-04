defmodule Cfdi.Transform do
  @moduledoc """
  Generación de la cadena original de un CFDI a partir de las hojas XSLT del SAT.

  Port en Elixir del paquete Node `@cfdi/transform`. Los módulos espejo:

  | Node (`src/`)           | Elixir                       |
  |-------------------------|------------------------------|
  | `transform.ts`          | `Cfdi.Transform.Transform`   |
  | `xslt-parser.ts`        | `Cfdi.Transform.XsltParser`  |
  | `cadena-engine.ts`      | `Cfdi.Transform.CadenaEngine`|
  | `types.ts`              | `Cfdi.Transform.Types`       |

  ## Ejemplo

      cadena =
        Cfdi.Transform.Transform.new()
        |> Cfdi.Transform.Transform.s("comprobante.xml")
        |> Cfdi.Transform.Transform.xsl("packages/files/4.0/cadenaoriginal.xslt")
        |> Cfdi.Transform.Transform.run!()
  """

  defdelegate normalize_space(s), to: Cfdi.Transform.CadenaEngine
  defdelegate requerido(value), to: Cfdi.Transform.CadenaEngine
  defdelegate opcional(value), to: Cfdi.Transform.CadenaEngine
  defdelegate parse_xslt(path), to: Cfdi.Transform.XsltParser, as: :parse_file
  defdelegate generate_cadena_original(xml, registry), to: Cfdi.Transform.CadenaEngine
end
