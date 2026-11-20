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

  @doc """
  Ruta del `cadenaoriginal_4_0.xslt` oficial del SAT incluido en `priv/`, ya
  LOCALIZADO (complementos descargados y `href` relativos). Se regenera con
  `mix cfdi.xslt.update`.

      Cfdi.Transform.Transform.new()
      |> Cfdi.Transform.Transform.xsl(Cfdi.Transform.bundled_xslt())
  """
  @spec bundled_xslt() :: String.t()
  def bundled_xslt do
    Path.join(:code.priv_dir(:cfdi_transform), "xslt/4.0/cadenaoriginal_4_0.xslt")
  end

  defdelegate normalize_space(s), to: Cfdi.Transform.CadenaEngine
  defdelegate requerido(value), to: Cfdi.Transform.CadenaEngine
  defdelegate opcional(value), to: Cfdi.Transform.CadenaEngine
  defdelegate parse_xslt(path), to: Cfdi.Transform.XsltParser, as: :parse_file
  defdelegate generate_cadena_original(xml, registry), to: Cfdi.Transform.CadenaEngine
end
