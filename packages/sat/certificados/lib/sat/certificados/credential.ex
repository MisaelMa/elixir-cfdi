defmodule Sat.Certificados.Credential do
  @moduledoc """
  Credencial SAT: certificado (`.cer`) y llave privada (`.key`) asociados.
  """

  alias Sat.Certificados.{Certificate, PrivateKey}

  defstruct [:certificate, :private_key]

  @type t :: %__MODULE__{certificate: Certificate.t(), private_key: PrivateKey.t()}

  @doc """
  Carga certificado y llave desde rutas de archivo.
  """
  @spec create(String.t(), String.t(), String.t() | nil) :: {:ok, t()} | {:error, term()}
  def create(cer_path, key_path, password \\ nil) do
    with {:ok, cert} <- Certificate.from_file(cer_path),
         {:ok, pk} <- PrivateKey.from_file(key_path, password) do
      {:ok, %__MODULE__{certificate: cert, private_key: pk}}
    end
  end

  @doc """
  Crea una credencial a partir de strings PEM (cer y key sin cifrar).
  """
  @spec from_pem(String.t(), String.t()) :: {:ok, t()} | {:error, term()}
  def from_pem(cer_pem, key_pem) when is_binary(cer_pem) and is_binary(key_pem) do
    with {:ok, cert} <- Certificate.from_pem(cer_pem),
         {:ok, pk} <- PrivateKey.from_pem(key_pem) do
      {:ok, %__MODULE__{certificate: cert, private_key: pk}}
    end
  end

  @doc "RFC del titular (desde el certificado)."
  @spec rfc(t()) :: String.t()
  def rfc(%__MODULE__{certificate: c}), do: Certificate.rfc(c)

  @doc "Nombre legal del titular."
  @spec legal_name(t()) :: String.t()
  def legal_name(%__MODULE__{certificate: c}), do: Certificate.legal_name(c)

  @doc "Número de serie del certificado (hex)."
  @spec serial_number(t()) :: String.t()
  def serial_number(%__MODULE__{certificate: c}), do: Certificate.serial_number(c)

  @doc "Número de certificado SAT."
  @spec no_certificado(t()) :: String.t()
  def no_certificado(%__MODULE__{certificate: c}), do: Certificate.no_certificado(c)

  @doc """
  Firma datos con la llave privada (SHA-256 por defecto, Base64).
  """
  @spec sign(t(), iodata(), atom()) :: String.t()
  def sign(%__MODULE__{private_key: pk}, data, algo \\ :sha256), do: PrivateKey.sign(pk, data, algo)

  @doc """
  Verifica una firma Base64 contra `data` usando la llave pública del certificado.
  """
  @spec verify(t(), iodata(), String.t(), atom()) :: boolean()
  def verify(%__MODULE__{certificate: cert}, data, signature_b64, algo \\ :sha256) do
    with {:ok, sig} <- Base.decode64(signature_b64),
         pub when is_tuple(pub) <- Certificate.public_key(cert) do
      :public_key.verify(data, algo, sig, pub)
    else
      _ -> false
    end
  rescue
    _ -> false
  catch
    _, _ -> false
  end

  @doc "`true` si el certificado no está vencido."
  @spec valid?(t()) :: boolean()
  def valid?(%__MODULE__{certificate: c}), do: not Certificate.expired?(c)

  @doc "`true` si el RFC del certificado coincide (case insensitive) con `rfc`."
  @spec belongs_to?(t(), String.t()) :: boolean()
  def belongs_to?(%__MODULE__{} = cred, rfc) when is_binary(rfc) do
    String.upcase(rfc(cred)) == String.upcase(rfc)
  end

  @doc "`true` si la llave privada corresponde al certificado de la credencial."
  @spec key_matches_certificate?(t()) :: boolean()
  def key_matches_certificate?(%__MODULE__{certificate: c, private_key: pk}) do
    PrivateKey.belongs_to_certificate?(pk, c)
  end

  @doc "Ver `Sat.Certificados.Certificate.is_fiel?/1`."
  @spec is_fiel?(t()) :: boolean()
  def is_fiel?(%__MODULE__{certificate: c}), do: Certificate.is_fiel?(c)

  @doc "Ver `Sat.Certificados.Certificate.is_csd?/1`."
  @spec is_csd?(t()) :: boolean()
  def is_csd?(%__MODULE__{certificate: c}), do: Certificate.is_csd?(c)
end
