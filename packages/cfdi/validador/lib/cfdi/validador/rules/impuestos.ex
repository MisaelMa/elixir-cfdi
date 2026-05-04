defmodule Cfdi.Validador.Rules.Impuestos do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :impuestos_optional,
        description: "Nodo Impuestos es opcional; regla de marcador de posición",
        check: fn _data -> :ok end
      }
    ]
  end
end
