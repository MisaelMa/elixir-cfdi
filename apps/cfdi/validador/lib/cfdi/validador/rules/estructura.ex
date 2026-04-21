defmodule Cfdi.Validador.Rules.Estructura do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationIssue
  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :comprobante_root,
        description: "El elemento raíz debe corresponder a Comprobante",
        check: fn %Cfdi.Validador.Types.CfdiData{document: {name, _, _}} ->
          n = local_name(name)

          if n == "Comprobante" do
            :ok
          else
            {:error,
             %ValidationIssue{
               message: "Se esperaba cfdi:Comprobante como raíz",
               path: "/"
             }}
          end
        end
      }
    ]
  end

  defp local_name(tag) do
    case String.split(tag, ":", parts: 2) do
      [_p, l] -> l
      [l] -> l
    end
  end
end
