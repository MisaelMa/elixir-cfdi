defmodule Cfdi.Transform.Types do
  @moduledoc false

  @type attr_rule :: %{
          type: :attr,
          name: String.t(),
          required: boolean()
        }

  @type child_rule :: %{
          type: :child,
          select: String.t(),
          for_each: boolean(),
          inline: list(),
          apply_templates: boolean(),
          descendant: boolean()
        }

  @type rule :: attr_rule() | child_rule()

  @type parsed_template :: %{
          match: String.t(),
          rules: [rule()]
        }

  @type template_registry :: %{
          templates: %{optional(String.t()) => parsed_template()},
          namespaces: %{optional(String.t()) => String.t()}
        }
end
