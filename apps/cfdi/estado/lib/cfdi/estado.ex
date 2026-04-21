defmodule Cfdi.Estado do
  @moduledoc """
  Consulta de estado de CFDI en el webservice del SAT.
  """

  alias Cfdi.Estado.{Soap, Types}

  @timeout_ms 30_000

  @spec consultar(Types.ConsultaParams.t()) :: {:ok, Types.ConsultaResult.t()} | {:error, String.t()}
  def consultar(%Types.ConsultaParams{} = params) do
    body = Soap.build_request(params)

    case Req.post(Soap.webservice_url(),
           body: body,
           headers: [
             {"content-type", "text/xml; charset=utf-8"},
             {"soapaction", Soap.soap_action()}
           ],
           receive_timeout: @timeout_ms
         ) do
      {:ok, %{status: 200, body: xml}} ->
        Soap.parse_response(xml)

      {:ok, %{status: status, body: body}} ->
        {:error, "El webservice del SAT retornó HTTP #{status}: #{body}"}

      {:error, %{reason: :timeout}} ->
        {:error, "Timeout: el webservice del SAT no respondió en #{div(@timeout_ms, 1000)} segundos"}

      {:error, reason} ->
        {:error, "Error de red al consultar el estado del CFDI: #{inspect(reason)}"}
    end
  end
end
