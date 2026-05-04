defmodule Cfdi.Validador.Rules.Receptor do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationIssue
  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :receptor_exists,
        description: "Debe existir nodo Receptor",
        check: fn %Cfdi.Validador.Types.CfdiData{document: {_, _, children}} ->
          if find_receptor(children) do
            :ok
          else
            {:error,
             %ValidationIssue{
               message: "Falta el elemento Receptor",
               path: "/Comprobante/Receptor"
             }}
          end
        end
      }
    ]
  end

  defp find_receptor(children) do
    Enum.any?(children, fn
      {:element, name, _, _} -> local_name(name) == "Receptor"
      _ -> false
    end)
  end

  defp local_name(tag) do
    case String.split(tag, ":", parts: 2) do
      [_p, l] -> l
      [l] -> l
    end
  end
end
