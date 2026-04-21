defmodule Cfdi.Validador.Rules.Montos do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :montos_present,
        description: "SubTotal y Total deben estar presentes cuando aplique",
        check: fn %Cfdi.Validador.Types.CfdiData{document: {_n, attrs, _}} ->
          attrs_map = Map.new(attrs)

          cond do
            Map.has_key?(attrs_map, "SubTotal") and Map.has_key?(attrs_map, "Total") ->
              :ok

            Map.has_key?(attrs_map, "SubTotal") or Map.has_key?(attrs_map, "Total") ->
              {:error,
               %Cfdi.Validador.Types.ValidationIssue{
                 message: "SubTotal y Total deben declararse juntos en el comprobante",
                 path: "/Comprobante"
               }}

            true ->
              :ok
          end
        end
      }
    ]
  end
end
