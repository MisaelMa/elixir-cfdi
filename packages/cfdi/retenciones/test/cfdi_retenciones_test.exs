defmodule Cfdi.RetencionesTest do
  use ExUnit.Case, async: true

  alias Cfdi.Retenciones.Types.{Retencion20, EmisorRetencion, ReceptorRetencion, ReceptorNacional, PeriodoRetencion, TotalesRetencion}
  alias Cfdi.Retenciones.Builders.Retencion20, as: Builder

  test "build retencion20 XML" do
    doc = %Retencion20{
      cve_retenc: "14",
      fecha_exp: "2024-01-15T10:00:00",
      lugar_exp_ret: "06600",
      emisor: %EmisorRetencion{rfc: "AAA010101AAA", regimen_fiscal_e: "601"},
      receptor: %ReceptorRetencion{
        nacionalidad_r: "Nacional",
        nacional: %ReceptorNacional{rfc_recep: "BBB020202BBB"}
      },
      periodo: %PeriodoRetencion{mes_ini: "01", mes_fin: "12", ejerc: "2024"},
      totales: %TotalesRetencion{
        monto_tot_operacion: "10000.00",
        monto_tot_grav: "8000.00",
        monto_tot_exent: "2000.00",
        monto_tot_ret: "1000.00"
      }
    }

    xml = Builder.build(doc)
    assert xml =~ "retenciones:Retenciones"
    assert xml =~ "AAA010101AAA"
    assert xml =~ "BBB020202BBB"
    assert xml =~ "Version=\"2.0\""
  end
end
