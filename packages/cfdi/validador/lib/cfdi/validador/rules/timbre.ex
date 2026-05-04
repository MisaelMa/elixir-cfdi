defmodule Cfdi.Validador.Rules.Timbre do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :timbre_optional,
        description: "Timbre fiscal: validación extendida pendiente",
        check: fn _data -> :ok end
      }
    ]
  end
end
