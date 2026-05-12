defmodule Sat.WsDescargaMasiva.Internal.Parser do
  @moduledoc false
  # Parsers de respuestas SOAP del WS de Descarga Masiva.

  alias Sat.WsDescargaMasiva.Types.{
    Paquete,
    SolicitudResult,
    Token,
    VerificacionResult
  }

  @doc """
  Parsea la respuesta de `Autentica`. Extrae el token, `Created` y `Expires`
  del Timestamp incluido en el header.
  """
  @spec parse_autenticacion(binary()) :: {:ok, Token.t()} | {:error, term()}
  def parse_autenticacion(body) when is_binary(body) do
    with {:ok, token_value} <- extract_text(body, "AutenticaResult"),
         {:ok, created} <- extract_text(body, "u:Created"),
         {:ok, expires} <- extract_text(body, "u:Expires"),
         {:ok, created_dt} <- parse_iso8601(created),
         {:ok, expires_dt} <- parse_iso8601(expires) do
      {:ok,
       %Token{
         value: String.trim(token_value),
         issued_at: created_dt,
         expires_at: expires_dt
       }}
    else
      :not_found -> {:error, {:parse_error, :missing_fields, body}}
      other -> other
    end
  end

  @doc """
  Parsea la respuesta de `SolicitaDescarga`.
  """
  @spec parse_solicitud(binary()) :: {:ok, SolicitudResult.t()} | {:error, term()}
  def parse_solicitud(body) when is_binary(body) do
    cod_estatus = extract_attr(body, "SolicitaDescargaResult", "CodEstatus") || ""
    mensaje = extract_attr(body, "SolicitaDescargaResult", "Mensaje") || ""
    id_solicitud = extract_attr(body, "SolicitaDescargaResult", "IdSolicitud")

    if cod_estatus == "" and mensaje == "" do
      {:error, {:parse_error, :missing_fields, body}}
    else
      {:ok,
       %SolicitudResult{
         id_solicitud: id_solicitud,
         cod_estatus: cod_estatus,
         mensaje: mensaje
       }}
    end
  end

  @doc """
  Parsea la respuesta de `VerificaSolicitudDescarga`.
  """
  @spec parse_verificacion(binary()) :: {:ok, VerificacionResult.t()} | {:error, term()}
  def parse_verificacion(body) when is_binary(body) do
    estado_solicitud =
      extract_attr(body, "VerificaSolicitudDescargaResult", "EstadoSolicitud")
      |> parse_estado_solicitud()

    cod_estado_solicitud =
      extract_attr(body, "VerificaSolicitudDescargaResult", "CodigoEstadoSolicitud") || ""

    numero_cfdis =
      extract_attr(body, "VerificaSolicitudDescargaResult", "NumeroCFDIs")
      |> parse_int_or_zero()

    mensaje = extract_attr(body, "VerificaSolicitudDescargaResult", "Mensaje")
    id_solicitud = extract_attr(body, "VerificaSolicitudDescargaResult", "IdsPaquetes") |> nil_to_empty()

    ids_paquetes = extract_all_text(body, "IdsPaquetes")

    if cod_estado_solicitud == "" and ids_paquetes == [] do
      {:error, {:parse_error, :missing_fields, body}}
    else
      {:ok,
       %VerificacionResult{
         id_solicitud: id_solicitud,
         estado_solicitud: estado_solicitud,
         codigo_estado_solicitud: cod_estado_solicitud,
         numero_cfdis: numero_cfdis,
         mensaje: mensaje,
         ids_paquetes: ids_paquetes
       }}
    end
  end

  @doc """
  Parsea la respuesta de `DescargaMasivaSolicitudes`. El paquete viene como
  base64 dentro de `<Paquete>...</Paquete>` en el header de respuesta.
  """
  @spec parse_descarga(binary(), String.t()) :: {:ok, Paquete.t()} | {:error, term()}
  def parse_descarga(body, id_paquete) when is_binary(body) and is_binary(id_paquete) do
    with {:ok, paquete_b64} <- extract_text(body, "Paquete"),
         clean = String.trim(paquete_b64),
         {:ok, content} <- Base.decode64(clean, ignore: :whitespace) do
      {:ok,
       %Paquete{
         id: id_paquete,
         content: content,
         size: byte_size(content)
       }}
    else
      :not_found -> {:error, {:parse_error, :missing_paquete, body}}
      :error -> {:error, {:parse_error, :invalid_base64}}
      other -> other
    end
  end

  @doc """
  Detecta si la respuesta SOAP es un Fault y devuelve `{:error, {:soap_fault, ...}}`.
  """
  @spec detect_fault(binary()) :: :ok | {:error, term()}
  def detect_fault(body) when is_binary(body) do
    cond do
      String.contains?(body, "<s:Fault") or String.contains?(body, "<soap:Fault") or
          String.contains?(body, "<faultcode") ->
        faultcode = extract_text_loose(body, "faultcode") || extract_text_loose(body, "Code")
        faultstring = extract_text_loose(body, "faultstring") || extract_text_loose(body, "Reason")
        {:error, {:soap_fault, faultcode || "unknown", faultstring || "unknown"}}

      true ->
        :ok
    end
  end

  # --- Helpers de extraccion ---------------------------------------------

  # Extrae el texto entre <localname>...</localname> ignorando prefijos.
  defp extract_text(body, name) do
    case extract_text_loose(body, name) do
      nil -> :not_found
      text -> {:ok, text}
    end
  end

  defp extract_text_loose(body, name) do
    pattern = ~r/<(?:[\w-]+:)?#{Regex.escape(strip_prefix(name))}\b[^>]*>([\s\S]*?)<\/(?:[\w-]+:)?#{Regex.escape(strip_prefix(name))}>/

    case Regex.run(pattern, body) do
      [_, content] -> content
      _ -> nil
    end
  end

  defp extract_all_text(body, name) do
    pattern = ~r/<(?:[\w-]+:)?#{Regex.escape(strip_prefix(name))}\b[^>]*>([\s\S]*?)<\/(?:[\w-]+:)?#{Regex.escape(strip_prefix(name))}>/

    Regex.scan(pattern, body)
    |> Enum.map(fn [_, content] -> String.trim(content) end)
    |> Enum.reject(&(&1 == ""))
  end

  defp extract_attr(body, element_name, attr_name) do
    name = strip_prefix(element_name)

    pattern =
      ~r/<(?:[\w-]+:)?#{Regex.escape(name)}\b([^>]*)/

    case Regex.run(pattern, body) do
      [_, attrs_blob] ->
        attr_pattern = ~r/#{Regex.escape(attr_name)}="([^"]*)"/

        case Regex.run(attr_pattern, attrs_blob) do
          [_, value] -> unescape(value)
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp strip_prefix(name) do
    case String.split(name, ":", parts: 2) do
      [_prefix, local] -> local
      [local] -> local
    end
  end

  defp parse_iso8601(string) when is_binary(string) do
    s = if String.ends_with?(string, "Z"), do: string, else: string <> "Z"

    case DateTime.from_iso8601(s) do
      {:ok, dt, _} -> {:ok, dt}
      {:error, _} = e -> e
    end
  end

  defp parse_estado_solicitud("1"), do: :aceptada
  defp parse_estado_solicitud("2"), do: :en_proceso
  defp parse_estado_solicitud("3"), do: :terminada
  defp parse_estado_solicitud("4"), do: :error
  defp parse_estado_solicitud("5"), do: :rechazada
  defp parse_estado_solicitud("6"), do: :vencida
  defp parse_estado_solicitud(nil), do: 0
  defp parse_estado_solicitud(other) when is_binary(other) do
    case Integer.parse(other) do
      {n, _} -> n
      :error -> other
    end
  end

  defp parse_int_or_zero(nil), do: 0

  defp parse_int_or_zero(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp nil_to_empty(nil), do: ""
  defp nil_to_empty(s), do: s

  defp unescape(s) do
    s
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
  end
end
