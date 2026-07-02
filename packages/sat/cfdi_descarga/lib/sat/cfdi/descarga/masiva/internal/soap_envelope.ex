defmodule Sat.Cfdi.Descarga.Masiva.Internal.SoapEnvelope do
  @moduledoc false
  # Construye los sobres SOAP firmados para los 4 servicios del WS de
  # Descarga Masiva del SAT. Los sobres se construyen ya en forma
  # canonica (atributos ordenados, sin whitespace) para que el digest y
  # la firma coincidan sin necesidad de canonicalizar despues.

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.Internal.{X509Info, XmlDsig}
  alias Sat.Cfdi.Descarga.Masiva.Types.SolicitudParams

  @ns_soap "http://schemas.xmlsoap.org/soap/envelope/"
  @ns_wsse "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  @ns_wsu "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
  @ns_des "http://DescargaMasivaTerceros.sat.gob.mx"
  @ns_terceros "http://DescargaMasivaTerceros.gob.mx"

  @doc """
  Sobre SOAP para `Autentica`. Firma un `wsu:Timestamp` con FIEL.

  Opciones:
    * `:now` — DateTime para el `Created` (default `DateTime.utc_now/0`)
    * `:lifetime_seconds` — duracion de la ventana (default 300s)
  """
  @spec build_autenticacion(Credential.t(), keyword()) :: String.t()
  def build_autenticacion(%Credential{} = cred, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    lifetime = Keyword.get(opts, :lifetime_seconds, 300)
    created = format_datetime(now)
    expires = format_datetime(DateTime.add(now, lifetime, :second))
    timestamp_id = "_0"
    token_id = "BinarySecurityToken-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}-4"

    timestamp =
      ~s|<u:Timestamp xmlns:u="#{@ns_wsu}" u:Id="#{timestamp_id}">| <>
        ~s|<u:Created>#{created}</u:Created>| <>
        ~s|<u:Expires>#{expires}</u:Expires>| <>
        ~s|</u:Timestamp>|

    digest = XmlDsig.sha1_base64(timestamp)
    signed_info = XmlDsig.build_signed_info(timestamp_id, digest)
    signature_value = XmlDsig.sign_signed_info(signed_info, cred)
    key_info = XmlDsig.build_key_info_str(token_id)
    signature = XmlDsig.build_signature(signed_info, signature_value, key_info)
    bst = XmlDsig.build_binary_security_token(cred, token_id)

    ~s|<?xml version="1.0" encoding="UTF-8"?>| <>
      ~s|<s:Envelope xmlns:s="#{@ns_soap}" xmlns:u="#{@ns_wsu}">| <>
      ~s|<s:Header>| <>
      ~s|<o:Security xmlns:o="#{@ns_wsse}" s:mustUnderstand="1">| <>
      timestamp <>
      bst <>
      signature <>
      ~s|</o:Security>| <>
      ~s|</s:Header>| <>
      ~s|<s:Body>| <>
      ~s|<Autentica xmlns="#{@ns_terceros}"/>| <>
      ~s|</s:Body>| <>
      ~s|</s:Envelope>|
  end

  @doc """
  Sobre SOAP para `SolicitaDescargaEmitidos`, `SolicitaDescargaRecibidos` o
  `SolicitaDescargaFolio`. Firma el nodo `solicitud` con FIEL.

  Referencia oficial: `docs/sat/01-solicitud.pdf` §5 (SolicitaDescarga).

  ## Parametros

    * `cred` — `Sat.Certificados.Credential` (FIEL) para firmar.
    * `params` — `SolicitudParams`. Campos que se leen y a que atributo del
      nodo `<des:solicitud>` mapean:

      | Campo `SolicitudParams` | Atributo XML       | Notas |
      |-------------------------|--------------------|-------|
      | `:fecha_inicial`        | `FechaInicial`     | `DateTime`/string ISO sin `Z`. Omitido en consulta por folio. |
      | `:fecha_final`          | `FechaFinal`       | idem. |
      | `:rfc_emisor`           | `RfcEmisor`        | En `:recibidos` queda como filtro. |
      | `:rfc_receptor`         | `RfcReceptor` / `<des:RfcReceptores>` | En `:recibidos` = solicitante. Máx 5 receptores. |
      | `:rfc_solicitante`      | `RfcSolicitante`   | Default: RFC del certificado. |
      | `:rfc_a_cuenta_terceros`| `RfcACuentaTerceros` | Opcional. |
      | `:tipo_solicitud`       | `TipoSolicitud`    | `:emitidos`/`:recibidos`/`:folio`/`:cfdi` → `"CFDI"`; `:metadata` → `"Metadata"`. |
      | `:tipo_comprobante`     | `TipoComprobante`  | `:i`/`:e`/`:t`/`:n`/`:p` → mayúsculas; `:null` → `"Null"`. |
      | `:estado_comprobante`   | `EstadoComprobante`| `:vigente` → `"Vigente"`, `:cancelado` → `"Cancelado"`, `:todos` → `"Todos"`, `nil` → omitido. Para CFDI recibidos usa `:vigente` (el SAT no entrega XML cancelados). |
      | `:complemento`          | `Complemento`      | Opcional (ver lista en la doc). |
      | `:uuid`                 | `Folio`            | Consulta por folio; en ese caso NO se declaran fechas ni RFCs. |

    * `token` — token Bearer (viaja en el header HTTP `Authorization`, no en el SOAP).
    * `operation` — nombre de la operacion sin prefijo, p. ej. `"SolicitaDescargaEmitidos"`.

  Los atributos se emiten en ORDEN ALFABÉTICO (Complemento, EstadoComprobante,
  FechaInicial, FechaFinal, Folio, RfcACuentaTerceros, RfcEmisor, RfcReceptor,
  RfcSolicitante, TipoComprobante, TipoSolicitud). El SAT lo exige para poder
  validar la firma sobre la forma canónica del nodo. Los atributos `nil`/`""`
  se omiten.
  """
  @spec build_solicitud(Credential.t(), SolicitudParams.t(), String.t(), String.t()) :: String.t()
  def build_solicitud(
        %Credential{} = cred,
        %SolicitudParams{} = params,
        token,
        operation \\ "SolicitaDescargaEmitidos"
      )
      when is_binary(token) and is_binary(operation) do
    solicitud_attrs = solicitud_attributes(cred, params)

    # Nodo a firmar en forma canonica para que el digest sea reproducible.
    solicitud_open = "<des:solicitud" <> solicitud_attrs <> ">"

    rfc_receptores = rfc_receptores_xml(params)
    solicitud_node = solicitud_open <> rfc_receptores <> "</des:solicitud>"

    digest = XmlDsig.sha1_base64(solicitud_node)
    signed_info = XmlDsig.build_signed_info("", digest)
    signature_value = XmlDsig.sign_signed_info(signed_info, cred)
    key_info = XmlDsig.build_key_info_x509(cred)
    signature = XmlDsig.build_signature(signed_info, signature_value, key_info)

    body =
      ~s|<des:#{operation} xmlns:des="#{@ns_des}" xmlns:xd="http://www.w3.org/2000/09/xmldsig#">| <>
        solicitud_open <>
        rfc_receptores <>
        signature <>
        "</des:solicitud>" <>
        "</des:#{operation}>"

    wrap_envelope_with_token(body, token)
  end

  @doc """
  Sobre SOAP para `VerificaSolicitudDescarga`.

  Referencia oficial: `docs/sat/02-verificacion.pdf` §5.

  Firma el nodo `<des:solicitud IdSolicitud RfcSolicitante>`.

  ## Parametros
    * `cred` — FIEL para firmar.
    * `rfc_solicitante` — RFC del que generó la solicitud original.
    * `id_solicitud` — `IdSolicitud` devuelto por `SolicitaDescarga`.
    * `token` — token Bearer (header HTTP `Authorization`).
  """
  @spec build_verificacion(Credential.t(), String.t(), String.t(), String.t()) :: String.t()
  def build_verificacion(
        %Credential{} = cred,
        rfc_solicitante,
        id_solicitud,
        token
      )
      when is_binary(rfc_solicitante) and is_binary(id_solicitud) and is_binary(token) do
    solicitud_attrs =
      ~s| IdSolicitud="#{id_solicitud}" RfcSolicitante="#{escape(rfc_solicitante)}"|

    solicitud_open = "<des:solicitud" <> solicitud_attrs <> ">"
    solicitud_node = solicitud_open <> "</des:solicitud>"

    digest = XmlDsig.sha1_base64(solicitud_node)
    signed_info = XmlDsig.build_signed_info("", digest)
    signature_value = XmlDsig.sign_signed_info(signed_info, cred)
    key_info = XmlDsig.build_key_info_x509(cred)
    signature = XmlDsig.build_signature(signed_info, signature_value, key_info)

    body =
      ~s|<des:VerificaSolicitudDescarga xmlns:des="#{@ns_des}" xmlns:xd="http://www.w3.org/2000/09/xmldsig#">| <>
        solicitud_open <>
        signature <>
        "</des:solicitud>" <>
        "</des:VerificaSolicitudDescarga>"

    wrap_envelope_with_token(body, token)
  end

  @doc """
  Sobre SOAP para `DescargaMasivaSolicitudes` (operación
  `PeticionDescargaMasivaTercerosEntrada`). Firma el nodo `peticionDescarga`.

  Referencia oficial: `docs/sat/03-descarga.pdf`.

  ## Parametros
    * `cred` — FIEL para firmar.
    * `rfc_solicitante` — RFC del solicitante (debe coincidir con la solicitud).
    * `id_paquete` — `IdPaquete` devuelto por `VerificaSolicitudDescarga`.
    * `token` — token Bearer (header HTTP `Authorization`).
  """
  @spec build_descarga(Credential.t(), String.t(), String.t(), String.t()) :: String.t()
  def build_descarga(
        %Credential{} = cred,
        rfc_solicitante,
        id_paquete,
        token
      )
      when is_binary(rfc_solicitante) and is_binary(id_paquete) and is_binary(token) do
    peticion_attrs =
      ~s| IdPaquete="#{id_paquete}" RfcSolicitante="#{escape(rfc_solicitante)}"|

    peticion_open = "<des:peticionDescarga" <> peticion_attrs <> ">"
    peticion_node = peticion_open <> "</des:peticionDescarga>"

    digest = XmlDsig.sha1_base64(peticion_node)
    signed_info = XmlDsig.build_signed_info("", digest)
    signature_value = XmlDsig.sign_signed_info(signed_info, cred)
    key_info = XmlDsig.build_key_info_x509(cred)
    signature = XmlDsig.build_signature(signed_info, signature_value, key_info)

    body =
      ~s|<des:PeticionDescargaMasivaTercerosEntrada xmlns:des="#{@ns_des}" xmlns:xd="http://www.w3.org/2000/09/xmldsig#">| <>
        peticion_open <>
        signature <>
        "</des:peticionDescarga>" <>
        "</des:PeticionDescargaMasivaTercerosEntrada>"

    wrap_envelope_with_token(body, token)
  end

  # Solicitud / Verificación / Descarga: el sobre lleva el Header VACÍO. La firma
  # XML-DSig va DENTRO del body (nodo `solicitud`/`peticionDescarga`) y el token
  # viaja en el header HTTP `Authorization: WRAP access_token="..."` (ver Http).
  #
  # NO se incluye `<wsse:Security>`: estos endpoints usan BasicHttpBinding y
  # devuelven un fault `MustUnderstand` si reciben ese header con
  # `mustUnderstand="1"`. (Solo la Autenticación firma en el Security header.)
  defp wrap_envelope_with_token(body, _token) do
    ~s|<?xml version="1.0" encoding="UTF-8"?>| <>
      ~s|<s:Envelope xmlns:s="#{@ns_soap}">| <>
      ~s|<s:Header/>| <>
      ~s|<s:Body>| <>
      body <>
      ~s|</s:Body>| <>
      ~s|</s:Envelope>|
  end

  defp solicitud_attributes(%Credential{} = cred, %SolicitudParams{} = p) do
    rfc_solicitante = p.rfc_solicitante || Credential.rfc(cred)

    # El SAT es simétrico invertido:
    #   emitidos → atributo `RfcEmisor` = solicitante (RfcReceptor sería filtro)
    #   recibidos → atributo `RfcReceptor` = solicitante (RfcEmisor sería filtro)
    {rfc_emisor, rfc_receptor} =
      if p.tipo_solicitud == :recibidos do
        {p.rfc_emisor, rfc_solicitante}
      else
        {p.rfc_emisor || rfc_solicitante, nil}
      end

    # Orden exacto (alfabético) requerido por el SAT para validacion de firma
    # (C14N): ... RfcACuentaTerceros, RfcEmisor, RfcReceptor, RfcSolicitante ...
    [
      {"Complemento", complemento_string(p.complemento)},
      {"EstadoComprobante", estado_comprobante_string(p.estado_comprobante)},
      {"FechaFinal", to_datetime_string(p.fecha_final)},
      {"FechaInicial", to_datetime_string(p.fecha_inicial)},
      {"Folio", p.uuid},
      {"RfcACuentaTerceros", p.rfc_a_cuenta_terceros},
      {"RfcEmisor", rfc_emisor},
      {"RfcReceptor", rfc_receptor},
      {"RfcSolicitante", rfc_solicitante},
      {"TipoComprobante", tipo_comprobante_string(p.tipo_comprobante)},
      {"TipoSolicitud", tipo_solicitud_string(p.tipo_solicitud)}
    ]
    |> Enum.reject(fn {_, v} -> is_nil(v) or v == "" end)
    |> Enum.map(fn {k, v} -> ~s| #{k}="#{escape(v)}"| end)
    |> Enum.join("")
  end

  defp rfc_receptores_xml(%SolicitudParams{rfc_receptor: nil}), do: ""

  defp rfc_receptores_xml(%SolicitudParams{rfc_receptor: rfcs}) when is_list(rfcs) do
    inner =
      rfcs
      |> Enum.map(fn rfc -> ~s|<des:RfcReceptor>#{escape(rfc)}</des:RfcReceptor>| end)
      |> Enum.join("")

    "<des:RfcReceptores>" <> inner <> "</des:RfcReceptores>"
  end

  defp rfc_receptores_xml(%SolicitudParams{rfc_receptor: rfc}) when is_binary(rfc) do
    "<des:RfcReceptores><des:RfcReceptor>#{escape(rfc)}</des:RfcReceptor></des:RfcReceptores>"
  end

  # En consulta por Folio (UUID) las fechas no se declaran (van nil); el
  # atributo se omite despues en el Enum.reject de solicitud_attributes.
  defp to_datetime_string(nil), do: nil

  defp to_datetime_string(%DateTime{} = dt) do
    dt
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
    |> String.replace("Z", "")
  end

  defp to_datetime_string(s) when is_binary(s), do: s

  defp format_datetime(%DateTime{} = dt) do
    dt
    |> DateTime.truncate(:millisecond)
    |> DateTime.to_iso8601()
  end

  defp complemento_string(nil), do: nil
  defp complemento_string(s) when is_binary(s), do: s

  defp tipo_solicitud_string(:emitidos), do: "CFDI"
  defp tipo_solicitud_string(:recibidos), do: "CFDI"
  defp tipo_solicitud_string(:folio), do: "CFDI"
  defp tipo_solicitud_string(:metadata), do: "Metadata"
  defp tipo_solicitud_string(:cfdi), do: "CFDI"
  defp tipo_solicitud_string(other) when is_binary(other), do: other

  defp tipo_comprobante_string(nil), do: nil
  defp tipo_comprobante_string(:null), do: "Null"
  defp tipo_comprobante_string(atom) when atom in [:i, :e, :t, :n, :p],
    do: atom |> Atom.to_string() |> String.upcase()
  defp tipo_comprobante_string(other) when is_binary(other), do: other

  # v1.5: el SAT espera el TEXTO del estado, no el numerico. Enviar "1"/"0"
  # hace que el SAT no lo reconozca y asuma "Todos" → error 301 "No se permite
  # la descarga de xml que se encuentren cancelados". Valores per fixture oficial
  # de phpcfdi/sat-ws-descarga-masiva: "Vigente", "Cancelado", "Todos".
  defp estado_comprobante_string(nil), do: nil
  defp estado_comprobante_string(:todos), do: "Todos"
  defp estado_comprobante_string(:cancelado), do: "Cancelado"
  defp estado_comprobante_string(:vigente), do: "Vigente"
  defp estado_comprobante_string(other) when is_binary(other), do: other

  defp escape(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  defp escape(other), do: to_string(other)

  _ = X509Info
end
