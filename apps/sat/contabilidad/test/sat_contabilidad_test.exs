defmodule Sat.ContabilidadTest do
  use ExUnit.Case, async: true

  alias Sat.Contabilidad.Types.{ContribuyenteInfo, CuentaBalanza}
  alias Sat.Contabilidad.Xml.Balanza

  test "build balanza XML" do
    info = %ContribuyenteInfo{rfc: "AAA010101AAA", mes: "01", anio: 2024, tipo_envio: :normal}

    cuentas = [
      %CuentaBalanza{num_cta: "1000", saldo_ini: 100.0, debe: 50.0, haber: 30.0, saldo_fin: 120.0}
    ]

    xml = Balanza.build(info, cuentas)
    assert xml =~ "BCE:Balanza"
    assert xml =~ "AAA010101AAA"
    assert xml =~ "1000"
  end
end
