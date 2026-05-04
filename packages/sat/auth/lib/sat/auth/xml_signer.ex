defmodule Sat.Auth.XmlSigner do
  @moduledoc false

  @doc """
  Exclusive C14N-style normalization sufficient for the SAT authentication `Timestamp` fragment.

  Removes XML declarations, normalizes newlines, sorts attributes on opening tags by name.
  """
  @spec canonicalize(String.t()) :: String.t()
  def canonicalize(xml_fragment) when is_binary(xml_fragment) do
    xml_fragment
    |> String.replace(~r/<\?xml[^?]*\?>\s*/, "")
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> Regex.replace(~r/<([a-zA-Z][^\s\/>]*)((?:\s+[^>]*)?)(\/?)>/, fn _full, tag, attrs, self_close ->
      attrs = String.trim(attrs || "")

      if attrs == "" do
        "<#{tag}#{self_close}>"
      else
        sorted =
          attrs
          |> parse_attributes()
          |> Enum.sort_by(&elem(&1, 0))
          |> Enum.map_join(" ", fn {k, v} -> ~s(#{k}="#{v}") end)

        "<#{tag} #{sorted}#{self_close}>"
      end
    end)
  end

  defp parse_attributes(attrs_str) do
    ~r/([a-zA-Z_:][\w:.-]*)=["']([^"']*)["']/
    |> Regex.scan(attrs_str, capture: :all_but_first)
    |> Enum.map(fn [k, v] -> {k, v} end)
  end

  @doc """
  SHA-256 digest of `data` (UTF-8), Base64-encoded.
  """
  @spec sha256_digest(iodata()) :: String.t()
  def sha256_digest(data) do
    data
    |> :erlang.iolist_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode64()
  end

  @doc """
  RSA-SHA256 PKCS#1 v1.5 signature of `data`, Base64-encoded.
  """
  @spec sign_rsa_sha256(iodata(), Cfdi.Csd.PrivateKey.t()) :: String.t()
  def sign_rsa_sha256(data, %Cfdi.Csd.PrivateKey{} = pk) do
    Cfdi.Csd.PrivateKey.sign(pk, data)
  end
end
