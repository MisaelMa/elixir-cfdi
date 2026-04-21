defmodule Cfdi.EstadoTest do
  use ExUnit.Case, async: true

  alias Cfdi.Estado.Soap

  test "format_total pads correctly" do
    assert Soap.format_total("1000.00") == "0000001000.000000"
  end

  test "build_request generates valid SOAP" do
    params = %Cfdi.Estado.Types.ConsultaParams{
      rfc_emisor: "AAA010101AAA",
      rfc_receptor: "BBB020202BBB",
      total: "1000.00",
      uuid: "12345678-1234-1234-1234-123456789012"
    }

    xml = Soap.build_request(params)
    assert xml =~ "soap:Envelope"
    assert xml =~ "AAA010101AAA"
    assert xml =~ "0000001000.000000"
  end

  test "parse_response extracts estado" do
    xml = """
    <s:Envelope>
      <s:Body>
        <ConsultaResponse>
          <a:CodigoEstatus>S - Comprobante obtenido satisfactoriamente.</a:CodigoEstatus>
          <a:EsCancelable>Cancelable sin aceptación</a:EsCancelable>
          <a:Estado>Vigente</a:Estado>
          <a:EstatusCancelacion></a:EstatusCancelacion>
          <a:ValidacionEFOS>200</a:ValidacionEFOS>
        </ConsultaResponse>
      </s:Body>
    </s:Envelope>
    """

    {:ok, result} = Soap.parse_response(xml)
    assert result.activo == true
    assert result.estado == "Vigente"
  end
end
