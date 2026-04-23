defmodule Cfdi.Csd.PrivateKey do
  @moduledoc """
  Llave privada RSA en PKCS#8 (típico archivo `.key` del SAT, DER cifrado o PEM claro).
  """

  defstruct [:raw_der, :decoded]

  @type t :: %__MODULE__{raw_der: binary(), decoded: term()}

  @doc """
  Carga llave desde DER (p. ej. `.key` cifrado del SAT) usando la contraseña.
  """
  @spec from_der(binary(), String.t() | nil) :: {:ok, t()} | {:error, term()}
  def from_der(der, password) when is_binary(der) do
    case Clir.Openssl.Pkcs8.to_pem(der, password) do
      {:ok, pem} ->
        case Clir.Openssl.Pkcs8.from_pem(pem, nil) do
          {:ok, decoded} -> {:ok, %__MODULE__{raw_der: der, decoded: decoded}}
          err -> err
        end

      err ->
        err
    end
  end

  @doc """
  Carga llave desde PEM (sin cifrar).
  """
  @spec from_pem(String.t()) :: {:ok, t()} | {:error, term()}
  def from_pem(pem) when is_binary(pem) do
    with {:ok, decoded} <- Clir.Openssl.Pkcs8.from_pem(pem, nil) do
      der = pem_to_raw_der(decoded, pem)
      {:ok, %__MODULE__{raw_der: der, decoded: decoded}}
    end
  end

  defp pem_to_raw_der(decoded, _pem) do
    cond do
      match?({:PrivateKeyInfo, _, _, _, _}, decoded) ->
        :public_key.der_encode(:PrivateKeyInfo, decoded)

      match?({:RSAPrivateKey, _, _, _, _, _, _, _, _}, decoded) ->
        :public_key.der_encode(:RSAPrivateKey, decoded)

      true ->
        <<>>
    end
  end

  @doc """
  Lee archivo `.key` (DER cifrado o PEM claro).
  """
  @spec from_file(String.t(), String.t() | nil) :: {:ok, t()} | {:error, term()}
  def from_file(path, password \\ nil) do
    case File.read(path) do
      {:ok, bin} ->
        if pem_like?(bin) do
          from_pem(bin)
        else
          from_der(bin, password || "")
        end

      {:error, reason} ->
        {:error, {:read_failed, path, reason}}
    end
  end

  @doc """
  Firma datos con RSA y SHA-256; devuelve la firma en Base64 (PKCS-1 v1.5).
  """
  @spec sign(t(), iodata()) :: String.t()
  def sign(%__MODULE__{decoded: key}, data) do
    sig = :public_key.sign(data, :sha256, key)
    Base.encode64(sig)
  end

  defp pem_like?(bin) do
    sample = binary_part(bin, 0, min(byte_size(bin), 32))
    String.contains?(sample, "-----")
  end
end
