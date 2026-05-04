defmodule Sat.Banxico.Client do
  @moduledoc """
  HTTP client for Banxico SIE API to fetch exchange rates.
  """

  alias Sat.Banxico.Types
  alias Sat.Banxico.Types.{TipoCambio, Config}

  @base_url "https://www.banxico.org.mx/SieAPIRest/service/v1/series"

  @spec new(Config.t()) :: Config.t()
  def new(%Config{api_token: token} = config) when is_binary(token) and token != "" do
    config
  end

  @spec obtener_tipo_cambio(Config.t(), Types.moneda(), String.t() | nil) ::
          {:ok, TipoCambio.t()} | {:error, String.t()}
  def obtener_tipo_cambio(config, moneda, fecha \\ nil) do
    with {:ok, serie} <- Types.resolve_serie(moneda) do
      f = fecha_consulta(fecha)
      url = build_url(config, "#{serie}/datos/#{f}/#{f}")
      fetch_and_parse(config, url, moneda)
    end
  end

  @spec obtener_tipo_cambio_actual(Config.t(), Types.moneda()) ::
          {:ok, TipoCambio.t()} | {:error, String.t()}
  def obtener_tipo_cambio_actual(config, moneda) do
    with {:ok, serie} <- Types.resolve_serie(moneda) do
      url = build_url(config, "#{serie}/datos/oportuno")
      fetch_and_parse(config, url, moneda)
    end
  end

  defp fetch_and_parse(config, url, moneda) do
    case Req.get(url,
           headers: [{"accept", "application/json"}],
           receive_timeout: config.timeout
         ) do
      {:ok, %{status: 200, body: body}} ->
        parse_tipo_cambio(moneda, body)

      {:ok, %{status: status}} ->
        {:error, "Banxico HTTP #{status}"}

      {:error, reason} ->
        {:error, "Error de red al consultar Banxico: #{inspect(reason)}"}
    end
  end

  defp parse_tipo_cambio(moneda, body) do
    series = get_in(body, ["bmx", "series"]) || []
    serie = List.first(series) || %{}
    datos = Map.get(serie, "datos", [])
    ultimo = List.last(datos)

    cond do
      is_nil(ultimo) ->
        {:error, "Respuesta Banxico sin observaciones en la serie solicitada"}

      Map.get(ultimo, "dato") in [nil, "", "N/E"] ->
        {:error, "Banxico reportó dato no disponible (N/E) para la fecha o serie"}

      true ->
        dato_raw = Map.get(ultimo, "dato", "")
        cleaned = String.replace(dato_raw, ",", "")

        case Float.parse(cleaned) do
          {tc, _} ->
            {:ok,
             %TipoCambio{
               fecha: Map.get(ultimo, "fecha", ""),
               moneda: Atom.to_string(moneda),
               tipo_cambio: tc
             }}

          :error ->
            {:error, "Valor de tipo de cambio inválido: #{dato_raw}"}
        end
    end
  end

  defp fecha_consulta(nil), do: Date.utc_today() |> Date.to_iso8601()
  defp fecha_consulta(""), do: fecha_consulta(nil)
  defp fecha_consulta(fecha), do: String.trim(fecha)

  defp build_url(config, path_suffix) do
    uri = URI.parse("#{@base_url}/#{path_suffix}")
    query = URI.encode_query(%{"token" => config.api_token})
    URI.to_string(%{uri | query: query})
  end
end
