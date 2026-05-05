defmodule Sat.Certificados.Asn1 do
  @moduledoc false

  # Parser BER mínimo para inspeccionar respuestas OCSP del SAT sin depender
  # de tipos ASN.1 compilados. Suficiente para `Sat.Certificados.Ocsp`.

  import Bitwise

  @doc """
  Lee el siguiente TLV en `bin` y devuelve `{ {class, form, number}, content, rest }`.

  - `class` ∈ {0, 1, 2, 3} (universal, application, context-specific, private)
  - `form` ∈ {0, 1} (primitive / constructed)
  - `number` es el tag number — para tags universales devuelve el byte del tag
    completo (ej. SEQUENCE = 0x30 → number = 0x10) cuando es constructed.

  Esta función soporta solo low-tag-number form (tag <= 30).
  """
  @spec next(binary()) ::
          {{0..3, 0..1, non_neg_integer()}, binary(), binary()} | :error
  def next(<<tag_byte, rest::binary>>) do
    class = Bitwise.bsr(tag_byte, 6) &&& 0x03
    form = Bitwise.bsr(tag_byte, 5) &&& 0x01
    number = tag_byte &&& 0x1F
    {len, after_len} = read_length(rest)

    case after_len do
      <<content::binary-size(len), tail::binary>> ->
        {{class, form, number}, content, tail}

      _ ->
        :error
    end
  end

  def next(_), do: :error

  defp read_length(<<l, rest::binary>>) when l < 0x80, do: {l, rest}

  defp read_length(<<first, rest::binary>>) when first >= 0x80 do
    n = first - 0x80
    <<len_bytes::binary-size(n), tail::binary>> = rest
    {:binary.decode_unsigned(len_bytes), tail}
  end
end
