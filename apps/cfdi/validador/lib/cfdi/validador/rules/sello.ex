defmodule Cfdi.Validador.Rules.Sello do
  @moduledoc false

  alias Cfdi.Validador.Types.ValidationIssue
  alias Cfdi.Validador.Types.ValidationRule

  @spec rules() :: [ValidationRule.t()]
  def rules do
    [
      %ValidationRule{
        id: :sello_length,
        description: "Sello no vacío cuando está presente",
        check: fn %Cfdi.Validador.Types.CfdiData{document: {_n, attrs, _}} ->
          attrs_map = Map.new(attrs)

          case Map.get(attrs_map, "Sello") do
            nil ->
              :ok

            "" ->
              {:error,
               %ValidationIssue{
                 message: "Sello no debe ser cadena vacía",
                 path: "/Comprobante@Sello"
               }}

            _ ->
              :ok
          end
        end
      }
    ]
  end
end
