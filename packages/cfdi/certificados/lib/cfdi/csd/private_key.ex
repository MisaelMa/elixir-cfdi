defmodule Cfdi.Csd.PrivateKey do
  @moduledoc """
  Llave privada RSA en PKCS#8 (típico archivo `.key` del SAT, DER cifrado o PEM claro).
  """

  alias Cfdi.Csd.Certificate

  defstruct [:raw_der, :decoded]

  @type t :: %__MODULE__{raw_der: binary(), decoded: term()}

  @typedoc """
  Opciones de carga.

    * `:strict` — si `true`, rechaza llaves no cifradas (PKCS#8 plano o PKCS#1).
      Por convención SAT las `.key` siempre vienen cifradas.
  """
  @type load_opts :: [strict: boolean()]

  @doc """
  Carga llave desde DER (p. ej. `.key` cifrado del SAT) usando la contraseña.

  Soporta PKCS#8 EncryptedPrivateKeyInfo (formato SAT), PKCS#8 PrivateKeyInfo
  plano y PKCS#1 RSAPrivateKey plano.

  Cuando `opts[:strict]` es `true`, **solo** acepta PKCS#8 cifrado.
  """
  @spec from_der(binary(), String.t() | nil, load_opts()) :: {:ok, t()} | {:error, term()}
  def from_der(der, password, opts \\ []) when is_binary(der) do
    case detect_der_kind(der) do
      :encrypted_pkcs8 ->
        with {:ok, pem} <- Clir.Openssl.Pkcs8.to_pem(der, password),
             {:ok, decoded} <- Clir.Openssl.Pkcs8.from_pem(pem, nil) do
          {:ok, %__MODULE__{raw_der: der, decoded: decoded}}
        end

      _kind when opts != [] ->
        if Keyword.get(opts, :strict, false) do
          {:error, :not_encrypted_pkcs8}
        else
          load_plain_der(der)
        end

      _ ->
        load_plain_der(der)
    end
  end

  defp load_plain_der(der) do
    case try_decode(:PrivateKeyInfo, der) do
      {:ok, decoded} -> {:ok, %__MODULE__{raw_der: der, decoded: decoded}}
      _ ->
        case try_decode(:RSAPrivateKey, der) do
          {:ok, decoded} -> {:ok, %__MODULE__{raw_der: der, decoded: decoded}}
          err -> err
        end
    end
  end

  defp try_decode(type, der) do
    {:ok, :public_key.der_decode(type, der)}
  rescue
    _ -> {:error, :decode_failed}
  catch
    _, _ -> {:error, :decode_failed}
  end

  defp detect_der_kind(der) do
    cond do
      match?({:ok, _}, try_decode(:PrivateKeyInfo, der)) -> :plain_pkcs8
      match?({:ok, _}, try_decode(:RSAPrivateKey, der)) -> :plain_pkcs1
      true -> :encrypted_pkcs8
    end
  end

  @doc """
  Carga llave desde PEM (sin cifrar).
  """
  @spec from_pem(String.t()) :: {:ok, t()} | {:error, term()}
  def from_pem(pem) when is_binary(pem) do
    with {:ok, decoded} <- Clir.Openssl.Pkcs8.from_pem(pem, nil) do
      der = encode_decoded_to_der(decoded)
      {:ok, %__MODULE__{raw_der: der, decoded: decoded}}
    end
  end

  defp encode_decoded_to_der(k) when is_tuple(k) and elem(k, 0) == :RSAPrivateKey do
    :public_key.der_encode(:RSAPrivateKey, k)
  end

  defp encode_decoded_to_der({:PrivateKeyInfo, _, _, _, _} = k) do
    :public_key.der_encode(:PrivateKeyInfo, k)
  end

  defp encode_decoded_to_der(_), do: <<>>

  @doc """
  Lee archivo `.key` (DER cifrado o PEM claro).

  En modo `strict: true` rechaza PEM y DER sin cifrar.
  """
  @spec from_file(String.t(), String.t() | nil, load_opts()) :: {:ok, t()} | {:error, term()}
  def from_file(path, password \\ nil, opts \\ []) do
    case File.read(path) do
      {:ok, bin} ->
        cond do
          pem_like?(bin) and Keyword.get(opts, :strict, false) ->
            {:error, :not_encrypted_pkcs8}

          pem_like?(bin) ->
            from_pem(bin)

          true ->
            from_der(bin, password || "", opts)
        end

      {:error, reason} ->
        {:error, {:read_failed, path, reason}}
    end
  end

  @doc """
  PEM PKCS#8 (sin cifrar) de la llave decodificada.
  """
  @spec to_pem(t()) :: String.t()
  def to_pem(%__MODULE__{decoded: decoded}) do
    rsa = ensure_rsa_private(decoded)
    der = :public_key.der_encode(:RSAPrivateKey, rsa)

    pki =
      {:PrivateKeyInfo, :v1,
       {:PrivateKeyInfo_privateKeyAlgorithm, {1, 2, 840, 113_549, 1, 1, 1}, {:asn1_OPENTYPE, <<5, 0>>}}, der,
       :asn1_NOVALUE}

    pki_der = :public_key.der_encode(:PrivateKeyInfo, pki)
    :public_key.pem_encode([{:PrivateKeyInfo, pki_der, :not_encrypted}])
  end

  @doc """
  Firma datos con RSA y SHA-256 por defecto; devuelve la firma en Base64.

  Algoritmos válidos: `:sha256`, `:sha384`, `:sha512`, `:sha`, `:md5`.
  """
  @spec sign(t(), iodata(), atom()) :: String.t()
  def sign(%__MODULE__{decoded: decoded}, data, algo \\ :sha256) do
    rsa = ensure_rsa_private(decoded)
    sig = :public_key.sign(data, algo, rsa)
    Base.encode64(sig)
  end

  @doc """
  Desencripta un mensaje cifrado con la llave pública del certificado
  correspondiente (RSA PKCS#1 v1.5). El input debe estar en Base64.
  Retorna el plaintext como binary.
  """
  @spec rsa_decrypt(t(), String.t()) :: {:ok, binary()} | {:error, term()}
  def rsa_decrypt(%__MODULE__{decoded: decoded}, ciphertext_b64) do
    with {:ok, cipher} <- Base.decode64(ciphertext_b64) do
      rsa = ensure_rsa_private(decoded)
      plain = :public_key.decrypt_private(cipher, rsa)
      {:ok, plain}
    end
  rescue
    e -> {:error, e}
  catch
    _, e -> {:error, e}
  end

  @doc """
  `true` si esta llave corresponde al certificado dado (mismo módulo y exponente).
  """
  @spec belongs_to_certificate?(t(), Certificate.t()) :: boolean()
  def belongs_to_certificate?(%__MODULE__{decoded: priv}, %Certificate{} = cert) do
    rsa_priv = ensure_rsa_private(priv)
    n = elem(rsa_priv, 2)
    e = elem(rsa_priv, 3)

    case Certificate.public_key(cert) do
      {:RSAPublicKey, n2, e2} -> n == n2 and e == e2
      _ -> false
    end
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  defp ensure_rsa_private(k) when is_tuple(k) and elem(k, 0) == :RSAPrivateKey, do: k

  defp ensure_rsa_private({:PrivateKeyInfo, _, _, der, _}) when is_binary(der) do
    :public_key.der_decode(:RSAPrivateKey, der)
  end

  defp pem_like?(bin) do
    sample = binary_part(bin, 0, min(byte_size(bin), 32))
    String.contains?(sample, "-----")
  end
end
