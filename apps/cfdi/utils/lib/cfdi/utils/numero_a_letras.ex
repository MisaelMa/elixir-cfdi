defmodule Cfdi.Utils.NumeroALetras do
  @moduledoc """
  Convierte números a su representación en letras (español) para montos de CFDI.
  """

  @type currency :: %{
          plural: String.t(),
          singular: String.t(),
          cent_plural: String.t(),
          cent_singular: String.t()
        }

  @default_currency %{
    plural: "PESOS",
    singular: "PESO",
    cent_plural: "CENTAVOS",
    cent_singular: "CENTAVO"
  }

  @spec convert(number(), currency()) :: String.t()
  def convert(num, currency \\ @default_currency) do
    enteros = trunc(num)
    centavos = round((num * 100 - enteros * 100)) |> abs()

    letras_centavos =
      cond do
        centavos > 0 and centavos < 10 ->
          "0#{centavos}/100 M.N"

        centavos > 0 ->
          "#{centavos}/100 M.N"

        true ->
          "00/100"
      end

    cond do
      enteros == 0 ->
        "CERO #{currency.plural} #{letras_centavos}"

      enteros == 1 ->
        "#{millones(enteros)} #{currency.singular} #{letras_centavos}"

      true ->
        "#{millones(enteros)} #{currency.plural} #{letras_centavos}"
    end
  end

  defp unidades(num) do
    case num do
      1 -> "UN"
      2 -> "DOS"
      3 -> "TRES"
      4 -> "CUATRO"
      5 -> "CINCO"
      6 -> "SEIS"
      7 -> "SIETE"
      8 -> "OCHO"
      9 -> "NUEVE"
      _ -> ""
    end
  end

  defp decenas(num) do
    decena = div(num, 10)
    unidad = num - decena * 10

    case decena do
      1 ->
        case unidad do
          0 -> "DIEZ"
          1 -> "ONCE"
          2 -> "DOCE"
          3 -> "TRECE"
          4 -> "CATORCE"
          5 -> "QUINCE"
          _ -> "DIECI" <> unidades(unidad)
        end

      2 ->
        case unidad do
          0 -> "VEINTE"
          _ -> "VEINTI" <> unidades(unidad)
        end

      3 -> decenas_y("TREINTA", unidad)
      4 -> decenas_y("CUARENTA", unidad)
      5 -> decenas_y("CINCUENTA", unidad)
      6 -> decenas_y("SESENTA", unidad)
      7 -> decenas_y("SETENTA", unidad)
      8 -> decenas_y("OCHENTA", unidad)
      9 -> decenas_y("NOVENTA", unidad)
      0 -> unidades(unidad)
      _ -> ""
    end
  end

  defp decenas_y(str_sin, num_unidades) do
    if num_unidades > 0,
      do: str_sin <> " Y " <> unidades(num_unidades),
      else: str_sin
  end

  defp centenas(num) do
    c = div(num, 100)
    d = num - c * 100

    case c do
      1 -> if d > 0, do: "CIENTO " <> decenas(d), else: "CIEN"
      2 -> "DOSCIENTOS " <> decenas(d)
      3 -> "TRESCIENTOS " <> decenas(d)
      4 -> "CUATROCIENTOS " <> decenas(d)
      5 -> "QUINIENTOS " <> decenas(d)
      6 -> "SEISCIENTOS " <> decenas(d)
      7 -> "SETECIENTOS " <> decenas(d)
      8 -> "OCHOCIENTOS " <> decenas(d)
      9 -> "NOVECIENTOS " <> decenas(d)
      _ -> decenas(d)
    end
  end

  defp seccion(num, divisor, str_singular, str_plural) do
    cientos = div(num, divisor)

    cond do
      cientos > 1 -> centenas(cientos) <> " " <> str_plural
      cientos == 1 -> str_singular
      true -> ""
    end
  end

  defp miles(num) do
    divisor = 1000
    resto = num - div(num, divisor) * divisor

    str_miles = seccion(num, divisor, "UN MIL", "MIL")
    str_centenas = centenas(resto)

    if str_miles == "",
      do: str_centenas,
      else: String.trim(str_miles <> " " <> str_centenas)
  end

  defp millones(num) do
    divisor = 1_000_000
    resto = num - div(num, divisor) * divisor

    str_millones = seccion(num, divisor, "UN MILLON DE", "MILLONES DE")
    str_miles = miles(resto)

    if str_millones == "",
      do: str_miles,
      else: String.trim(str_millones <> " " <> str_miles)
  end
end
