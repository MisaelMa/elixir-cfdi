defmodule Cfdi.Validador.Rules.Emisor do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationIssue
  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :emisor_exists,
        description: "Debe existir nodo Emisor",
        check: fn %Cfdi.Validador.Types.CfdiData{document: {_, _, children}} ->
          if find_emisor(children) do
            :ok
          else
            {:error,
             %ValidationIssue{
               message: "Falta el elemento Emisor",
               path: "/Comprobante/Emisor"
             }}
          end
        end
      }
    ]
  end

  defp find_emisor(children) do
    Enum.any?(children, fn
      {:element, name, _, _} -> local_name(name) == "Emisor"
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
