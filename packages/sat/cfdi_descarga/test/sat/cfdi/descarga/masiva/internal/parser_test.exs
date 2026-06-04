defmodule Sat.Cfdi.Descarga.Masiva.Internal.ParserTest do
  use ExUnit.Case, async: true

  alias Sat.Cfdi.Descarga.Masiva.Internal.Parser

  describe "parse_autenticacion/1" do
    test "extrae token, created y expires de una respuesta tipica" do
      body = """
      <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
        <s:Header>
          <o:Security xmlns:o="...">
            <u:Timestamp xmlns:u="..." u:Id="_0">
              <u:Created>2025-01-01T00:00:00.000Z</u:Created>
              <u:Expires>2025-01-01T00:05:00.000Z</u:Expires>
            </u:Timestamp>
          </o:Security>
        </s:Header>
        <s:Body>
          <AutenticaResponse xmlns="http://DescargaMasivaTerceros.gob.mx">
            <AutenticaResult>fake.jwt.token</AutenticaResult>
          </AutenticaResponse>
        </s:Body>
      </s:Envelope>
      """

      assert {:ok, token} = Parser.parse_autenticacion(body)
      assert token.value == "fake.jwt.token"
      assert %DateTime{} = token.issued_at
      assert %DateTime{} = token.expires_at
      assert DateTime.compare(token.expires_at, token.issued_at) == :gt
    end

    test "retorna error si faltan campos" do
      assert {:error, _} = Parser.parse_autenticacion("<empty/>")
    end
  end

  describe "parse_solicitud/1" do
    test "extrae IdSolicitud, CodEstatus y Mensaje" do
      body = """
      <s:Envelope xmlns:s="...">
        <s:Body>
          <SolicitaDescargaResponse xmlns="...">
            <SolicitaDescargaResult IdSolicitud="abc-123-def" CodEstatus="5000" Mensaje="Solicitud Aceptada"/>
          </SolicitaDescargaResponse>
        </s:Body>
      </s:Envelope>
      """

      assert {:ok, result} = Parser.parse_solicitud(body)
      assert result.id_solicitud == "abc-123-def"
      assert result.cod_estatus == "5000"
      assert result.mensaje == "Solicitud Aceptada"
    end
  end

  describe "parse_verificacion/1" do
    test "mapea EstadoSolicitud a atomos y junta IdsPaquetes" do
      body = """
      <s:Envelope xmlns:s="...">
        <s:Body>
          <VerificaSolicitudDescargaResponse xmlns="...">
            <VerificaSolicitudDescargaResult EstadoSolicitud="3" CodigoEstadoSolicitud="5000" NumeroCFDIs="100" Mensaje="OK">
              <IdsPaquetes>PKG_AAA_01</IdsPaquetes>
              <IdsPaquetes>PKG_AAA_02</IdsPaquetes>
            </VerificaSolicitudDescargaResult>
          </VerificaSolicitudDescargaResponse>
        </s:Body>
      </s:Envelope>
      """

      assert {:ok, r} = Parser.parse_verificacion(body)
      assert r.estado_solicitud == :terminada
      assert r.codigo_estado_solicitud == "5000"
      assert r.numero_cfdis == 100
      assert r.ids_paquetes == ["PKG_AAA_01", "PKG_AAA_02"]
    end

    test "estado en proceso retorna :en_proceso" do
      body =
        ~s|<VerificaSolicitudDescargaResult EstadoSolicitud="2" CodigoEstadoSolicitud="5000" NumeroCFDIs="0"></VerificaSolicitudDescargaResult>|

      assert {:ok, r} = Parser.parse_verificacion(body)
      assert r.estado_solicitud == :en_proceso
    end
  end

  describe "parse_descarga/2" do
    test "decodifica base64 del Paquete" do
      original = "FAKE_ZIP_BYTES"
      b64 = Base.encode64(original)

      body = """
      <s:Envelope xmlns:s="...">
        <s:Header>
          <h:respuesta xmlns:h="...">
            <Paquete>#{b64}</Paquete>
          </h:respuesta>
        </s:Header>
      </s:Envelope>
      """

      assert {:ok, paquete} = Parser.parse_descarga(body, "PKG-1")
      assert paquete.id == "PKG-1"
      assert paquete.content == original
      assert paquete.size == byte_size(original)
    end
  end

  describe "detect_fault/1" do
    test "no detecta fault en respuesta normal" do
      assert Parser.detect_fault("<ok/>") == :ok
    end

    test "detecta s:Fault y devuelve error" do
      body =
        ~s|<s:Envelope xmlns:s="..."><s:Body><s:Fault><faultcode>Server</faultcode><faultstring>boom</faultstring></s:Fault></s:Body></s:Envelope>|

      assert {:error, {:soap_fault, "Server", "boom"}} = Parser.detect_fault(body)
    end
  end
end
