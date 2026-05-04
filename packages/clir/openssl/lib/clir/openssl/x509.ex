defmodule Clir.Openssl.X509 do
  @moduledoc """
  Lectura de certificados X.509 vía `:public_key.pkix_decode_cert/2` (formato OTP interno).
  """

  @typedoc "Certificado en formato OTP (`:OTPCertificate`)."
  @type otp_cert :: tuple()

  @doc """
  Convierte certificado DER a PEM, o lee un archivo si `der_or_path` es una ruta existente.
  """
  @spec get_pem(binary()) :: {:ok, String.t()} | {:error, term()}
  def get_pem(der_or_path) when is_binary(der_or_path) do
    cond do
      maybe_path?(der_or_path) and File.exists?(der_or_path) ->
        with {:ok, der} <- file_as_der(der_or_path) do
          {:ok, der_to_pem(der)}
        end

      true ->
        {:ok, der_to_pem(der_or_path)}
    end
  end

  defp maybe_path?(b) do
    byte_size(b) < 8192 and not String.contains?(b, <<0>>)
  end

  defp file_as_der(path) do
    case File.read(path) do
      {:ok, bin} ->
        if pem_like?(bin) do
          with {:ok, der} <- der_from_pem(bin), do: {:ok, der}
        else
          {:ok, bin}
        end

      {:error, reason} ->
        {:error, {:read_failed, path, reason}}
    end
  end

  defp pem_like?(bin) do
    sample = binary_part(bin, 0, min(byte_size(bin), 32))
    String.contains?(sample, "-----")
  end

  defp der_from_pem(pem) do
    case :public_key.pem_decode(pem) do
      [{:Certificate, der, _} | _] ->
        {:ok, der}

      _ ->
        {:error, :no_certificate_pem}
    end
  end

  defp der_to_pem(der) when is_binary(der) do
    :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
  end

  @doc """
  Número de serie en hexadecimal (mayúsculas), como string.
  """
  @spec serial(otp_cert()) :: String.t()
  def serial(cert) do
    tbs = otp_tbs(cert)
    serial_int = elem(tbs, 2)
    serial_int |> Integer.to_string(16) |> String.upcase()
  end

  @doc """
  Subject en formato estilo LDAP (CN=..., O=..., ...).
  """
  @spec subject(otp_cert()) :: String.t()
  def subject(cert) do
    {:OTPTBSCertificate, _, _, _, _, _, subject, _, _, _, _} = otp_tbs(cert)
    format_name(subject)
  end

  @doc """
  Issuer en formato estilo LDAP.
  """
  @spec issuer(otp_cert()) :: String.t()
  def issuer(cert) do
    {:OTPTBSCertificate, _, _, _, issuer, _, _, _, _, _, _} = otp_tbs(cert)
    format_name(issuer)
  end

  @doc """
  Vigencia como `%{not_before: DateTime.t(), not_after: DateTime.t()}` en UTC.
  """
  @spec validity(otp_cert()) :: %{not_before: DateTime.t(), not_after: DateTime.t()}
  def validity(cert) do
    {:OTPTBSCertificate, _, _, _, _, {:Validity, nb, na}, _, _, _, _, _} = otp_tbs(cert)

    %{
      not_before: asn1_time_to_datetime(nb),
      not_after: asn1_time_to_datetime(na)
    }
  end

  @doc """
  Huella del DER del certificado. `algo` puede ser `:md5`, `:sha` o `:sha256`.
  """
  @spec fingerprint(otp_cert(), :md5 | :sha | :sha256) :: String.t()
  def fingerprint(cert, algo \\ :sha) do
    der = otp_cert_der(cert)
    digest_type = algo_to_digest_type(algo)
    :crypto.hash(digest_type, der) |> Base.encode16(case: :upper)
  end

  defp algo_to_digest_type(:md5), do: :md5
  defp algo_to_digest_type(:sha), do: :sha
  defp algo_to_digest_type(:sha256), do: :sha256

  @doc """
  Número de certificado SAT: si el serial en hex son pares ASCII de dígitos (`0`–`9`), se decodifica a string decimal; si no, se devuelve el hex.
  """
  @spec no_certificado(otp_cert()) :: String.t()
  def no_certificado(cert) do
    cert |> serial() |> sat_decimal_from_serial_hex()
  end

  defp sat_decimal_from_serial_hex(hex) do
    if rem(String.length(hex), 2) == 0 do
      h = String.downcase(hex)
      len = String.length(h)

      pairs =
        for i <- 0..(div(len, 2) - 1)//1 do
          String.slice(h, i * 2, 2)
        end

      all_digits =
        Enum.all?(pairs, fn p ->
          code = String.to_integer(p, 16)
          code >= ?0 and code <= ?9
        end)

      if all_digits do
        pairs |> Enum.map(fn p -> <<String.to_integer(p, 16)>> end) |> IO.iodata_to_binary()
      else
        hex
      end
    else
      hex
    end
  end

  @doc """
  Parsea certificado DER y devuelve la tupla OTP.
  """
  @spec from_der(binary()) :: {:ok, otp_cert()} | {:error, term()}
  def from_der(binary) when is_binary(binary) do
    try do
      {:ok, :public_key.pkix_decode_cert(binary, :otp)}
    rescue
      _ -> {:error, :invalid_certificate}
    catch
      :error, _ -> {:error, :invalid_certificate}
    end
  end

  @doc """
  Parsea certificado PEM.
  """
  @spec from_pem(String.t()) :: {:ok, otp_cert()} | {:error, term()}
  def from_pem(pem) when is_binary(pem) do
    with {:ok, der} <- der_from_pem(pem), do: from_der(der)
  end

  @doc """
  Lee certificado desde archivo (.cer DER o PEM).
  """
  @spec from_file(String.t()) :: {:ok, otp_cert()} | {:error, term()}
  def from_file(path) do
    case File.read(path) do
      {:ok, bin} ->
        if pem_like?(bin), do: from_pem(bin), else: from_der(bin)

      {:error, reason} ->
        {:error, {:read_failed, path, reason}}
    end
  end

  @doc false
  def otp_cert_der(cert) do
    :public_key.pkix_encode(:OTPCertificate, cert, :otp)
  end

  @doc false
  def otp_tbs(cert) when is_tuple(cert) and tuple_size(cert) >= 2 do
    elem(cert, 1)
  end

  defp format_name({:rdnSequence, seq}) do
    seq
    |> Enum.map(fn avas ->
      avas
      |> Enum.map(&format_ava/1)
      |> Enum.join("+")
    end)
    |> Enum.join(",")
  end

  defp format_name(_), do: ""

  defp format_ava({:AttributeTypeAndValue, oid, value}) do
    short = oid_to_label(oid)
    str = directory_string(value)
    short <> "=" <> str
  end

  defp format_ava(_), do: ""

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
  defp directory_string(s) when is_binary(s), do: s
  defp directory_string(s) when is_list(s), do: List.to_string(s)
  defp directory_string(_), do: ""

  defp oid_to_label({2, 5, 4, 3}), do: "CN"
  defp oid_to_label({2, 5, 4, 4}), do: "SN"
  defp oid_to_label({2, 5, 4, 5}), do: "serialNumber"
  defp oid_to_label({2, 5, 4, 6}), do: "C"
  defp oid_to_label({2, 5, 4, 7}), do: "L"
  defp oid_to_label({2, 5, 4, 8}), do: "ST"
  defp oid_to_label({2, 5, 4, 10}), do: "O"
  defp oid_to_label({2, 5, 4, 11}), do: "OU"
  defp oid_to_label({2, 5, 4, 42}), do: "givenName"
  defp oid_to_label({2, 5, 4, 45}), do: "UID"
  defp oid_to_label({0, 9, 2342, 19200300, 100, 1, 1}), do: "UID"
  defp oid_to_label(oid) when is_tuple(oid), do: oid |> Tuple.to_list() |> Enum.join(".")

  defp asn1_time_to_datetime({:utcTime, t}) do
    s = to_string_list(t)
    {yy, rest} = String.split_at(s, 2)

    year =
      case String.to_integer(yy) do
        n when n >= 50 -> 1900 + n
        n -> 2000 + n
      end

    <<mo::binary-size(2), d::binary-size(2), hh::binary-size(2), mm::binary-size(2), ss::binary-size(2), _z::binary>> =
      rest

    DateTime.new!(
      Date.new!(year, String.to_integer(mo), String.to_integer(d)),
      Time.new!(String.to_integer(hh), String.to_integer(mm), String.to_integer(ss)),
      "Etc/UTC"
    )
  end

  defp asn1_time_to_datetime({:generalTime, t}) do
    s = to_string_list(t)

    <<y::binary-size(4), mo::binary-size(2), d::binary-size(2), hh::binary-size(2), mm::binary-size(2),
      ss::binary-size(2), _::binary>> = s

    DateTime.new!(
      Date.new!(String.to_integer(y), String.to_integer(mo), String.to_integer(d)),
      Time.new!(String.to_integer(hh), String.to_integer(mm), String.to_integer(ss)),
      "Etc/UTC"
    )
  end

  defp to_string_list(t) when is_list(t), do: List.to_string(t)
  defp to_string_list(t) when is_binary(t), do: t
end
