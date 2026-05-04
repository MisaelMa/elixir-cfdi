defmodule Cfdi.Transform.Types do
  @moduledoc """
  Tipos de datos del motor de cadena original.

  Espejo de [`src/types.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/transform/src/types.ts)
  del paquete `@cfdi/transform`.
  """

  @typedoc """
  Regla derivada de `<xsl:call-template name="Requerido|Opcional">` con
  `<xsl:with-param select="@AttrName"/>`. Indica que se debe extraer el
  atributo `name` del nodo actual.
  """
  @type attr_rule :: %{
          type: :attr,
          name: String.t(),
          required: boolean()
        }

  @typedoc """
  Regla de `<xsl:call-template>` cuyo `select` es una ruta a contenido
  textual (no un atributo). Equivale a `xsl:value-of`.
  """
  @type text_rule :: %{
          type: :text,
          select: String.t(),
          required: boolean()
        }

  @typedoc """
  Regla derivada de `<xsl:apply-templates>` o `<xsl:for-each>`.

  Campos:
    * `:select`        — expresión XPath simplificada (sin `./`).
    * `:for_each`      — `true` si proviene de `xsl:for-each`.
    * `:inline`        — atributos/textos inline dentro del `for-each`.
    * `:apply_templates` — si dentro hay `xsl:apply-templates` que recurra
      contra el registro de plantillas.
    * `:condition`     — `xsl:if test="..."` que envuelve la regla.
    * `:wildcard`      — `select="./*"` o `"*"`: aplica plantilla a cada
      hijo elemento.
    * `:descendant`    — `select=".//foo"`: busca en cualquier descendiente.
  """
  @type child_rule :: %{
          required(:type) => :child,
          required(:select) => String.t(),
          required(:for_each) => boolean(),
          required(:inline) => [attr_rule() | text_rule()],
          required(:apply_templates) => boolean(),
          optional(:condition) => String.t(),
          optional(:wildcard) => boolean(),
          optional(:descendant) => boolean()
        }

  @type rule :: attr_rule() | text_rule() | child_rule()

  @type parsed_template :: %{match: String.t(), rules: [rule()]}

  @type template_registry :: %{
          templates: %{optional(String.t()) => parsed_template()},
          namespaces: %{optional(String.t()) => String.t()}
        }
end
