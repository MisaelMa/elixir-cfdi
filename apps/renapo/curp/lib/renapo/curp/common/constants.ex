defmodule Renapo.Curp.Common.Constants do
  @moduledoc false

  @curp_regex "[A-Z][AEIXOU][A-Z]{2}[0-9]{2}(0[1-9]|1[0-2])(0[1-9]|1[0-9]|2[0-9]|3[0-1])" <>
                "[HM](AS|BC|BS|CC|CS|CH|CL|CM|DF|DG|GT|GR|HG|JC|MC|MN|MS|NT|NL|OC|PL|QT|QR|SP|SL|SR|TC|TS|TL|VZ|YN|ZS|NE)" <>
                "[B-DF-HJ-NP-TV-Z]{3}[0-9A-Z][0-9]"

  @curp_pattern Regex.compile!("^#{@curp_regex}$", "u")

  def regex_curp_string, do: @curp_regex

  @doc "String form of the official CURP pattern (cf. `REGEX_CURP` in other SDKs)."
  def regex_curp, do: @curp_regex

  def regex_curp!, do: @curp_pattern

  def compile_regex_curp, do: {:ok, @curp_pattern}

  def curp_re, do: @curp_pattern

  @forbidden_words ~w(
    BACA BAKA BUEI BUEY CACA CACO CAGA CAGO CAKA CAKO COGE COGI COJA COJE COJI COJO COLA CULO
    FALO FETO GETA GUEI GUEY JETA JOTO KACA KACO KAGA KAGO KAKA KAKO KOGE KOGI KOJA KOJE KOJI KOJO KOLA KULO
    LILO LOCA LOCO LOKA LOKO MAME MAMO MEAR MEAS MEON MIAR MION MOCO MOKO MULA MULO NACA NACO PEDA PEDO PENE
    PIPI PITO POPO PUTA PUTO QULO RATA ROBA ROBE ROBO RUIN SENO TETA VACA VAGA VAGO VAKA VUEI VUEY WUEI WUEY
  )

  def forbidden_words, do: @forbidden_words

  def forbidden_set, do: MapSet.new(@forbidden_words)

  @states %{
    "AS" => "Aguascalientes",
    "BC" => "Baja California",
    "BS" => "Baja California Sur",
    "CC" => "Campeche",
    "CL" => "Coahuila",
    "CM" => "Colima",
    "CS" => "Chiapas",
    "CH" => "Chihuahua",
    "DF" => "Ciudad de México",
    "DG" => "Durango",
    "GT" => "Guanajuato",
    "GR" => "Guerrero",
    "HG" => "Hidalgo",
    "JC" => "Jalisco",
    "MC" => "Estado de México",
    "MN" => "Michoacán",
    "MS" => "Morelos",
    "NT" => "Nayarit",
    "NL" => "Nuevo León",
    "OC" => "Oaxaca",
    "PL" => "Puebla",
    "QT" => "Querétaro",
    "QR" => "Quintana Roo",
    "SP" => "San Luis Potosí",
    "SL" => "Sinaloa",
    "SR" => "Sonora",
    "TC" => "Tabasco",
    "TS" => "Tamaulipas",
    "TL" => "Tlaxcala",
    "VZ" => "Veracruz",
    "YN" => "Yucatán",
    "ZS" => "Zacatecas",
    "NE" => "Nacido en el extranjero"
  }

  def state_map, do: @states

  @err_invalid_format :invalid_curp_format
  @err_bad_check_digit :bad_check_digit
  @err_forbidden :forbidden_sequence
  @err_bad_state :invalid_birth_entity
  @err_bad_date :invalid_birth_date

  def error_invalid_format, do: @err_invalid_format
  def error_bad_check_digit, do: @err_bad_check_digit
  def error_forbidden, do: @err_forbidden
  def error_bad_state, do: @err_bad_state
  def error_bad_date, do: @err_bad_date

  @doc """
  `yy_mm_dd` is the 6-digit fragment from CURP positions 5-10 (YYMMDD).
  Uses century pivot 20YY; adjust if you need 19YY for centenarians.
  """
  @spec parse_curp_birthdate(String.t()) :: {:ok, Date.t()} | {:error, term()}
  def parse_curp_birthdate(yy_mm_dd) when byte_size(yy_mm_dd) == 6 do
    <<yy::binary-size(2), mm::binary-size(2), dd::binary-size(2)>> = yy_mm_dd

    with {y, _} <- Integer.parse(yy),
         {m, _} <- Integer.parse(mm),
         {d, _} <- Integer.parse(dd),
         full_year <- 2000 + y,
         {:ok, date} <- Date.new(full_year, m, d) do
      {:ok, date}
    else
      _ -> {:error, @err_bad_date}
    end
  end

  def parse_curp_birthdate(_), do: {:error, @err_bad_date}
end
