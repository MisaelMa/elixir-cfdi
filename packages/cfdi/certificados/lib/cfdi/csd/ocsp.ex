defmodule Cfdi.Csd.Ocsp do
  @moduledoc """
  Validación OCSP (Online Certificate Status Protocol — RFC 6960) contra
  el responder del SAT.

  El SAT expone `https://cfdi.sat.gob.mx/edofiel` para consultar el estado
  (`GOOD` / `REVOKED`) de un certificado en línea. Para validar un certificado
  de un contribuyente se necesitan tres certificados:

    1. **subject**: el cert del contribuyente que estás verificando.
    2. **issuer**: el cert raíz del SAT que lo emitió (AC4 o AC5).
    3. **ocsp**: el cert que firma la respuesta del responder OCSP del SAT.

  ## Ejemplo

      {:ok, subject} = Certificate.from_file("contribuyente.cer")
      {:ok, issuer}  = Certificate.from_file("AC5_SAT.cer")
      {:ok, ocsp_c}  = Certificate.from_file("ocsp.ac5_sat.cer")

      ocsp = Ocsp.new!("https://cfdi.sat.gob.mx/edofiel", issuer, subject, ocsp_c)
      {:ok, %{status: status, revocation_time: t}} = Ocsp.verify(ocsp)

  ## Parsing offline

  Las funciones `parse_response_status/1` y `parse_certificate_status/1`
  permiten inspeccionar respuestas OCSP grabadas en archivo, útiles para
  pruebas sin red.

  ## Tests

  La suite de este paquete incluye tests offline (parsing de respuestas
  OCSP grabadas en `packages/files/certificados/efirma/{revoked,tryLater}.der`)
  que corren siempre con `mix test`.

  El test que pega al endpoint en vivo del SAT está marcado con `@tag :online`
  y **no corre por default** para evitar requerir red en CI. Para ejecutarlo:

      mix test --include online

  Lo recomendado es dejarlo así: el test online es flaky (depende de la
  disponibilidad del responder del SAT) y los offline ya cubren toda la
  lógica de parseo y verificación de firma.
  """

  alias Cfdi.Csd.Certificate

  defstruct [:url, :issuer, :subject, :ocsp_cert]

  @type t :: %__MODULE__{
          url: String.t(),
          issuer: Certificate.t(),
          subject: Certificate.t(),
          ocsp_cert: Certificate.t()
        }

  @type status :: :good | :revoked | :unknown | :undefined

  @type cert_status_result :: %{
          required(:status) => status(),
          optional(:revocation_time) => DateTime.t()
        }

  @type verify_response :: %{
          required(:status) => status(),
          optional(:revocation_time) => DateTime.t(),
          required(:ocsp_request_base64) => String.t(),
          required(:ocsp_response_base64) => String.t()
        }

  @url_regex ~r/^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_+.~#?&\/=]*)$/i

  # Códigos de responseStatus (RFC 6960 §4.2.1)
  @response_status %{
    0 => :successful,
    1 => :malformed_request,
    2 => :internal_error,
    3 => :try_later,
    5 => :sig_required,
    6 => :unauthorized
  }

  @doc """
  Construye una struct `%Ocsp{}` validando la URL.
  """
  @spec new(String.t(), Certificate.t(), Certificate.t(), Certificate.t()) ::
          {:ok, t()} | {:error, :invalid_url}
  def new(url, %Certificate{} = issuer, %Certificate{} = subject, %Certificate{} = ocsp_cert) do
    if Regex.match?(@url_regex, url) do
      {:ok, %__MODULE__{url: url, issuer: issuer, subject: subject, ocsp_cert: ocsp_cert}}
    else
      {:error, :invalid_url}
    end
  end

  @doc "Como `new/4`, pero lanza `ArgumentError` si la URL es inválida."
  @spec new!(String.t(), Certificate.t(), Certificate.t(), Certificate.t()) :: t()
  def new!(url, issuer, subject, ocsp_cert) do
    case new(url, issuer, subject, ocsp_cert) do
      {:ok, ocsp} -> ocsp
      {:error, :invalid_url} -> raise ArgumentError, "Revisar la url del servicio OCSP, el formato no es de URL"
    end
  end

  @doc """
  Construye la solicitud OCSP, la POSTea al endpoint, parsea la respuesta y
  devuelve el estado del certificado del contribuyente.

  Lanza si el servicio responde error o si la firma de la respuesta no
  corresponde al `ocsp_cert`.
  """
  @spec verify(t()) :: {:ok, verify_response()} | {:error, term()}
  def verify(%__MODULE__{} = ocsp) do
    request_der = build_request_der(ocsp)

    with {:ok, response_der} <- post(ocsp.url, request_der),
         {:ok, response_status} <- {:ok, parse_response_status_der(response_der)},
         :successful <- response_status,
         {:ok, basic_der} <- extract_basic_response(response_der),
         true <- verify_response_signature(ocsp.ocsp_cert, basic_der),
         status <- parse_certificate_status_der(basic_der) do
      {:ok,
       Map.merge(status, %{
         ocsp_request_base64: Base.encode64(request_der),
         ocsp_response_base64: Base.encode64(response_der)
       })}
    else
      {:error, _} = err -> err
      :try_later -> {:error, :try_later}
      other -> {:error, {:ocsp_failed, other}}
    end
  end

  @doc """
  Parsea el `responseStatus` (primer campo de OCSPResponse, RFC 6960 §4.2.1)
  desde el DER. Útil para inspeccionar respuestas pre-grabadas.
  """
  @spec parse_response_status(binary()) :: status() | :try_later | :successful | atom()
  def parse_response_status(der) when is_binary(der), do: parse_response_status_der(der)

  @doc """
  Extrae `%{status, revocation_time?}` desde el DER de una `BasicOCSPResponse`.
  Útil para inspeccionar respuestas pre-grabadas.
  """
  @spec parse_certificate_status(binary()) :: cert_status_result()
  def parse_certificate_status(basic_der) when is_binary(basic_der) do
    parse_certificate_status_der(basic_der)
  end

  # --- Internals ---

  defp post(url, body) do
    :inets.start()
    :ssl.start()

    request = {String.to_charlist(url), [], ~c"application/octet-stream", body}

    case :httpc.request(:post, request, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, response}} when is_binary(response) ->
        {:ok, response}

      {:ok, {{_, 200, _}, _headers, response}} when is_list(response) ->
        {:ok, IO.iodata_to_binary(response)}

      {:ok, {{_, code, _}, _, _}} ->
        {:error, {:http_error, code}}

      {:error, reason} ->
        {:error, {:http_failed, reason}}
    end
  end

  defp parse_response_status_der(der) do
    # OCSPResponse ::= SEQUENCE { responseStatus ENUMERATED, ... }
    case Cfdi.Csd.Asn1.next(der) do
      {{_, _, 0x10}, body, _} ->
        case Cfdi.Csd.Asn1.next(body) do
          {{_, _, 0x0A}, <<v>>, _} -> Map.get(@response_status, v, :undefined)
          _ -> :undefined
        end

      _ ->
        :undefined
    end
  end

  defp extract_basic_response(der) do
    # OCSPResponse → SEQUENCE { responseStatus, responseBytes [0] EXPLICIT ResponseBytes }
    # ResponseBytes → SEQUENCE { responseType OID, response OCTET STRING }
    # response OCTET STRING contiene el DER de BasicOCSPResponse
    with {{_, _, 0x10}, body, _} <- Cfdi.Csd.Asn1.next(der),
         {{_, _, 0x0A}, _status, after_status} <- Cfdi.Csd.Asn1.next(body),
         {{_class, _form, 0x00}, ctx_body, _} <- Cfdi.Csd.Asn1.next(after_status),
         {{_, _, 0x10}, rb_body, _} <- Cfdi.Csd.Asn1.next(ctx_body),
         {{_, _, 0x06}, _oid, after_oid} <- Cfdi.Csd.Asn1.next(rb_body),
         {{_, _, 0x04}, basic_der, _} <- Cfdi.Csd.Asn1.next(after_oid) do
      {:ok, basic_der}
    else
      _ -> {:error, :no_basic_response}
    end
  end

  defp parse_certificate_status_der(basic_der) do
    # BasicOCSPResponse ::= SEQUENCE { tbsResponseData, sigAlg, signature, [0] certs OPTIONAL }
    # tbsResponseData ::= SEQUENCE { [0] version OPTIONAL, responderID, producedAt, responses, ... }
    # responses ::= SEQUENCE OF SingleResponse
    # SingleResponse ::= SEQUENCE { certID, certStatus, thisUpdate, ... }
    with {{_, _, 0x10}, body, _} <- Cfdi.Csd.Asn1.next(basic_der),
         {{_, _, 0x10}, tbs, _} <- Cfdi.Csd.Asn1.next(body),
         {:ok, single} <- find_first_single_response(tbs),
         {:ok, cert_status} <- extract_cert_status(single) do
      cert_status
    else
      _ -> %{status: :undefined}
    end
  end

  defp find_first_single_response(tbs) do
    # Recorrer hasta encontrar el SEQUENCE OF responses (que es a su vez una SEQUENCE)
    # Estrategia: ir avanzando elementos hasta encontrar SEQUENCE que contenga otra SEQUENCE
    Enum.reduce_while(walk_children(tbs), {:error, :not_found}, fn child, _acc ->
      case child do
        {{_, _, 0x10}, body, _} ->
          # ¿es responses (SEQUENCE OF SEQUENCE) ?
          case Cfdi.Csd.Asn1.next(body) do
            {{_, _, 0x10}, single_body, _} -> {:halt, {:ok, single_body}}
            _ -> {:cont, {:error, :not_found}}
          end

        _ ->
          {:cont, {:error, :not_found}}
      end
    end)
  end

  defp walk_children(<<>>), do: []

  defp walk_children(bin) do
    case Cfdi.Csd.Asn1.next(bin) do
      {tag, content, rest} -> [{tag, content, rest} | walk_children(rest)]
      _ -> []
    end
  end

  defp extract_cert_status(single_body) do
    # SingleResponse ::= SEQUENCE { certID, certStatus, thisUpdate, ... }
    with {{_, _, 0x10}, _cert_id, after_cert_id} <- Cfdi.Csd.Asn1.next(single_body),
         {tag, status_body, _} <- Cfdi.Csd.Asn1.next(after_cert_id) do
      case tag do
        # CertStatus is CHOICE: good [0] IMPLICIT NULL, revoked [1] IMPLICIT RevokedInfo, unknown [2]
        {2, _, 0} -> {:ok, %{status: :good}}
        {2, _, 1} -> {:ok, parse_revoked(status_body)}
        {2, _, 2} -> {:ok, %{status: :unknown}}
        _ -> {:ok, %{status: :undefined}}
      end
    end
  end

  defp parse_revoked(revoked_body) do
    # RevokedInfo ::= SEQUENCE { revocationTime GeneralizedTime, ... }
    case Cfdi.Csd.Asn1.next(revoked_body) do
      {{_, _, 0x18}, time_str, _} ->
        %{status: :revoked, revocation_time: parse_generalized_time(time_str)}

      _ ->
        %{status: :revoked}
    end
  end

  defp parse_generalized_time(bin) do
    s = if is_list(bin), do: List.to_string(bin), else: bin

    case s do
      <<y::binary-size(4), m::binary-size(2), d::binary-size(2), hh::binary-size(2),
        mm::binary-size(2), ss::binary-size(2), _::binary>> ->
        DateTime.new!(
          Date.new!(String.to_integer(y), String.to_integer(m), String.to_integer(d)),
          Time.new!(String.to_integer(hh), String.to_integer(mm), String.to_integer(ss)),
          "Etc/UTC"
        )

      _ ->
        nil
    end
  end

  defp verify_response_signature(%Certificate{} = ocsp_cert, basic_der) do
    # BasicOCSPResponse ::= SEQUENCE { tbsResponseData, sigAlg, signature BIT STRING, ... }
    # Recodificar tbsResponseData NO (los bytes deben ser los originales).
    with {{_, _, 0x10}, body, _} <- Cfdi.Csd.Asn1.next(basic_der),
         {tbs_total, _} <- ber_total_length_of(body),
         tbs_der <- binary_part(body, 0, tbs_total),
         after_tbs <- binary_part(body, tbs_total, byte_size(body) - tbs_total),
         {{_, _, 0x10}, sig_alg_body, after_sig_alg} <- Cfdi.Csd.Asn1.next(after_tbs),
         {{_, _, 0x06}, oid_bin, _} <- Cfdi.Csd.Asn1.next(sig_alg_body),
         {{_, _, 0x03}, sig_bits, _} <- Cfdi.Csd.Asn1.next(after_sig_alg) do
      <<_unused, sig::binary>> = sig_bits
      digest = oid_to_digest(decode_oid(oid_bin))
      pub = Certificate.public_key(ocsp_cert)
      :public_key.verify(tbs_der, digest, sig, pub)
    else
      _ -> false
    end
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  defp ber_total_length_of(<<_tag, rest::binary>>) do
    {content_len, after_len} = read_ber_length(rest)
    header = byte_size(rest) - byte_size(after_len) + 1
    {header + content_len, content_len}
  end

  defp read_ber_length(<<l, rest::binary>>) when l < 0x80, do: {l, rest}

  defp read_ber_length(<<first, rest::binary>>) when first >= 0x80 do
    n = first - 0x80
    <<len_bytes::binary-size(n), tail::binary>> = rest
    {:binary.decode_unsigned(len_bytes), tail}
  end

  defp decode_oid(bin) do
    [first | tail] = :binary.bin_to_list(bin)
    a = div(first, 40)
    b = rem(first, 40)
    rest = decode_oid_tail(tail, 0, [])
    [a, b | rest]
  end

  defp decode_oid_tail([], _acc, out), do: Enum.reverse(out)

  defp decode_oid_tail([b | rest], acc, out) do
    if Bitwise.band(b, 0x80) == 0 do
      v = Bitwise.bsl(acc, 7) + b
      decode_oid_tail(rest, 0, [v | out])
    else
      decode_oid_tail(rest, Bitwise.bsl(acc, 7) + Bitwise.band(b, 0x7F), out)
    end
  end

  # OIDs típicos de firma del SAT
  defp oid_to_digest([1, 2, 840, 113_549, 1, 1, 5]), do: :sha
  defp oid_to_digest([1, 2, 840, 113_549, 1, 1, 11]), do: :sha256
  defp oid_to_digest([1, 2, 840, 113_549, 1, 1, 12]), do: :sha384
  defp oid_to_digest([1, 2, 840, 113_549, 1, 1, 13]), do: :sha512
  defp oid_to_digest(_), do: :sha256

  # Construcción del OCSPRequest DER. Estructura mínima compatible con
  # el responder del SAT (incluye la nonce extension específica del SAT).
  defp build_request_der(%__MODULE__{subject: subject, issuer: issuer}) do
    issuer_name_der = encode_issuer_name(subject)
    issuer_name_hash = :crypto.hash(:sha, issuer_name_der)
    issuer_key_hash = :crypto.hash(:sha, extract_issuer_public_key_bits(issuer))
    serial_int = :binary.decode_unsigned(:binary.list_to_bin(:binary.bin_to_list(decode_hex(Certificate.serial_number(subject)))))

    cert_id =
      seq([
        seq([
          oid([1, 3, 14, 3, 2, 26]),
          null()
        ]),
        octet_string(issuer_name_hash),
        octet_string(issuer_key_hash),
        integer(serial_int)
      ])

    request = seq([cert_id])
    request_list = seq([request])

    nonce_ext =
      explicit_tag(2,
        seq([
          seq([
            oid([1, 3, 6, 1, 5, 5, 7, 48, 1, 2]),
            octet_string(decode_hex("041064bb982b0f6236984ec9d8c4997b6996"))
          ])
        ])
      )

    seq([seq([request_list, nonce_ext])])
  end

  defp encode_issuer_name(subject) do
    # Reusa el bloque de issuer del DER original del subject (es lo más confiable)
    der = Certificate.to_der(subject)

    with {{_, _, 0x10}, body, _} <- Cfdi.Csd.Asn1.next(der),
         {{_, _, 0x10}, tbs, _} <- Cfdi.Csd.Asn1.next(body) do
      issuer_der = nth_child(tbs, issuer_position(tbs))
      issuer_der
    else
      _ -> <<>>
    end
  end

  # Posición del campo issuer en TBSCertificate. Si hay [0] EXPLICIT version
  # (tbs_first_tag class=2,number=0), issuer está en idx 4; si no, idx 3.
  defp issuer_position(tbs) do
    case Cfdi.Csd.Asn1.next(tbs) do
      {{2, _, 0}, _, _} -> 4
      _ -> 3
    end
  end

  defp nth_child(seq_body, n), do: nth_child(seq_body, n, 0)

  defp nth_child(_bin, n, i) when i > n, do: <<>>

  defp nth_child(bin, target, target) do
    {total, _} = ber_total_length_of(bin)
    binary_part(bin, 0, total)
  end

  defp nth_child(bin, target, i) do
    {total, _} = ber_total_length_of(bin)
    rest = binary_part(bin, total, byte_size(bin) - total)
    nth_child(rest, target, i + 1)
  end

  defp extract_issuer_public_key_bits(issuer) do
    der = Certificate.to_der(issuer)

    with {{_, _, 0x10}, body, _} <- Cfdi.Csd.Asn1.next(der),
         {{_, _, 0x10}, tbs, _} <- Cfdi.Csd.Asn1.next(body) do
      spki_der = nth_child(tbs, spki_position(tbs))

      with {{_, _, 0x10}, spki_body, _} <- Cfdi.Csd.Asn1.next(spki_der),
           {{_, _, 0x10}, _alg, after_alg} <- Cfdi.Csd.Asn1.next(spki_body),
           {{_, _, 0x03}, bit_string, _} <- Cfdi.Csd.Asn1.next(after_alg) do
        # Bit string: primer byte = unused bits, resto = contenido
        <<_unused, contents::binary>> = bit_string
        contents
      else
        _ -> <<>>
      end
    else
      _ -> <<>>
    end
  end

  defp spki_position(tbs) do
    case Cfdi.Csd.Asn1.next(tbs) do
      {{2, _, 0}, _, _} -> 6
      _ -> 5
    end
  end

  defp decode_hex(<<>>), do: <<>>

  defp decode_hex(s) when is_binary(s) do
    Base.decode16!(String.upcase(s))
  end

  # --- Mini DER builder ---

  defp seq(items) when is_list(items), do: tag_lv(0x30, IO.iodata_to_binary(items))
  defp octet_string(bin), do: tag_lv(0x04, bin)
  defp null(), do: <<0x05, 0x00>>

  defp integer(0), do: <<0x02, 0x01, 0x00>>

  defp integer(n) when is_integer(n) and n > 0 do
    bytes = integer_to_min_bytes(n)
    bytes = if Bitwise.band(:binary.first(bytes), 0x80) != 0, do: <<0>> <> bytes, else: bytes
    tag_lv(0x02, bytes)
  end

  defp integer_to_min_bytes(n) do
    bin = :binary.encode_unsigned(n)
    bin
  end

  defp oid(parts) when is_list(parts) do
    [a, b | rest] = parts
    first = a * 40 + b
    encoded = [first | Enum.flat_map(rest, &encode_oid_node/1)]
    tag_lv(0x06, :binary.list_to_bin(encoded))
  end

  defp encode_oid_node(0), do: [0]

  defp encode_oid_node(n) when is_integer(n) and n > 0 do
    encode_oid_loop(n, [], 0)
  end

  defp encode_oid_loop(0, [], _), do: [0]

  defp encode_oid_loop(0, acc, _), do: acc

  defp encode_oid_loop(n, acc, depth) do
    byte = Bitwise.band(n, 0x7F)
    byte = if depth == 0, do: byte, else: Bitwise.bor(byte, 0x80)
    encode_oid_loop(Bitwise.bsr(n, 7), [byte | acc], depth + 1)
  end

  defp explicit_tag(num, content) when num <= 0x1E do
    tag = 0xA0 + num
    tag_lv(tag, content)
  end

  defp tag_lv(tag, content) do
    len = byte_size(content)

    len_enc =
      cond do
        len < 0x80 -> <<len>>
        true ->
          enc = :binary.encode_unsigned(len)
          <<0x80 + byte_size(enc), enc::binary>>
      end

    <<tag>> <> len_enc <> content
  end
end
