defmodule Cfdi.Csd.Credential do
  @moduledoc """
  Credencial SAT: certificado (`.cer`) y llave privada (`.key`) asociados.
  """

  defstruct [:certificate, :private_key]

  @type t :: %__MODULE__{
          certificate: Cfdi.Csd.Certificate.t(),
          private_key: Cfdi.Csd.PrivateKey.t()
        }

  @doc """
  Carga certificado y llave desde rutas de archivo.
  """
  @spec create(String.t(), String.t(), String.t() | nil) :: {:ok, t()} | {:error, term()}
  def create(cer_path, key_path, password \\ nil) do
    with {:ok, cert} <- Cfdi.Csd.Certificate.from_file(cer_path),
         {:ok, pk} <- Cfdi.Csd.PrivateKey.from_file(key_path, password) do
      {:ok, %__MODULE__{certificate: cert, private_key: pk}}
    end
  end

  @doc """
  RFC del titular (desde el certificado).
  """
  @spec rfc(t()) :: String.t()
  def rfc(%__MODULE__{certificate: c}), do: Cfdi.Csd.Certificate.rfc(c)

  @doc """
  Firma usando la llave privada (`SHA-256`, Base64).
  """
  @spec sign(t(), iodata()) :: String.t()
  def sign(%__MODULE__{private_key: pk}, data), do: Cfdi.Csd.PrivateKey.sign(pk, data)

  @doc """
  Ver `Cfdi.Csd.Certificate.is_fiel?/1`.
  """
  @spec is_fiel?(t()) :: boolean()
  def is_fiel?(%__MODULE__{certificate: c}), do: Cfdi.Csd.Certificate.is_fiel?(c)

  @doc """
  Ver `Cfdi.Csd.Certificate.is_csd?/1`.
  """
  @spec is_csd?(t()) :: boolean()
  def is_csd?(%__MODULE__{certificate: c}), do: Cfdi.Csd.Certificate.is_csd?(c)
end
