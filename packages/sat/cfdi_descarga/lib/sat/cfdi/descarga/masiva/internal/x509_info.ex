defmodule Sat.Cfdi.Descarga.Masiva.Internal.X509Info do
  @moduledoc false

  alias Sat.Certificados.Certificate

  @doc """
  Issuer del certificado en formato RFC 2253 (`CN=...,O=...,OU=...`),
  con los componentes en el orden inverso al ASN.1 (de hoja a raiz).
  """
  @spec issuer_name(Certificate.t()) :: String.t()
  def issuer_name(%Certificate{} = cert) do
    cert
    |> Certificate.issuer()
    |> issuer_attribute_order()
    |> Enum.map(fn {k, v} -> "#{k}=#{escape_rfc2253(v)}" end)
    |> Enum.join(",")
  end

  @doc """
  Numero de serie del certificado en decimal (string).
  El X509SerialNumber del XMLDSig requiere formato decimal.
  """
  @spec serial_number_decimal(Certificate.t()) :: String.t()
  def serial_number_decimal(%Certificate{} = cert) do
    hex = Certificate.serial_number(cert)
    {int, _} = Integer.parse(hex, 16)
    Integer.to_string(int)
  end

  @doc """
  Certificado en base64 (DER) sin saltos de linea — formato esperado por
  `o:BinarySecurityToken` y `ds:X509Certificate`.
  """
  @spec der_base64(Certificate.t()) :: String.t()
  def der_base64(%Certificate{} = cert) do
    cert
    |> Certificate.to_der()
    |> Base.encode64()
  end

  defp issuer_attribute_order(map) do
    preferred = ~w(CN OU O L ST C STREET emailAddress serialNumber x500UniqueIdentifier)

    ordered =
      preferred
      |> Enum.flat_map(fn k -> if map[k], do: [{k, map[k]}], else: [] end)

    extras =
      map
      |> Enum.reject(fn {k, _} -> k in preferred end)
      |> Enum.sort()

    ordered ++ extras
  end

  defp escape_rfc2253(value) when is_binary(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace(",", "\\,")
    |> String.replace("+", "\\+")
    |> String.replace("\"", "\\\"")
    |> String.replace(">", "\\>")
    |> String.replace("<", "\\<")
    |> String.replace(";", "\\;")
    |> String.replace("=", "\\=")
  end
end
