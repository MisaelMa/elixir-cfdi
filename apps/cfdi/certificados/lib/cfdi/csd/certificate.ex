defmodule Cfdi.Csd.Certificate do
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
  Issuer como cadena tipo LDAP.
  """
  @spec issuer(t()) :: String.t()
  def issuer(%__MODULE__{parsed: otp}), do: Clir.Openssl.X509.issuer(otp)

  @doc """
  Subject como cadena tipo LDAP.
  """
  @spec subject(t()) :: String.t()
  def subject(%__MODULE__{parsed: otp}), do: Clir.Openssl.X509.subject(otp)

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
  Huella del DER del certificado; por defecto SHA-256 (hex mayúsculas, sin separadores).
  """
  @spec fingerprint(t(), :md5 | :sha | :sha256) :: String.t()
  def fingerprint(%__MODULE__{raw_der: der}, algo \\ :sha256) do
    digest = algo_to_digest(algo)
    :crypto.hash(digest, der) |> Base.encode16(case: :upper)
  end

  defp algo_to_digest(:md5), do: :md5
  defp algo_to_digest(:sha), do: :sha
  defp algo_to_digest(:sha256), do: :sha256

  @doc """
  Contenido del certificado en Base64 (sin cabeceras PEM ni saltos).
  """
  @spec to_base64(t()) :: String.t()
  def to_base64(%__MODULE__{raw_der: der}), do: Base.encode64(der)

  @doc """
  `true` si algún atributo OU del subject contiene el texto \"FIEL\".
  """
  @spec is_fiel?(t()) :: boolean()
  def is_fiel?(%__MODULE__{parsed: otp}) do
    tbs = Clir.Openssl.X509.otp_tbs(otp)
    {:OTPTBSCertificate, _, _, _, _, _, subject, _, _, _, _} = tbs
    subject_has_fiel_ou?(subject)
  end

  defp subject_has_fiel_ou?({:rdnSequence, seq}) do
    Enum.any?(seq, fn avas ->
      Enum.any?(avas, fn
        {:AttributeTypeAndValue, {2, 5, 4, 11}, value} ->
          value |> directory_string() |> String.upcase() |> String.contains?("FIEL")

        _ ->
          false
      end)
    end)
  end

  defp subject_has_fiel_ou?(_), do: false

  @doc """
  `true` si no es FIEL según `is_fiel?/1` (certificado orientado a sello / no FIEL).
  """
  @spec is_csd?(t()) :: boolean()
  def is_csd?(%__MODULE__{} = cert), do: not is_fiel?(cert)

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
  defp oid_to_attr_key({2, 5, 4, 10}), do: "O"
  defp oid_to_attr_key({2, 5, 4, 11}), do: "OU"
  defp oid_to_attr_key({2, 5, 4, 42}), do: "givenName"
  defp oid_to_attr_key({2, 5, 4, 45}), do: "x500UniqueIdentifier"
  defp oid_to_attr_key({0, 9, 2342, 19200300, 100, 1, 1}), do: "UID"
  defp oid_to_attr_key(oid) when is_tuple(oid), do: oid |> Tuple.to_list() |> Enum.join(".")

  defp directory_string({:utf8String, b}) when is_binary(b), do: b
  defp directory_string({:printableString, b}) when is_binary(b), do: b
  defp directory_string({:teletexString, b}) when is_binary(b), do: b
  defp directory_string({:ia5String, b}) when is_binary(b), do: b
  defp directory_string(s) when is_binary(s), do: s
  defp directory_string(s) when is_list(s), do: List.to_string(s)
  defp directory_string(_), do: ""
end
