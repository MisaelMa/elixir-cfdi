defmodule Sat.Cfdi.Descarga.Masiva.Internal.Http do
  @moduledoc false

  require Logger

  @default_timeout 30_000

  @doc """
  POST a un endpoint SOAP. Headers obligatorios:
    * Content-Type: text/xml; charset=UTF-8
    * SOAPAction: <action>
    * Authorization: WRAP access_token="<token>" — solo si se pasa `:token`
  """
  @spec post_soap(String.t(), String.t(), iodata(), keyword()) ::
          {:ok, %{status: integer(), body: binary(), headers: list()}}
          | {:error, term()}
  def post_soap(url, soap_action, body, opts \\ [])
      when is_binary(url) and is_binary(soap_action) do
    headers =
      [
        {"content-type", "text/xml; charset=UTF-8"},
        {"soapaction", soap_action}
      ] ++ auth_header(opts[:token])

    timeout = opts[:timeout] || @default_timeout

    req_body = body_to_binary(body)

    # Log del REQUEST (activá con `Logger.configure(level: :debug)` en runtime).
    Logger.debug(fn ->
      "[SAT SOAP →] action=#{soap_action}\nurl=#{url}\ntoken=#{present?(opts[:token])}\n#{req_body}"
    end)

    case Req.post(url,
           body: req_body,
           headers: headers,
           receive_timeout: timeout,
           connect_options: [timeout: timeout],
           retry: false,
           decode_body: false
         ) do
      {:ok, %Req.Response{status: status, body: resp_body, headers: resp_headers}} ->
        resp = body_to_binary(resp_body)

        # Log del RESPONSE.
        Logger.debug(fn ->
          "[SAT SOAP ←] action=#{soap_action} status=#{status}\n#{resp}"
        end)

        {:ok, %{status: status, body: resp, headers: resp_headers}}

      {:error, reason} ->
        Logger.debug(fn -> "[SAT SOAP ✗] action=#{soap_action} network_error=#{inspect(reason)}" end)
        {:error, {:network_error, reason}}
    end
  rescue
    e ->
      Logger.debug(fn -> "[SAT SOAP ✗] action=#{soap_action} exception=#{inspect(e)}" end)
      {:error, {:exception, e}}
  end

  defp present?(nil), do: "no"
  defp present?(_), do: "sí"

  defp auth_header(nil), do: []

  defp auth_header(token) when is_binary(token) do
    [{"authorization", ~s|WRAP access_token="#{token}"|}]
  end

  defp body_to_binary(body) when is_binary(body), do: body
  defp body_to_binary(body) when is_list(body), do: IO.iodata_to_binary(body)
  defp body_to_binary(other), do: to_string(other)
end
