defmodule Sat.Certificados.Certificate do
  @moduledoc """
  Certificado X.509 (.cer) del SAT en formato DER con parseo OTP para consultas (RFC, vigencia, etc.).
  """

  defstruct [:raw_der, :parsed]

  @type t :: %__MODULE__{raw_der: binary(), parsed: Clir.Openssl.X509.otp_cert()}

  @rfc_re ~r/^[A-Z&Ñ]{3,4}\d{6}[A-Z\d]{3}$/iu

  @doc """
  Crea un certificado a partir del contenido DER binario (.cer).
  """
  @spec from_der(binary()) :: {:ok, t()} | {:error, term()}
  def from_der(binary) when is_binary(binary) do
    case Clir.Openssl.X509.from_der(binary) do
      {:ok, otp} -> {:ok, %__MODULE__{raw_der: binary, parsed: otp}}
      err -> err
    end
  end

  @doc """
  Crea un certificado a partir de un string PEM.
  """
  @spec from_pem(String.t()) :: {:ok, t()} | {:error, term()}
  def from_pem(pem) when is_binary(pem) do
    with {:ok, der} <- der_from_pem(pem),
         {:ok, otp} <- Clir.Openssl.X509.from_der(der) do
      {:ok, %__MODULE__{raw_der: der, parsed: otp}}
    end
  end

  @doc """
  Lee un archivo `.cer` (DER o PEM).
  """
  @spec from_file(String.t()) :: {:ok, t()} | {:error, term()}
  def from_file(path) do
    case File.read(path) do
      {:ok, bin} ->
        if pem_like?(bin), do: from_pem(bin), else: from_der(bin)

      {:error, reason} ->
        {:error, {:read_failed, path, reason}}
    end
  end

  @doc """
  PEM del certificado (incluye cabeceras).
  """
  @spec to_pem(t()) :: String.t()
  def to_pem(%__MODULE__{raw_der: der}) do
    :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
  end

  @doc """
  DER crudo del certificado.
  """
  @spec to_der(t()) :: binary()
  def to_der(%__MODULE__{raw_der: der}), do: der

  @doc """
  Número de serie en hexadecimal (mayúsculas).
  """
  @spec serial_number(t()) :: String.t()
  def serial_number(%__MODULE__{parsed: otp}), do: Clir.Openssl.X509.serial(otp)

  @doc """
  Número de certificado en formato SAT (ver `Clir.Openssl.X509.no_certificado/1`).
  """
  @spec no_certificado(t()) :: String.t()
  def no_certificado(%__MODULE__{parsed: otp}), do: Clir.Openssl.X509.no_certificado(otp)

  @doc """
  RFC del titular, inferido del subject (OIDs típicos del SAT).
  """
  @spec rfc(t()) :: String.t()
  def rfc(%__MODULE__{parsed: otp}) do
    attrs = subject_attributes(otp)

    rfc_from_keys(attrs, ["x500UniqueIdentifier", "serialNumber", "UID"]) ||
      rfc_fallback(attrs)
  end

  defp rfc_from_keys(attrs, keys) do
    Enum.find_value(keys, fn key ->
      case Map.get(attrs, key) do
        nil -> nil
        raw -> rfc_from_raw(raw)
      end
    end)
  end

  defp rfc_from_raw(raw) when is_binary(raw) do
    part = raw |> String.split("/") |> hd() |> String.trim()
    if part != "" and Regex.match?(@rfc_re, part), do: String.upcase(part)
  end

  defp rfc_fallback(attrs) do
    Enum.find_value(attrs, fn {_k, v} ->
      if is_binary(v) do
        part = v |> String.split("/") |> hd() |> String.trim()
        if part != "" and Regex.match?(@rfc_re, part), do: String.upcase(part)
      end
    end) || ""
  end

  @doc """
  Nombre legal (CN o, en su defecto, givenName).
  """
  @spec legal_name(t()) :: String.t()
  def legal_name(%__MODULE__{parsed: otp}) do
    attrs = subject_attributes(otp)
    Map.get(attrs, "CN") || Map.get(attrs, "givenName") || ""
  end

  @doc """
  Issuer como mapa atributo => valor.
  """
  @spec issuer(t()) :: %{String.t() => String.t()}
  def issuer(%__MODULE__{parsed: otp}) do
    tbs = Clir.Openssl.X509.otp_tbs(otp)
    {:OTPTBSCertificate, _, _, _, issuer, _, _, _, _, _, _} = tbs
    rdn_to_attr_map(issuer)
  end

  @doc """
  Subject como mapa atributo => valor.
  """
  @spec subject(t()) :: %{String.t() => String.t()}
  def subject(%__MODULE__{parsed: otp}), do: subject_attributes(otp)

  @doc """
  Inicio de vigencia (UTC).
  """
  @spec valid_from(t()) :: DateTime.t()
  def valid_from(%__MODULE__{parsed: otp}) do
    %{not_before: nb} = Clir.Openssl.X509.validity(otp)
    nb
  end

  @doc """
  Fin de vigencia (UTC).
  """
  @spec valid_to(t()) :: DateTime.t()
  def valid_to(%__MODULE__{parsed: otp}) do
    %{not_after: na} = Clir.Openssl.X509.validity(otp)
    na
  end

  @doc """
  `true` si la fecha actual es posterior a `valid_to/1`.
  """
  @spec expired?(t()) :: boolean()
  def expired?(%__MODULE__{} = cert) do
    DateTime.compare(DateTime.utc_now(), valid_to(cert)) == :gt
  end

  @doc """
  Huella SHA-1 del DER, formato `AA:BB:CC:...` en mayúsculas (estilo Node).
  """
  @spec fingerprint(t()) :: String.t()
  def fingerprint(%__MODULE__{raw_der: der}) do
    :crypto.hash(:sha, der)
    |> Base.encode16(case: :upper)
    |> String.codepoints()
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(":")
  end

  @doc """
  Huella SHA-256 del DER (hex mayúsculas, sin separadores).
  """
  @spec fingerprint_sha256(t()) :: String.t()
  def fingerprint_sha256(%__MODULE__{raw_der: der}) do
    :crypto.hash(:sha256, der) |> Base.encode16(case: :upper)
  end

  @doc """
  Contenido del certificado en Base64 (sin cabeceras PEM ni saltos).
  """
  @spec to_base64(t()) :: String.t()
  def to_base64(%__MODULE__{raw_der: der}), do: Base.encode64(der)

  @doc """
  Llave pública del certificado en formato PEM `-----BEGIN PUBLIC KEY-----`.
  """
  @spec public_key_pem(t()) :: String.t()
  def public_key_pem(%__MODULE__{} = cert) do
    rsa_pub = public_key(cert)
    entry = :public_key.pem_entry_encode(:SubjectPublicKeyInfo, rsa_pub)
    :public_key.pem_encode([entry])
  end

  @doc """
  Llave pública RSA decodificada (`{:RSAPublicKey, modulus, exponent}`).
  """
  @spec public_key(t()) :: {:RSAPublicKey, integer(), integer()}
  def public_key(%__MODULE__{parsed: otp}) do
    tbs = Clir.Openssl.X509.otp_tbs(otp)
    {:OTPTBSCertificate, _, _, _, _, _, _, spki, _, _, _} = tbs
    {:OTPSubjectPublicKeyInfo, _alg, pub_key} = spki
    pub_key
  end

  @doc """
  Detecta el tipo de certificado por **extensiones X.509 estándar**:

    - `:csd` (Certificado de Sello Digital): `keyUsage` con `digitalSignature`
      y `nonRepudiation` activos, sin `dataEncipherment` ni `keyAgreement`.
    - `:fiel` (e.firma / FIEL): `extKeyUsage` con `emailProtection` y
      `clientAuth` activos.

  Si las extensiones no resuelven el tipo, hace fallback a la heurística del
  OU del subject (`Prueba_CFDI`, `FIEL`, etc.). Retorna `:unknown` si no
  se puede determinar.
  """
  @spec certificate_type(t()) :: :csd | :fiel | :unknown
  def certificate_type(%__MODULE__{parsed: otp} = cert) do
    case classify_by_extensions(otp) do
      type when type in [:csd, :fiel] -> type
      :unknown -> classify_by_ou(cert)
    end
  end

  defp classify_by_extensions(otp) do
    exts = extensions(otp)

    cond do
      ext_key_usage_fiel?(exts) -> :fiel
      key_usage_csd?(exts) -> :csd
      true -> :unknown
    end
  end

  defp extensions(otp) do
    tbs = Clir.Openssl.X509.otp_tbs(otp)
    # OTPTBSCertificate position 10 (index 10) = extensions
    case tuple_size(tbs) do
      11 -> elem(tbs, 10) || []
      _ -> []
    end
  end

  defp ext_key_usage_fiel?(exts) when is_list(exts) do
    Enum.any?(exts, fn
      {:Extension, {2, 5, 29, 37}, _critical, value} ->
        oids = normalize_ext_key_usage(value)
        # 1.3.6.1.5.5.7.3.4 emailProtection, 1.3.6.1.5.5.7.3.2 clientAuth
        Enum.member?(oids, {1, 3, 6, 1, 5, 5, 7, 3, 4}) and
          Enum.member?(oids, {1, 3, 6, 1, 5, 5, 7, 3, 2})

      _ ->
        false
    end)
  end

  defp ext_key_usage_fiel?(_), do: false

  defp normalize_ext_key_usage(value) when is_list(value), do: value
  defp normalize_ext_key_usage(_), do: []

  defp key_usage_csd?(exts) when is_list(exts) do
    Enum.any?(exts, fn
      {:Extension, {2, 5, 29, 15}, _critical, value} ->
        flags = normalize_key_usage(value)

        :digitalSignature in flags and
          :nonRepudiation in flags and
          :dataEncipherment not in flags and
          :keyAgreement not in flags

      _ ->
        false
    end)
  end

  defp key_usage_csd?(_), do: false

  defp normalize_key_usage(flags) when is_list(flags), do: flags
  defp normalize_key_usage(_), do: []

  defp classify_by_ou(%__MODULE__{} = cert) do
    case ou_value(cert) do
      nil ->
        :unknown

      ou ->
        cond do
          csd_marker?(ou) -> :csd
          String.contains?(ou, "FIEL") or String.contains?(ou, "FIRMA") -> :fiel
          true -> :unknown
        end
    end
  end

  @doc """
  `true` si es FIEL (e.firma). Equivalente a `certificate_type/1 == :fiel`.
  """
  @spec is_fiel?(t()) :: boolean()
  def is_fiel?(%__MODULE__{} = cert), do: certificate_type(cert) == :fiel

  @doc """
  `true` si es CSD. Equivalente a `certificate_type/1 == :csd`.
  """
  @spec is_csd?(t()) :: boolean()
  def is_csd?(%__MODULE__{} = cert), do: certificate_type(cert) == :csd

  @doc """
  Versión de la Autoridad Certificadora del SAT (`4` o `5`) que emitió el cert.

  El SAT codifica el número de AC en el dígito 12 (índice 11) del
  `no_certificado` (20 dígitos decimales).

  Retorna `nil` si no se puede determinar.
  """
  @spec ac_version(t()) :: integer() | nil
  def ac_version(%__MODULE__{} = cert) do
    no_cer = no_certificado(cert)

    if String.length(no_cer) >= 12 do
      digit = String.at(no_cer, 11)

      case Integer.parse(digit) do
        {n, _} -> n
        :error -> nil
      end
    end
  end

  @doc """
  Tipo de sujeto (titular):

    - `:moral` — persona moral / empresa: el OID 2.5.4.45 contiene `RFC / CURP`.
    - `:fisica` — persona física: RFC de 13 caracteres sin `/`.
    - `:unknown` — no se pudo determinar.
  """
  @spec subject_type(t()) :: :moral | :fisica | :unknown
  def subject_type(%__MODULE__{parsed: otp} = cert) do
    attrs = subject_attributes(otp)

    case Map.get(attrs, "x500UniqueIdentifier") do
      v when is_binary(v) ->
        cond do
          String.contains?(v, " / ") -> :moral
          String.length(v) == 13 -> :fisica
          true -> subject_type_from_rfc(cert)
        end

      _ ->
        subject_type_from_rfc(cert)
    end
  end

  defp subject_type_from_rfc(cert) do
    case String.length(rfc(cert)) do
      13 -> :fisica
      12 -> :moral
      _ -> :unknown
    end
  end

  @doc """
  `true` si el certificado está vigente: `valid_from <= now <= valid_to`.
  A diferencia de `expired?/1`, también verifica que el inicio de vigencia
  ya esté en el pasado.
  """
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{} = cert) do
    now = DateTime.utc_now()
    DateTime.compare(now, valid_from(cert)) != :lt and DateTime.compare(now, valid_to(cert)) != :gt
  end

  @doc """
  Verifica que este certificado fue firmado por el `issuer` dado.
  Útil para validar la cadena de confianza contra `AC4_SAT.cer` / `AC5_SAT.cer`.

  Retorna `true` si la firma del cert es válida bajo la pública del emisor.
  """
  @spec issued_by?(t(), t()) :: boolean()
  def issued_by?(%__MODULE__{} = subject, %__MODULE__{} = issuer) do
    try do
      tbs_der = extract_tbs_der(subject.raw_der)
      sig_alg = pkix_signature_algorithm(subject.parsed)
      sig = pkix_signature(subject.parsed)
      digest = sig_alg_to_digest(sig_alg)
      pub = public_key(issuer)
      :public_key.verify(tbs_der, digest, sig, pub)
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  # Extrae la sub-secuencia tbsCertificate del DER original sin re-codificar
  # (importante para verificación de firma: los bytes deben ser idénticos a los
  # que el emisor firmó).
  defp extract_tbs_der(<<0x30, rest::binary>>) do
    {_outer_len, body} = read_ber_length(rest)
    {tbs_total, _} = ber_total_length(body)
    binary_part(body, 0, tbs_total)
  end

  defp read_ber_length(<<len, rest::binary>>) when len < 0x80, do: {len, rest}

  defp read_ber_length(<<first, rest::binary>>) when first >= 0x80 do
    n = first - 0x80
    <<len_bytes::binary-size(n), tail::binary>> = rest
    len = :binary.decode_unsigned(len_bytes)
    {len, tail}
  end

  defp ber_total_length(<<_tag, rest::binary>>) do
    {content_len, after_len} = read_ber_length(rest)
    header_len = byte_size(rest) - byte_size(after_len) + 1
    {header_len + content_len, content_len}
  end

  @doc "Alias de `issued_by?/2` por compatibilidad con `e.firma`."
  @spec verify_integrity(t(), t()) :: boolean()
  def verify_integrity(%__MODULE__{} = subject, %__MODULE__{} = issuer),
    do: issued_by?(subject, issuer)

  @doc """
  Verifica una firma Base64 contra `data` con la llave pública del cert.
  Default SHA-256 (lo que exige el SAT).
  """
  @spec verify(t(), iodata(), String.t(), atom()) :: boolean()
  def verify(%__MODULE__{} = cert, data, signature_b64, algo \\ :sha256) do
    with {:ok, sig} <- Base.decode64(signature_b64),
         pub when is_tuple(pub) <- public_key(cert) do
      :public_key.verify(data, algo, sig, pub)
    else
      _ -> false
    end
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  @doc """
  Encripta un mensaje con la llave pública del certificado (RSA PKCS#1 v1.5).
  Solo el dueño de la llave privada puede desencriptar. Retorna Base64.
  """
  @spec rsa_encrypt(t(), iodata()) :: String.t()
  def rsa_encrypt(%__MODULE__{} = cert, message) do
    pub = public_key(cert)
    cipher = :public_key.encrypt_public(IO.iodata_to_binary(message), pub)
    Base.encode64(cipher)
  end

  defp pkix_signature_algorithm(otp) do
    elem(otp, 2)
  end

  defp pkix_signature(otp) do
    elem(otp, 3)
  end

  defp sig_alg_to_digest({:SignatureAlgorithm, oid, _}), do: oid_to_digest(oid)
  defp sig_alg_to_digest(_), do: :sha256

  defp oid_to_digest({1, 2, 840, 113_549, 1, 1, 5}), do: :sha
  defp oid_to_digest({1, 2, 840, 113_549, 1, 1, 11}), do: :sha256
  defp oid_to_digest({1, 2, 840, 113_549, 1, 1, 12}), do: :sha384
  defp oid_to_digest({1, 2, 840, 113_549, 1, 1, 13}), do: :sha512
  defp oid_to_digest(_), do: :sha256

  defp csd_marker?(ou) do
    String.contains?(ou, "CSD") or
      String.contains?(ou, "CFDI") or
      String.contains?(ou, "SELLO")
  end

  defp ou_value(%__MODULE__{parsed: otp}) do
    case Map.get(subject_attributes(otp), "OU") do
      nil -> nil
      v -> String.upcase(v)
    end
  end

  defp pem_like?(bin) do
    sample = binary_part(bin, 0, min(byte_size(bin), 32))
    String.contains?(sample, "-----")
  end

  defp der_from_pem(pem) do
    case :public_key.pem_decode(pem) do
      [{:Certificate, der, _} | _] -> {:ok, der}
      _ -> {:error, :no_certificate_pem}
    end
  end

  defp subject_attributes(otp) do
    tbs = Clir.Openssl.X509.otp_tbs(otp)
    {:OTPTBSCertificate, _, _, _, _, _, subject, _, _, _, _} = tbs
    rdn_to_attr_map(subject)
  end

  defp rdn_to_attr_map({:rdnSequence, seq}) do
    Enum.reduce(seq, %{}, fn avas, acc ->
      Enum.reduce(avas, acc, fn {:AttributeTypeAndValue, oid, value}, a ->
        short = oid_to_attr_key(oid)
        str = directory_string(value)
        Map.put(a, short, str)
      end)
    end)
  end

  defp rdn_to_attr_map(_), do: %{}

  defp oid_to_attr_key({2, 5, 4, 3}), do: "CN"
  defp oid_to_attr_key({2, 5, 4, 5}), do: "serialNumber"
  defp oid_to_attr_key({2, 5, 4, 6}), do: "C"
  defp oid_to_attr_key({2, 5, 4, 7}), do: "L"
  defp oid_to_attr_key({2, 5, 4, 8}), do: "ST"
  defp oid_to_attr_key({2, 5, 4, 10}), do: "O"
  defp oid_to_attr_key({2, 5, 4, 11}), do: "OU"
  defp oid_to_attr_key({2, 5, 4, 42}), do: "givenName"
  defp oid_to_attr_key({2, 5, 4, 45}), do: "x500UniqueIdentifier"
  defp oid_to_attr_key({0, 9, 2342, 19200300, 100, 1, 1}), do: "UID"
  defp oid_to_attr_key(oid) when is_tuple(oid), do: oid |> Tuple.to_list() |> Enum.join(".")

  defp directory_string({:utf8String, b}) when is_binary(b), do: b
  defp directory_string({:utf8String, b}) when is_list(b), do: List.to_string(b)
  defp directory_string({:printableString, b}) when is_binary(b), do: b
  defp directory_string({:printableString, b}) when is_list(b), do: List.to_string(b)
  defp directory_string({:teletexString, b}) when is_binary(b), do: b
  defp directory_string({:teletexString, b}) when is_list(b), do: List.to_string(b)
  defp directory_string({:ia5String, b}) when is_binary(b), do: b
  defp directory_string({:ia5String, b}) when is_list(b), do: List.to_string(b)
  defp directory_string({:universalString, b}) when is_binary(b), do: b
  defp directory_string({:universalString, b}) when is_list(b), do: List.to_string(b)
  defp directory_string({:bmpString, b}) when is_binary(b), do: b
  defp directory_string({:bmpString, b}) when is_list(b), do: List.to_string(b)

  defp directory_string(s) when is_binary(s) do
    case decode_ber_string(s) do
      {:ok, str} -> str
      :error -> s
    end
  end

  defp directory_string(s) when is_list(s), do: List.to_string(s)
  defp directory_string(_), do: ""

  defp decode_ber_string(<<tag, len, rest::binary>>)
       when tag in [0x0C, 0x13, 0x14, 0x16, 0x1C, 0x1E] and byte_size(rest) >= len do
    <<str::binary-size(len), _::binary>> = rest
    {:ok, str}
  end

  defp decode_ber_string(_), do: :error
end
