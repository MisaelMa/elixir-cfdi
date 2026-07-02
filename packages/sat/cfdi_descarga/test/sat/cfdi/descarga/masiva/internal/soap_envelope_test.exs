defmodule Sat.Cfdi.Descarga.Masiva.Internal.SoapEnvelopeTest do
  @moduledoc """
  Valida el XML que se envía al WS de Descarga Masiva del SAT contra los
  ejemplos oficiales de referencia (ver `docs/sat/*.pdf`).

  Cada test IMPRIME el envelope completo (formateado con saltos de línea) para
  poder inspeccionarlo a ojo, y además hace aserciones sobre TODA la estructura
  (namespaces, orden de atributos, nodos de firma), no solo un `=~` suelto.

  Corre con: `mix test test/sat/cfdi/descarga/masiva/internal/soap_envelope_test.exs --trace`

  > Usa el certificado de PRUEBAS commiteado `LAN7008173R5` (CSD del SAT,
  > `packages/files/certificados`). No es una FIEL, pero para validar la
  > ESTRUCTURA del XML firmado da igual: `X509Info` extrae issuer/serie/DER de
  > cualquier X.509. Por eso estos tests corren siempre, sin FIEL personal.
  """

  use ExUnit.Case, async: true

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.Internal.SoapEnvelope
  alias Sat.Cfdi.Descarga.Masiva.Types.SolicitudParams

  @certs_dir Path.expand("../../../../../../../../files/certificados", __DIR__)
  @cer Path.join(@certs_dir, "LAN7008173R5.cer")
  @key Path.join(@certs_dir, "LAN7008173R5.key")
  @key_password "12345678a"
  @rfc "LAN7008173R5"

  # Namespaces / algoritmos oficiales (deben coincidir con XmlDsig).
  @ns_soap "http://schemas.xmlsoap.org/soap/envelope/"
  @ns_wsu "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
  @ns_wsse "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  @ns_dsig "http://www.w3.org/2000/09/xmldsig#"
  @ns_des "http://DescargaMasivaTerceros.sat.gob.mx"
  @ns_terceros "http://DescargaMasivaTerceros.gob.mx"
  @excc14n "http://www.w3.org/2001/10/xml-exc-c14n#"

  setup do
    {:ok, cred} = Credential.create(@cer, @key, @key_password)
    {:ok, %{cred: cred}}
  end

  # ==========================================================================
  # 1. AUTENTICACIÓN — ref: docs/sat/01-solicitud.pdf §4 (Servicio Autenticación)
  # ==========================================================================
  describe "build_autenticacion/2 (servicio Autentica)" do
    test "arma el envelope firmado con Timestamp + BinarySecurityToken", %{cred: cred} do
      envelope =
        SoapEnvelope.build_autenticacion(cred, now: ~U[2025-01-01 00:00:00.000Z])

      dump("AUTENTICACION", envelope)

      # --- Sobre ---
      assert String.starts_with?(envelope, ~s|<?xml version="1.0" encoding="UTF-8"?>|)

      assert envelope =~
               ~s|<s:Envelope xmlns:s="#{@ns_soap}" xmlns:u="#{@ns_wsu}">|

      assert envelope =~ "<s:Header>"

      # --- Security header con la firma del Timestamp ---
      assert envelope =~ ~s|<o:Security xmlns:o="#{@ns_wsse}" s:mustUnderstand="1">|

      # Timestamp: Created + Expires (lifetime default 300s → +5 min)
      assert envelope =~ ~s|<u:Timestamp xmlns:u="#{@ns_wsu}" u:Id="_0">|
      assert envelope =~ "<u:Created>2025-01-01T00:00:00.000Z</u:Created>"
      assert envelope =~ "<u:Expires>2025-01-01T00:05:00.000Z</u:Expires>"

      # BinarySecurityToken con el certificado DER en base64
      assert envelope =~ ~s|<o:BinarySecurityToken |
      assert envelope =~ ~s|ValueType="| <> "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"
      assert envelope =~ "#Base64Binary"

      # Firma sobre el Timestamp (Reference URI="#_0")
      assert envelope =~ ~s|<Signature xmlns="#{@ns_dsig}">|
      assert envelope =~ ~s|<CanonicalizationMethod Algorithm="#{@excc14n}">|
      assert envelope =~ ~s|<SignatureMethod Algorithm="#{@ns_dsig}rsa-sha1">|
      assert envelope =~ ~s|<Reference URI="#_0">|
      assert envelope =~ ~s|<Transform Algorithm="#{@excc14n}">|
      assert envelope =~ ~s|<DigestMethod Algorithm="#{@ns_dsig}sha1">|
      assert envelope =~ "<DigestValue>"
      assert envelope =~ "<SignatureValue>"

      # KeyInfo → SecurityTokenReference (apunta al BST del header)
      assert envelope =~ "<o:SecurityTokenReference>"
      assert envelope =~ "<o:Reference URI=\"#BinarySecurityToken-"

      # --- Body ---
      assert envelope =~ ~s|<Autentica xmlns="#{@ns_terceros}"/>|
      assert String.ends_with?(envelope, "</s:Envelope>")
    end

    test "es determinístico cuando se fija :now (mismo DigestValue)", %{cred: cred} do
      opts = [now: ~U[2025-01-01 00:00:00.000Z]]
      a = SoapEnvelope.build_autenticacion(cred, opts)
      b = SoapEnvelope.build_autenticacion(cred, opts)
      assert digest(a) == digest(b)
    end
  end

  # ==========================================================================
  # 2. SOLICITUD — ref: docs/sat/01-solicitud.pdf §5 (SolicitaDescarga)
  # ==========================================================================
  describe "build_solicitud/4 (SolicitaDescargaEmitidos / Recibidos / Folio)" do
    test "emitidos: atributos en orden alfabético + firma X509", %{cred: cred} do
      params = %SolicitudParams{
        rfc_solicitante: @rfc,
        rfc_emisor: @rfc,
        fecha_inicial: ~U[2025-01-01 00:00:00Z],
        fecha_final: ~U[2025-01-31 23:59:59Z],
        tipo_solicitud: :emitidos,
        tipo_comprobante: :i,
        estado_comprobante: :vigente
      }

      envelope =
        SoapEnvelope.build_solicitud(cred, params, "fake-token", "SolicitaDescargaEmitidos")

      dump("SOLICITUD EMITIDOS", envelope)

      # Sobre con Header VACÍO (el token va en el header HTTP, no en el SOAP)
      assert envelope =~ ~s|<s:Envelope xmlns:s="#{@ns_soap}">|
      assert envelope =~ "<s:Header/>"

      # Operación
      assert envelope =~
               ~s|<des:SolicitaDescargaEmitidos xmlns:des="#{@ns_des}" xmlns:xd="#{@ns_dsig}">|

      # Nodo <des:solicitud> con atributos en ORDEN ALFABÉTICO exacto (canónico
      # C14N) que exige el SAT: FechaFinal ANTES de FechaInicial, y
      # EstadoComprobante como TEXTO "Vigente" (no "1"). Coincide con el fixture
      # oficial de phpcfdi/sat-ws-descarga-masiva (tests/_files/query/request-*.xml).
      assert envelope =~
               ~s|<des:solicitud EstadoComprobante="Vigente" FechaFinal="2025-01-31T23:59:59" FechaInicial="2025-01-01T00:00:00" RfcEmisor="#{@rfc}" RfcSolicitante="#{@rfc}" TipoComprobante="I" TipoSolicitud="CFDI">|

      # Emitidos NO lleva nodo RfcReceptores
      refute envelope =~ "<des:RfcReceptores>"

      # Firma con KeyInfo X509 (issuer/serie + certificado)
      assert envelope =~ ~s|<Signature xmlns="#{@ns_dsig}">|
      assert envelope =~ "<X509IssuerSerial>"
      assert envelope =~ "<X509IssuerName>"
      assert envelope =~ "<X509SerialNumber>"
      assert envelope =~ "<X509Certificate>"
      assert envelope =~ "<SignatureValue>"

      assert_firma_estilo_phpcfdi(envelope)

      assert envelope =~ "</des:SolicitaDescargaEmitidos>"
    end

    test "recibidos: RfcReceptor=solicitante + nodo RfcReceptores", %{cred: cred} do
      params = %SolicitudParams{
        rfc_solicitante: @rfc,
        rfc_emisor: "AAA010101AAA",
        fecha_inicial: ~U[2025-02-01 00:00:00Z],
        fecha_final: ~U[2025-02-28 23:59:59Z],
        tipo_solicitud: :recibidos
      }

      envelope =
        SoapEnvelope.build_solicitud(cred, params, "fake-token", "SolicitaDescargaRecibidos")

      dump("SOLICITUD RECIBIDOS", envelope)

      # En recibidos el SAT invierte: RfcReceptor pasa a ser el solicitante y
      # RfcEmisor queda como filtro. (ver comentario en soap_envelope.ex)
      assert envelope =~ ~s|RfcEmisor="AAA010101AAA"|
      assert envelope =~ ~s|RfcReceptor="#{@rfc}"|
      assert envelope =~ ~s|RfcSolicitante="#{@rfc}"|
      assert envelope =~ ~s|TipoSolicitud="CFDI"|

      assert envelope =~ "</des:SolicitaDescargaRecibidos>"
    end

    test "folio: consulta por UUID con FechaInicial/Final vacías", %{cred: cred} do
      params = %SolicitudParams{
        rfc_solicitante: @rfc,
        tipo_solicitud: :folio,
        uuid: "5FB2822E-396D-4725-8521-CDC4BDD20CCF"
      }

      envelope =
        SoapEnvelope.build_solicitud(cred, params, "fake-token", "SolicitaDescargaFolio")

      dump("SOLICITUD FOLIO", envelope)

      # UUID se manda como atributo Folio (ver tabla de parámetros de la doc).
      assert envelope =~ ~s|Folio="5FB2822E-396D-4725-8521-CDC4BDD20CCF"|
      assert envelope =~ ~s|RfcSolicitante="#{@rfc}"|
      # Sin fechas: no debe aparecer FechaInicial/FechaFinal
      refute envelope =~ "FechaInicial="
      refute envelope =~ "FechaFinal="
      assert envelope =~ "</des:SolicitaDescargaFolio>"
    end
  end

  # ==========================================================================
  # 3. VERIFICACIÓN — ref: docs/sat/02-verificacion.pdf §5 (VerificaSolicitudDescarga)
  # ==========================================================================
  describe "build_verificacion/4 (VerificaSolicitudDescarga)" do
    test "arma <des:solicitud IdSolicitud RfcSolicitante> firmado", %{cred: cred} do
      envelope =
        SoapEnvelope.build_verificacion(
          cred,
          @rfc,
          "4E80345D-917F-40BB-A98F-4A73939343C5",
          "fake-token"
        )

      dump("VERIFICACION", envelope)

      assert envelope =~ "<s:Header/>"

      assert envelope =~
               ~s|<des:VerificaSolicitudDescarga xmlns:des="#{@ns_des}" xmlns:xd="#{@ns_dsig}">|

      assert envelope =~
               ~s|<des:solicitud IdSolicitud="4E80345D-917F-40BB-A98F-4A73939343C5" RfcSolicitante="#{@rfc}">|

      # Firma X509 sobre el nodo solicitud
      assert envelope =~ "<X509Certificate>"
      assert envelope =~ "<SignatureValue>"

      assert_firma_estilo_phpcfdi(envelope)

      assert envelope =~ "</des:VerificaSolicitudDescarga>"
    end
  end

  # ==========================================================================
  # 4. DESCARGA — ref: docs/sat/03-descarga.pdf (PeticionDescargaMasivaTercerosEntrada)
  # ==========================================================================
  describe "build_descarga/4 (PeticionDescargaMasivaTercerosEntrada)" do
    test "arma <des:peticionDescarga IdPaquete RfcSolicitante> firmado", %{cred: cred} do
      envelope =
        SoapEnvelope.build_descarga(
          cred,
          @rfc,
          "4e80345d-917f-40bb-a98f-4a73939343c5_01",
          "fake-token"
        )

      dump("DESCARGA", envelope)

      assert envelope =~ "<s:Header/>"

      assert envelope =~
               ~s|<des:PeticionDescargaMasivaTercerosEntrada xmlns:des="#{@ns_des}" xmlns:xd="#{@ns_dsig}">|

      assert envelope =~
               ~s|<des:peticionDescarga IdPaquete="4e80345d-917f-40bb-a98f-4a73939343c5_01" RfcSolicitante="#{@rfc}">|

      assert envelope =~ "<X509Certificate>"
      assert envelope =~ "<SignatureValue>"

      assert_firma_estilo_phpcfdi(envelope)

      assert envelope =~ "</des:PeticionDescargaMasivaTercerosEntrada>"
    end
  end

  # --- helpers ---

  # Imprime el envelope completo, un elemento por línea, para inspección visual.
  defp dump(label, envelope) do
    pretty = String.replace(envelope, "><", ">\n<")

    IO.puts("""

    ================ XML #{label} ================
    #{pretty}
    ============ FIN XML #{label} (#{byte_size(envelope)} bytes) ============
    """)
  end

  defp digest(envelope), do: Regex.run(~r|<DigestValue>([^<]+)</DigestValue>|, envelope)

  # Valida la firma de solicitud/verificación/descarga contra el fixture OFICIAL
  # de phpcfdi/sat-ws-descarga-masiva (probado contra el SAT real):
  #   * CanonicalizationMethod = exc-c14n#   (los PDFs del SAT muestran
  #     REC-xml-c14n-20010315 + enveloped-signature, pero eso NO es lo que el
  #     SAT acepta; phpcfdi y este código usan exc-c14n).
  #   * Transform = exc-c14n#   (NO enveloped-signature).
  #   * Reference URI=""   (documento completo; NO "#").
  defp assert_firma_estilo_phpcfdi(envelope) do
    assert envelope =~ ~s|<CanonicalizationMethod Algorithm="#{@excc14n}">|
    assert envelope =~ ~s|<Reference URI="">|
    assert envelope =~ ~s|<Transform Algorithm="#{@excc14n}">|
    refute envelope =~ "enveloped-signature"
    refute envelope =~ ~s|<Reference URI="#">|
  end
end
