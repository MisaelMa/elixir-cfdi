defmodule Sat.Catalogos.Codegen.AtomNamerTest do
  use ExUnit.Case, async: true

  alias Sat.Catalogos.Codegen.AtomNamer

  test "plain ASCII single word" do
    assert AtomNamer.normalize("Efectivo") == :efectivo
  end

  test "plain ASCII multi-word with spaces" do
    assert AtomNamer.normalize("Cheque nominativo") == :cheque_nominativo
  end

  test "Spanish accents (á, é, í, ó, ú, ñ) are stripped" do
    assert AtomNamer.normalize("Régimen Simplificado de Confianza") ==
             :regimen_simplificado_de_confianza

    assert AtomNamer.normalize("Pago en una sola exhibición") ==
             :pago_en_una_sola_exhibicion
  end

  test "uppercase letters are downcased" do
    assert AtomNamer.normalize("UPPERCASE") == :uppercase
    assert AtomNamer.normalize("CamelCase") == :camelcase
  end

  test "special characters (slashes, parens, dots) become underscores" do
    assert AtomNamer.normalize("Con/slash") == :con_slash
    assert AtomNamer.normalize("Con(parens)") == :con_parens
    assert AtomNamer.normalize("Fin.punto") == :fin_punto
  end

  test "multiple consecutive spaces collapse to single underscore" do
    assert AtomNamer.normalize("Multiple  Spaces") == :multiple_spaces
  end

  test "leading and trailing whitespace is trimmed" do
    assert AtomNamer.normalize("  Spaces  Around  ") == :spaces_around
  end

  test "idempotence: normalize(to_string(normalize(s))) == normalize(s)" do
    inputs = [
      "Efectivo",
      "Cheque nominativo",
      "Régimen Simplificado de Confianza",
      "Pago en una sola exhibición",
      "Con/slash"
    ]

    for input <- inputs do
      result = AtomNamer.normalize(input)
      assert AtomNamer.normalize(to_string(result)) == result,
             "idempotence failed for #{inspect(input)}: got #{inspect(result)}"
    end
  end
end
