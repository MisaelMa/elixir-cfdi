defmodule Cfdi.Validador do
  @moduledoc """
  Valida XML CFDI aplicando reglas modulares (estructura, montos, timbre, etc.).
  """

  alias Cfdi.Validador.Parser
  alias Cfdi.Validador.Types.ValidationResult
  alias Cfdi.Validador.Rules.{
    Conceptos,
    Emisor,
    Estructura,
    Impuestos,
    Montos,
    Receptor,
    Sello,
    Timbre
  }

  @rules_modules [
    Estructura,
    Montos,
    Emisor,
    Receptor,
    Conceptos,
    Impuestos,
    Timbre,
    Sello
  ]

  @doc """
  Parsea el XML, ejecuta todas las reglas y devuelve un `ValidationResult`.
  """
  @spec validate(String.t()) :: {:ok, ValidationResult.t()} | {:error, term()}
  def validate(xml_string) when is_binary(xml_string) do
    with {:ok, data} <- Parser.parse(xml_string) do
      issues =
        @rules_modules
        |> Enum.flat_map(& &1.rules/0)
        |> Enum.flat_map(fn rule -> run_rule(rule, data) end)

      {:ok, %ValidationResult{valid?: issues == [], issues: issues}}
    end
  end

  defp run_rule(%{id: id, check: check}, data) do
    case check.(data) do
      :ok -> []
      {:error, issue} -> [struct(issue, rule_id: id)]
    end
  end

  @doc """
  Lee el archivo y llama a `validate/1`.
  """
  @spec validate_file(String.t()) :: {:ok, ValidationResult.t()} | {:error, term()}
  def validate_file(path) do
    case File.read(path) do
      {:ok, bin} -> validate(bin)
      {:error, _} = e -> e
    end
  end
end
