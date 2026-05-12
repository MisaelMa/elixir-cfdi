defmodule Sat.WsDescargaMasiva.Cliente do
  @moduledoc """
  Orquestador del flujo completo de Descarga Masiva.

  Encadena los 4 servicios (autenticacion -> solicitud -> verificacion ->
  descarga) y entrega un stream de XMLs / metadatos al consumidor, ocultando
  el ZIP por debajo.

  ## Ejemplo

      {:ok, cred} = Sat.Certificados.Credential.create("fiel.cer", "fiel.key", "pwd")

      params = %SolicitudParams{
        rfc_solicitante: "AAA010101AAA",
        fecha_inicial: ~U[2025-01-01 00:00:00Z],
        fecha_final:   ~U[2025-01-31 23:59:59Z],
        tipo_solicitud: :cfdi
      }

      Cliente.stream_xml(params, credential: cred)
      |> Stream.each(fn
        {:ok, {filename, xml}} -> IO.puts(filename)
        {:error, reason} -> IO.warn(inspect(reason))
      end)
      |> Stream.run()

  Polling y retries son configurables via opciones.
  """

  alias Sat.WsDescargaMasiva.{Autenticacion, Descarga, PackageReader, Solicitud, Verificacion}
  alias Sat.WsDescargaMasiva.Types.{SolicitudParams, Token}

  @doc """
  Ejecuta el flujo completo y devuelve un `Stream` lazy donde cada elemento
  es `{:ok, {filename, xml}}` o `{:error, reason}`.

  Opciones:
    * `:credential` (requerido) — FIEL del solicitante
    * `:poll_interval_ms` — intervalo de polling para verificacion
    * `:max_attempts` — intentos maximos de polling
    * `:timeout` — HTTP timeout
  """
  @spec stream_xml(SolicitudParams.t(), keyword()) :: Enumerable.t()
  def stream_xml(%SolicitudParams{} = params, opts) do
    Stream.resource(
      fn -> begin_pipeline(params, opts) end,
      fn state -> next_xml(state, opts) end,
      fn _state -> :ok end
    )
  end

  @doc """
  Variante sincrona que materializa todos los CFDIs en una lista.
  Solo recomendable para volumenes chicos (< 10,000).
  """
  @spec listar_xml(SolicitudParams.t(), keyword()) ::
          {:ok, [{String.t(), String.t()}]} | {:error, term()}
  def listar_xml(%SolicitudParams{} = params, opts) do
    case run_pipeline(params, opts) do
      {:ok, paquetes} ->
        xmls =
          paquetes
          |> Enum.flat_map(fn paquete ->
            case PackageReader.stream_cfdis(paquete) do
              {:ok, stream} -> Enum.to_list(stream)
              {:error, _} -> []
            end
          end)

        {:ok, xmls}

      {:error, _} = e ->
        e
    end
  end

  @doc """
  Lista metadata de todos los paquetes (cuando el `tipo_solicitud` es
  `:metadata`). Devuelve una lista de mapas.
  """
  @spec listar_metadata(SolicitudParams.t(), keyword()) ::
          {:ok, [map()]} | {:error, term()}
  def listar_metadata(%SolicitudParams{} = params, opts) do
    params = %{params | tipo_solicitud: :metadata}

    case run_pipeline(params, opts) do
      {:ok, paquetes} ->
        rows =
          paquetes
          |> Enum.flat_map(fn paquete ->
            case PackageReader.parse_metadata(paquete) do
              {:ok, list} -> list
              {:error, _} -> []
            end
          end)

        {:ok, rows}

      {:error, _} = e ->
        e
    end
  end

  # --- Streaming pipeline -------------------------------------------------

  defp begin_pipeline(params, opts) do
    case run_pipeline(params, opts) do
      {:ok, paquetes} -> {:paquetes, paquetes, []}
      {:error, reason} -> {:error_state, reason}
    end
  end

  defp next_xml({:error_state, reason} = state, _opts), do: {[{:error, reason}], state}

  defp next_xml({:paquetes, [], []}, _opts), do: {:halt, :done}

  defp next_xml({:paquetes, [paquete | rest], []}, _opts) do
    case PackageReader.stream_cfdis(paquete) do
      {:ok, stream} ->
        items = Enum.to_list(stream) |> Enum.map(&{:ok, &1})
        next_xml({:paquetes, rest, items}, [])

      {:error, reason} ->
        {[{:error, reason}], {:paquetes, rest, []}}
    end
  end

  defp next_xml({:paquetes, paquetes, [head | tail]}, _opts) do
    {[head], {:paquetes, paquetes, tail}}
  end

  # Ejecuta los 4 pasos y devuelve la lista de paquetes descargados.
  defp run_pipeline(%SolicitudParams{} = params, opts) do
    with {:ok, %Token{} = token} <- Autenticacion.autenticar(opts),
         {:ok, %{cod_estatus: cod, id_solicitud: id_sol}} when cod in ["5000", "0"] <-
           Solicitud.solicitar(token, params, opts),
         id_sol when is_binary(id_sol) and id_sol != "" <- id_sol,
         {:ok, %{ids_paquetes: ids}} <-
           Verificacion.esperar_terminada(token, id_sol, opts) do
      paquetes =
        ids
        |> Enum.map(fn id ->
          case Descarga.descargar(token, id, opts) do
            {:ok, p} -> p
            {:error, _} -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      {:ok, paquetes}
    else
      nil -> {:error, {:solicitud_sin_id, "el SAT no devolvio IdSolicitud"}}

      {:ok, %{cod_estatus: cod, mensaje: msg}} ->
        {:error, {:solicitud_rechazada, cod, msg}}

      {:error, _} = e ->
        e
    end
  end
end
