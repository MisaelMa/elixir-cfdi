defmodule Sat.Catalogos.Codegen.AtomNamer do
  @moduledoc """
  Converts Spanish description strings into snake_case atoms.

  Strips diacritical marks via NFD normalization, removes non-ASCII characters,
  replaces non-alphanumeric sequences with underscores, and downcases the result.
  """

  @doc """
  Converts a Spanish description string into a snake_case atom.

  ## Examples

      iex> Sat.Catalogos.Codegen.AtomNamer.normalize("Efectivo")
      :efectivo

      iex> Sat.Catalogos.Codegen.AtomNamer.normalize("Cheque nominativo")
      :cheque_nominativo

      iex> Sat.Catalogos.Codegen.AtomNamer.normalize("Régimen Simplificado de Confianza")
      :regimen_simplificado_de_confianza

  """
  @spec normalize(String.t()) :: atom()
  def normalize(description) when is_binary(description) do
    description
    |> strip_diacritics()
    |> replace_non_alnum()
    |> String.downcase()
    |> String.trim("_")
    |> String.to_atom()
  end

  @doc """
  Returns true if the string is a valid Elixir atom identifier (ASCII letters, digits, underscores).
  """
  @spec valid_identifier?(String.t()) :: boolean()
  def valid_identifier?(str) when is_binary(str) do
    Regex.match?(~r/^[a-z][a-z0-9_]*$/, str)
  end

  # Strip diacritical marks: NFD decomposition → remove combining characters
  defp strip_diacritics(str) do
    str
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/[^\x00-\x7F]/u, "")
  end

  # Replace any run of non-alphanumeric characters with a single underscore
  defp replace_non_alnum(str) do
    Regex.replace(~r/[^a-zA-Z0-9]+/, str, "_")
  end
end
