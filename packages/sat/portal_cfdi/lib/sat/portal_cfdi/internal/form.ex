defmodule Sat.PortalCfdi.Internal.Form do
  @moduledoc false
  # Helpers para extraer campos hidden de formularios ASP.NET WebForms y
  # construir form-encoded payloads.

  @doc """
  Extrae todos los `<input type="hidden">` de un HTML.
  Retorna un map `name => value`.
  """
  @spec extract_hidden_inputs(String.t()) :: %{String.t() => String.t()}
  def extract_hidden_inputs(html) when is_binary(html) do
    case Floki.parse_document(html) do
      {:ok, doc} ->
        doc
        |> Floki.find(~s|input[type="hidden"]|)
        |> Enum.flat_map(fn input ->
          name = Floki.attribute(input, "name") |> List.first()
          value = Floki.attribute(input, "value") |> List.first() || ""
          if name && name != "", do: [{name, value}], else: []
        end)
        |> Map.new()

      {:error, _} ->
        %{}
    end
  end

  @doc "URL-encode de un map de form params."
  @spec encode(map()) :: String.t()
  def encode(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> "#{URI.encode_www_form(to_string(k))}=#{URI.encode_www_form(to_string(v))}" end)
    |> Enum.join("&")
  end
end
