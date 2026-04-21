defmodule Clir.Openssl.Pkcs8 do
  @moduledoc """
  Conversión y lectura de llaves privadas en formato PKCS#8 / tradicional RSA (PEM/DER).

  La contraseña se pasa como charlist a `:public_key.pem_entry_decode/2` cuando aplica.
  """

  @doc """
  Convierte una llave privada en DER a PEM (sin cifrar la salida).

  Si `der_binary` es PKCS#8 cifrado, `password` descifra la entrada.
  """
  @spec to_pem(binary(), String.t() | nil) :: {:ok, String.t()} | {:error, term()}
  def to_pem(der_binary, password \\ nil) when is_binary(der_binary) do
    password = normalize_password(password)

    case decode_private_der(der_binary, password) do
      {:ok, decoded} ->
        {:ok, encode_decoded_to_pem!(decoded)}

      {:error, _} ->
        openssl_pkcs8_to_pem(der_binary, password)
    end
  end

  @doc """
  Extrae la llave privada decodificada desde PEM (tupla interna OTP, p. ej. `RSAPrivateKey` o `PrivateKeyInfo`).
  """
  @spec from_pem(String.t(), String.t() | nil) :: {:ok, term()} | {:error, term()}
  def from_pem(pem_string, password \\ nil) when is_binary(pem_string) do
    password = normalize_password(password)

    with {:ok, entries} <- pem_decode_all(pem_string),
         {:ok, decoded} <- decode_first_private_entry(entries, password) do
      {:ok, decoded}
    end
  end

  @doc """
  Lee un archivo de llave (PEM o DER), opcionalmente descifrado con `password`, y devuelve el PEM normalizado (sin cifrar).
  """
  @spec get_data(String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, term()}
  def get_data(key_path, password \\ nil) do
    password = normalize_password(password)

    with {:ok, bin} <- file_read(key_path) do
      cond do
        pem_like?(bin) ->
          with {:ok, decoded} <- from_pem(bin, password) do
            {:ok, encode_decoded_to_pem!(decoded)}
          end

        true ->
          to_pem(bin, password)
      end
    end
  end

  defp normalize_password(nil), do: nil
  defp normalize_password(""), do: nil
  defp normalize_password(s) when is_binary(s), do: s

  defp pem_like?(bin) do
    sample = binary_part(bin, 0, min(byte_size(bin), 32))
    String.contains?(sample, "-----")
  end

  defp file_read(path) do
    case File.read(path) do
      {:ok, bin} -> {:ok, bin}
      {:error, reason} -> {:error, {:read_failed, path, reason}}
    end
  end

  defp pem_decode_all(pem) do
    entries = :public_key.pem_decode(pem)

    if entries == [] do
      {:error, :no_pem_entries}
    else
      {:ok, entries}
    end
  end

  defp decode_first_private_entry(entries, password) do
    pw = to_charlist_password(password)

    result =
      Enum.find_value(entries, fn entry ->
        case safe_pem_entry_decode(entry, pw) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> nil
        end
      end)

    if result, do: result, else: {:error, :unsupported_pem}
  end

  defp safe_pem_entry_decode(entry, password) do
    try do
      {:ok, :public_key.pem_entry_decode(entry, password)}
    rescue
      _ -> {:error, :decode_failed}
    catch
      :error, _ -> {:error, :decode_failed}
    end
  end

  defp decode_private_der(der, password) do
    pw = to_charlist_password(password)

    cond do
      good?(try_decode(:PrivateKeyInfo, der)) ->
        unwrap_ok(try_decode(:PrivateKeyInfo, der))

      good?(try_decode(:RSAPrivateKey, der)) ->
        unwrap_ok(try_decode(:RSAPrivateKey, der))

      good?(try_decode(:EncryptedPrivateKeyInfo, der)) ->
        decode_encrypted_pkcs8_der(der, pw)

      true ->
        {:error, :unknown_der}
    end
  end

  defp good?({:ok, _}), do: true
  defp good?(_), do: false

  defp unwrap_ok({:ok, v}), do: {:ok, v}

  defp try_decode(type, der) do
    try do
      {:ok, :public_key.der_decode(type, der)}
    rescue
      _ -> {:error, :decode_failed}
    catch
      :error, _ -> {:error, :decode_failed}
    end
  end

  defp decode_encrypted_pkcs8_der(der, password) when is_list(password) do
    try do
      fake_pem =
        :public_key.pem_encode([
          {:EncryptedPrivateKeyInfo, der, :not_encrypted}
        ])

      [entry] = :public_key.pem_decode(fake_pem)
      {:ok, :public_key.pem_entry_decode(entry, password)}
    rescue
      _ -> {:error, :decode_failed}
    catch
      :error, _ -> {:error, :decode_failed}
    end
  end

  defp encode_decoded_to_pem!(term) do
    cond do
      match?({:PrivateKeyInfo, _, _, _, _}, term) ->
        der = :public_key.der_encode(:PrivateKeyInfo, term)
        :public_key.pem_encode([{:PrivateKeyInfo, der, :not_encrypted}])

      match?({:RSAPrivateKey, _, _, _, _, _, _, _, _}, term) ->
        der = :public_key.der_encode(:RSAPrivateKey, term)
        :public_key.pem_encode([{:RSAPrivateKey, der, :not_encrypted}])

      true ->
        raise ArgumentError, "llave decodificada no soportada (se esperaba RSA PKCS#1 o PKCS#8)"
    end
  end

  defp to_charlist_password(nil), do: ''
  defp to_charlist_password(s) when is_binary(s), do: String.to_charlist(s)

  defp openssl_pkcs8_to_pem(der, password) do
    tmp_in = Path.join(System.tmp_dir!(), "clir_pkcs8_in_#{:erlang.unique_integer([:positive])}")
    tmp_out = Path.join(System.tmp_dir!(), "clir_pkcs8_out_#{:erlang.unique_integer([:positive])}")

    try do
      :ok = File.write!(tmp_in, der)

      args =
        [
          "pkcs8",
          "-inform",
          "DER",
          "-in",
          tmp_in,
          "-outform",
          "PEM",
          "-out",
          tmp_out,
          "-nocrypt"
        ] ++ openssl_pass_args(password)

      case System.cmd("openssl", args, stderr_to_stdout: true) do
        {_out, 0} ->
          {:ok, File.read!(tmp_out)}

        {out, code} ->
          {:error, {:openssl_pkcs8, code, out}}
      end
    after
      File.rm(tmp_in)
      File.rm(tmp_out)
    end
  end

  defp openssl_pass_args(nil), do: []

  defp openssl_pass_args(password) when is_binary(password) do
    ["-passin", "pass:#{password}"]
  end
end
