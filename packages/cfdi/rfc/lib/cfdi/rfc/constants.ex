defmodule Cfdi.Rfc.Constants do
  @moduledoc false

  @rfc_regexp ~r/^([A-ZÑ&]{3,4})([0-9]{6})([A-Z0-9]{3})$/

  @rfc_type_for_length %{
    12 => "company",
    13 => "person"
  }

  @special_cases %{
    "XEXX010101000" => "foreign",
    "XAXX010101000" => "generic"
  }

  @forbidden_words ~w(
    BUEI BUEY CACA CACO CAGA CAGO CAKA CAKO COGE COJA COJE COJI COJO CULO
    FETO GUEY JOTO KACA KACO KAGA KAGO KOGE KOJO KAKA KULO MAME MAMO MEAR
    MEAS MEON MION MOCO MULA PEDA PEDO PENE PUTA PUTO QULO RATA RUIN
  )

  def rfc_regexp, do: @rfc_regexp
  def rfc_type_for_length, do: @rfc_type_for_length
  def special_cases, do: @special_cases
  def forbidden_words, do: @forbidden_words
end
