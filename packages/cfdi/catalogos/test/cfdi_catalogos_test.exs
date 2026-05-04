defmodule Cfdi.CatalogosTest do
  use ExUnit.Case, async: true

  alias Cfdi.Catalogos.{
    FormaPago,
    MetodoPago,
    TipoComprobante,
    Impuesto,
    UsoCFDI,
    Exportacion,
    Moneda,
    RegimenFiscal,
    Periodicidad,
    Meses,
    TipoRelacion,
    ObjetoImp,
    TipoFactor,
    Pais,
    Estado
  }

  # ─── Atom-bearing catalogs ───────────────────────────────────────────────────

  describe "FormaPago" do
    test "list/0 returns 22 entries" do
      assert length(FormaPago.list()) == 22
    end

    test "list/0 entries have required keys" do
      [first | _] = FormaPago.list()
      assert Map.has_key?(first, :value)
      assert Map.has_key?(first, :code)
      assert Map.has_key?(first, :label)
      assert Map.has_key?(first, :deprecated)
    end

    test "valid?/1 accepts known string code" do
      assert FormaPago.valid?("01")
      assert FormaPago.valid?("99")
    end

    test "valid?/1 rejects unknown code" do
      refute FormaPago.valid?("ZZ")
      refute FormaPago.valid?("00")
    end

    test "valid?/1 rejects non-string" do
      refute FormaPago.valid?(1)
      refute FormaPago.valid?(:efectivo)
      refute FormaPago.valid?(nil)
    end

    test "value/1 converts atom to string code" do
      assert FormaPago.value(:efectivo) == "01"
      assert FormaPago.value(:transferencia_electronica) == "03"
      assert FormaPago.value(:por_definir) == "99"
    end

    test "value/1 returns nil for unknown atom" do
      assert FormaPago.value(:unknown) == nil
    end

    test "from_code/1 returns full entry map" do
      assert {:ok, %{value: :efectivo, code: "01", label: "Efectivo", deprecated: false}} =
               FormaPago.from_code("01")
    end

    test "from_code/1 returns :error for unknown code" do
      assert :error = FormaPago.from_code("ZZ")
      assert :error = FormaPago.from_code("")
    end
  end

  describe "MetodoPago" do
    test "list/0 returns 2 entries" do
      assert length(MetodoPago.list()) == 2
    end

    test "valid?/1 accepts known string codes" do
      assert MetodoPago.valid?("PUE")
      assert MetodoPago.valid?("PPD")
    end

    test "valid?/1 rejects invalid code" do
      refute MetodoPago.valid?("PUF")
      refute MetodoPago.valid?(:pago_en_una_exhibicion)
    end

    test "value/1 converts atom to code" do
      assert MetodoPago.value(:pago_en_una_exhibicion) == "PUE"
      assert MetodoPago.value(:pago_en_parcialidades_diferido) == "PPD"
    end

    test "from_code/1 returns full entry map" do
      assert {:ok, %{value: :pago_en_una_exhibicion, code: "PUE", label: _, deprecated: false}} =
               MetodoPago.from_code("PUE")
    end

    test "from_code/1 returns error for unknown code" do
      assert :error = MetodoPago.from_code("PUF")
    end
  end

  describe "TipoComprobante" do
    test "list/0 returns 5 entries" do
      assert length(TipoComprobante.list()) == 5
    end

    test "valid?/1 accepts known string codes" do
      assert TipoComprobante.valid?("I")
      assert TipoComprobante.valid?("P")
    end

    test "valid?/1 rejects non-string" do
      refute TipoComprobante.valid?(:ingreso)
      refute TipoComprobante.valid?(nil)
    end

    test "value/1 converts atom to code" do
      assert TipoComprobante.value(:ingreso) == "I"
      assert TipoComprobante.value(:pago) == "P"
    end

    test "from_code/1 returns full entry map" do
      assert {:ok, %{value: :ingreso, code: "I", label: "Ingreso", deprecated: false}} =
               TipoComprobante.from_code("I")
    end

    test "from_code/1 returns error for unknown code" do
      assert :error = TipoComprobante.from_code("X")
    end
  end

  describe "Impuesto" do
    test "list/0 returns 3 entries" do
      assert length(Impuesto.list()) == 3
    end

    test "valid?/1 accepts known string codes" do
      assert Impuesto.valid?("001")
      assert Impuesto.valid?("002")
      assert Impuesto.valid?("003")
    end

    test "valid?/1 rejects unknown code" do
      refute Impuesto.valid?("004")
      refute Impuesto.valid?(:iva)
    end

    test "value/1 converts atom to code" do
      assert Impuesto.value(:isr) == "001"
      assert Impuesto.value(:iva) == "002"
      assert Impuesto.value(:ieps) == "003"
    end

    test "from_code/1 returns full entry map" do
      assert {:ok, %{value: :iva, code: "002", label: "IVA", deprecated: false}} =
               Impuesto.from_code("002")
    end

    test "from_code/1 returns error for unknown code" do
      assert :error = Impuesto.from_code("004")
    end
  end

  describe "UsoCFDI" do
    test "list/0 returns 25 entries" do
      assert length(UsoCFDI.list()) == 25
    end

    test "valid?/1 accepts known string codes" do
      assert UsoCFDI.valid?("G03")
      assert UsoCFDI.valid?("G01")
      assert UsoCFDI.valid?("P01")
      assert UsoCFDI.valid?("S01")
    end

    test "valid?/1 rejects invalid code" do
      refute UsoCFDI.valid?("ZZ")
      refute UsoCFDI.valid?(:gastos_en_general)
    end

    test "value/1 converts atom to code" do
      assert UsoCFDI.value(:gastos_en_general) == "G03"
      assert UsoCFDI.value(:por_definir) == "P01"
    end

    test "from_code/1 returns full entry map for deprecated entry" do
      assert {:ok, %{value: :por_definir, code: "P01", label: "Por definir", deprecated: true}} =
               UsoCFDI.from_code("P01")
    end

    test "from_code/1 returns error for unknown code" do
      assert :error = UsoCFDI.from_code("ZZ")
    end
  end

  describe "Exportacion" do
    test "list/0 returns 4 entries" do
      assert length(Exportacion.list()) == 4
    end

    test "valid?/1 accepts known string codes" do
      assert Exportacion.valid?("01")
      assert Exportacion.valid?("02")
    end

    test "valid?/1 rejects invalid code" do
      refute Exportacion.valid?("05")
      refute Exportacion.valid?(:no_aplica)
    end

    test "value/1 converts atom to code" do
      assert Exportacion.value(:no_aplica) == "01"
      assert Exportacion.value(:definitiva) == "02"
    end

    test "from_code/1 returns full entry map" do
      assert {:ok, %{value: :no_aplica, code: "01", label: "No aplica", deprecated: false}} =
               Exportacion.from_code("01")
    end

    test "from_code/1 returns error for unknown code" do
      assert :error = Exportacion.from_code("99")
    end
  end

  describe "Moneda" do
    test "list/0 returns 183 entries" do
      assert length(Moneda.list()) == 183
    end

    test "valid?/1 accepts known string code" do
      assert Moneda.valid?("MXN")
      assert Moneda.valid?("USD")
    end

    test "valid?/1 rejects invalid code" do
      refute Moneda.valid?("XYZ")
      refute Moneda.valid?(:MXN)
    end

    test "value/1 converts atom to string code (code-as-atom)" do
      assert Moneda.value(:MXN) == "MXN"
      assert Moneda.value(:USD) == "USD"
    end

    test "value/1 returns nil for unknown atom" do
      assert Moneda.value(:UNKNOWN) == nil
    end

    test "from_code/1 returns full entry map" do
      assert {:ok, %{value: :MXN, code: "MXN", label: "Peso Mexicano", deprecated: false}} =
               Moneda.from_code("MXN")
    end

    test "from_code/1 returns error for unknown code" do
      assert :error = Moneda.from_code("XYZ")
    end
  end

  # ─── String-only catalogs ────────────────────────────────────────────────────

  describe "RegimenFiscal" do
    test "list/0 returns 23 entries" do
      assert length(RegimenFiscal.list()) == 23
    end

    test "list/0 entries include persona_fisica and persona_moral booleans" do
      entry_601 = Enum.find(RegimenFiscal.list(), &(&1.value == "601"))
      assert is_boolean(entry_601.persona_fisica)
      assert is_boolean(entry_601.persona_moral)
    end

    test "list/0 entries include inicio_vigencia as Date.t() or nil" do
      entry_601 = Enum.find(RegimenFiscal.list(), &(&1.value == "601"))
      assert %Date{} = entry_601.inicio_vigencia

      entry_609 = Enum.find(RegimenFiscal.list(), &(&1.value == "609"))
      assert is_nil(entry_609.inicio_vigencia)
    end

    test "list/0 entries include fin_vigencia as nil for active entries" do
      entry_601 = Enum.find(RegimenFiscal.list(), &(&1.value == "601"))
      assert is_nil(entry_601.fin_vigencia)
    end

    test "valid?/1 accepts known string codes" do
      assert RegimenFiscal.valid?("601")
      assert RegimenFiscal.valid?("626")
    end

    test "valid?/1 accepts deprecated codes (still valid catalog entries)" do
      assert RegimenFiscal.valid?("609")
    end

    test "valid?/1 rejects non-string" do
      refute RegimenFiscal.valid?(601)
      refute RegimenFiscal.valid?(nil)
      refute RegimenFiscal.valid?(:resico)
    end

    test "valid?/1 rejects unknown code" do
      refute RegimenFiscal.valid?("999")
    end

    test "626 (RESICO) is present" do
      assert RegimenFiscal.valid?("626")
      assert {:ok, %{value: "626", label: "Régimen Simplificado de Confianza"}} =
               RegimenFiscal.from_code("626")
    end

    test "from_code/1 returns full entry map with all extra fields" do
      assert {:ok,
              %{
                value: "601",
                label: "General de Ley Personas Morales",
                persona_fisica: false,
                persona_moral: true,
                inicio_vigencia: %Date{},
                fin_vigencia: nil,
                deprecated: false
              }} = RegimenFiscal.from_code("601")
    end

    test "from_code/1 returns deprecated entry with correct flags" do
      assert {:ok, %{value: "609", deprecated: true, persona_fisica: false, persona_moral: false}} =
               RegimenFiscal.from_code("609")
    end

    test "from_code/1 returns error for unknown code" do
      assert :error = RegimenFiscal.from_code("999")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(RegimenFiscal, :value, 1)
    end
  end

  describe "Periodicidad" do
    test "list/0 returns 5 entries" do
      assert length(Periodicidad.list()) == 5
    end

    test "valid?/1 accepts known string code" do
      assert Periodicidad.valid?("01")
      assert Periodicidad.valid?("05")
    end

    test "valid?/1 rejects invalid input" do
      refute Periodicidad.valid?("06")
      refute Periodicidad.valid?(1)
    end

    test "from_code/1 returns entry map" do
      assert {:ok, %{value: "01", label: "Diario", deprecated: false}} =
               Periodicidad.from_code("01")
    end

    test "from_code/1 returns error for unknown" do
      assert :error = Periodicidad.from_code("99")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(Periodicidad, :value, 1)
    end
  end

  describe "Meses" do
    test "list/0 returns 18 entries" do
      assert length(Meses.list()) == 18
    end

    test "valid?/1 accepts known string code" do
      assert Meses.valid?("01")
      assert Meses.valid?("12")
      assert Meses.valid?("18")
    end

    test "valid?/1 rejects invalid input" do
      refute Meses.valid?("19")
      refute Meses.valid?(1)
    end

    test "from_code/1 returns entry map" do
      assert {:ok, %{value: "01", label: "Enero", deprecated: false}} = Meses.from_code("01")
    end

    test "from_code/1 returns error for unknown" do
      assert :error = Meses.from_code("99")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(Meses, :value, 1)
    end
  end

  describe "TipoRelacion" do
    test "list/0 returns 9 entries" do
      assert length(TipoRelacion.list()) == 9
    end

    test "valid?/1 accepts known string code" do
      assert TipoRelacion.valid?("01")
      assert TipoRelacion.valid?("07")
    end

    test "valid?/1 accepts deprecated codes (still valid catalog entries)" do
      assert TipoRelacion.valid?("08")
      assert TipoRelacion.valid?("09")
    end

    test "valid?/1 rejects invalid input" do
      refute TipoRelacion.valid?("10")
      refute TipoRelacion.valid?(1)
    end

    test "from_code/1 returns entry map" do
      assert {:ok,
              %{
                value: "01",
                label: "Nota de crédito de los documentos relacionados",
                deprecated: false
              }} = TipoRelacion.from_code("01")
    end

    test "from_code/1 returns deprecated entry for 08" do
      assert {:ok, %{value: "08", deprecated: true}} = TipoRelacion.from_code("08")
    end

    test "from_code/1 returns error for unknown" do
      assert :error = TipoRelacion.from_code("10")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(TipoRelacion, :value, 1)
    end
  end

  describe "ObjetoImp" do
    test "list/0 returns 8 entries" do
      assert length(ObjetoImp.list()) == 8
    end

    test "valid?/1 accepts known string code" do
      assert ObjetoImp.valid?("01")
      assert ObjetoImp.valid?("02")
    end

    test "valid?/1 rejects invalid input" do
      refute ObjetoImp.valid?("09")
      refute ObjetoImp.valid?(1)
    end

    test "from_code/1 returns entry map" do
      assert {:ok, %{value: "01", label: "No objeto de impuesto.", deprecated: false}} =
               ObjetoImp.from_code("01")
    end

    test "from_code/1 returns error for unknown" do
      assert :error = ObjetoImp.from_code("99")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(ObjetoImp, :value, 1)
    end
  end

  describe "TipoFactor" do
    test "list/0 returns 3 entries" do
      assert length(TipoFactor.list()) == 3
    end

    test "valid?/1 accepts known string values" do
      assert TipoFactor.valid?("Tasa")
      assert TipoFactor.valid?("Cuota")
      assert TipoFactor.valid?("Exento")
    end

    test "valid?/1 rejects invalid input" do
      refute TipoFactor.valid?("tasa")
      refute TipoFactor.valid?(nil)
    end

    test "from_code/1 returns entry map (code is the value itself)" do
      assert {:ok, %{value: "Tasa", label: "Tasa", deprecated: false}} =
               TipoFactor.from_code("Tasa")
    end

    test "from_code/1 returns error for unknown" do
      assert :error = TipoFactor.from_code("exento")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(TipoFactor, :value, 1)
    end
  end

  describe "Pais" do
    test "list/0 returns 250 entries" do
      assert length(Pais.list()) == 250
    end

    test "valid?/1 accepts known string codes" do
      assert Pais.valid?("MEX")
      assert Pais.valid?("USA")
    end

    test "valid?/1 rejects invalid input" do
      refute Pais.valid?("XYZ")
      refute Pais.valid?(nil)
    end

    test "from_code/1 returns entry map for MEX" do
      assert {:ok, %{value: "MEX", label: "México", deprecated: false}} = Pais.from_code("MEX")
    end

    test "from_code/1 returns error for unknown" do
      assert :error = Pais.from_code("XYZ")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(Pais, :value, 1)
    end
  end

  describe "Estado" do
    test "list/0 returns 96 entries" do
      assert length(Estado.list()) == 96
    end

    test "valid?/1 accepts known string code" do
      assert Estado.valid?("AGU")
      assert Estado.valid?("CMX")
    end

    test "valid?/1 accepts deprecated code DIF" do
      assert Estado.valid?("DIF")
    end

    test "valid?/1 rejects invalid input" do
      refute Estado.valid?("ZZZ")
      refute Estado.valid?(nil)
    end

    test "from_code/1 returns entry for AGU" do
      assert {:ok, %{value: "AGU", label: "Aguascalientes", deprecated: false}} =
               Estado.from_code("AGU")
    end

    test "from_code/1 returns deprecated entry for DIF" do
      assert {:ok, %{value: "DIF", label: "Distrito Federal", deprecated: true}} =
               Estado.from_code("DIF")
    end

    test "from_code/1 returns error for unknown" do
      assert :error = Estado.from_code("ZZZ")
    end

    test "no value/1 function (string-only catalog)" do
      refute function_exported?(Estado, :value, 1)
    end
  end
end
