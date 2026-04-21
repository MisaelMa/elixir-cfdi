defmodule Cfdi.Validador.Rules.Conceptos do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :conceptos_wrapper,
        description: "Si hay conceptos deben estar bajo Conceptos",
        check: fn %Cfdi.Validador.Types.CfdiData{document: {_, _, children}} ->
          conceptos = find_concepto_nodes(children)

          if conceptos == [] do
            :ok
          else
            if find_conceptos_wrapper(children) do
              :ok
            else
              {:error,
               %Cfdi.Validador.Types.ValidationIssue{
                 message: "Los Concepto deben agruparse en Conceptos",
                 path: "/Comprobante/Conceptos"
               }}
            end
          end
        end
      }
    ]
  end

  defp find_conceptos_wrapper(children) do
    Enum.any?(children, fn
      {:element, name, _, kids} ->
        local_name(name) == "Conceptos" and Enum.any?(kids, &concepto?/1)

      _ ->
        false
    end)
  end

  defp find_concepto_nodes(children) do
    Enum.flat_map(children, fn
      {:element, name, _, kids} ->
        cond do
          local_name(name) == "Concepto" -> [name]
          true -> find_concepto_nodes(kids)
        end

      _ ->
        []
    end)
  end

  defp concepto?({:element, name, _, _}), do: local_name(name) == "Concepto"
  defp concepto?(_), do: false

  defp local_name(tag) do
    case String.split(tag, ":", parts: 2) do
      [_p, l] -> l
      [l] -> l
    end
  end
end
