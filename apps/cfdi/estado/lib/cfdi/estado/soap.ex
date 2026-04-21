defmodule Cfdi.Estado.Soap do
  @moduledoc """
  SOAP request builder and response parser for CFDI status consultation.
  """

  alias Cfdi.Estado.Types.{ConsultaParams, ConsultaResult}

  @webservice_url "https://consultaqr.facturaelectronica.sat.gob.mx/ConsultaCFDIService.svc"
  @soap_action "http://tempuri.org/IConsultaCFDIService/Consulta"

  def webservice_url, do: @webservice_url
  def soap_action, do: @soap_action

  @spec format_total(String.t()) :: String.t()
  def format_total(total) do
    trimmed = String.trim(total)

    unless Regex.match?(~r/^\d+(\.\d+)?$/, trimmed) do
      raise "Total invalido: '#{total}'"
    end

    [integer | rest] = String.split(trimmed, ".")
    decimal = List.first(rest) || ""
    padded_integer = String.pad_leading(integer, 10, "0")
    padded_decimal = decimal |> String.pad_trailing(6, "0") |> String.slice(0, 6)
    "#{padded_integer}.#{padded_decimal}"
  end

  @spec build_request(ConsultaParams.t()) :: String.t()
  def build_request(%ConsultaParams{} = params) do
    total_formateado = format_total(params.total)
    expresion = "?re=#{params.rfc_emisor}&rr=#{params.rfc_receptor}&tt=#{total_formateado}&id=#{params.uuid}"

    """
    <?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
      <soap:Header/>
      <soap:Body>
        <tem:Consulta>
          <tem:expresionImpresa><![CDATA[#{expresion}]]></tem:expresionImpresa>
        </tem:Consulta>
      </soap:Body>
    </soap:Envelope>\
    """
    |> String.trim_leading()
  end

  @spec parse_response(String.t()) :: {:ok, ConsultaResult.t()} | {:error, String.t()}
  def parse_response(xml) do
    if String.contains?(xml, "<s:Fault>") || String.contains?(xml, "<soap:Fault>") do
      fault_string = extract_tag(xml, "faultstring")
      {:error, "SOAP Fault: #{fault_string || "Error desconocido del servicio"}"}
    else
      estado = extract_tag(xml, "Estado")

      {:ok,
       %ConsultaResult{
         codigo_estatus: extract_tag(xml, "CodigoEstatus"),
         es_cancelable: extract_tag(xml, "EsCancelable"),
         estado: estado,
         estatus_cancelacion: extract_tag(xml, "EstatusCancelacion"),
         validacion_efos: extract_tag(xml, "ValidacionEFOS"),
         activo: estado == "Vigente",
         cancelado: estado == "Cancelado",
         no_encontrado: estado == "No Encontrado"
       }}
    end
  end

  defp extract_tag(xml, local_name) do
    pattern = ~r/<(?:[a-zA-Z0-9_]+:)?#{local_name}[^>]*>([\s\S]*?)<\/(?:[a-zA-Z0-9_]+:)?#{local_name}>/i

    case Regex.run(pattern, xml) do
      [_, content] -> String.trim(content)
      _ -> ""
    end
  end
end
