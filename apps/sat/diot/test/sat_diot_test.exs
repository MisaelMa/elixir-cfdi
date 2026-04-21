defmodule Sat.DiotTest do
  use ExUnit.Case, async: true

  alias Sat.Diot.Builders.DiotTxt
  alias Sat.Diot.Types.{Declaracion, OperacionTercero}

  test "build empty declaration returns empty string" do
    assert DiotTxt.build(%Declaracion{rfc: "AAA", ejercicio: 2024, periodo: 1}) == ""
  end

  test "build declaration with operations" do
    decl = %Declaracion{
      rfc: "AAA010101AAA",
      ejercicio: 2024,
      periodo: 1,
      operaciones: [
        %OperacionTercero{
          tipo_tercero: :proveedor_nacional,
          tipo_operacion: :otros_con_iva,
          rfc: "BBB020202BBB",
          monto_iva_16: 1600.0,
          monto_iva_0: 0.0,
          monto_exento: 0.0,
          monto_retenido: 0.0,
          monto_iva_no_deduc: 0.0
        }
      ]
    }

    result = DiotTxt.build(decl)
    assert result =~ "04|03|BBB020202BBB"
    assert result =~ "1600.00"
  end
end
