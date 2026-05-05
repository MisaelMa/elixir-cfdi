defmodule Sat.Catalogos.Codegen.CrossValidatorTest do
  use ExUnit.Case, async: true

  alias Sat.Catalogos.Codegen.CrossValidator

  @empty_overrides %{enum_names: %{}, descriptions: %{}}

  describe "reconcile/4 happy path" do
    test "all codes present in both XSD and XLSX: 3 entries, none deprecated, order preserved" do
      xsd_codes = ["01", "02", "03"]

      xlsx_rows = [
        %{code: "01", label: "Efectivo", ending_date: nil},
        %{code: "02", label: "Cheque nominativo", ending_date: nil},
        %{code: "03", label: "Transferencia electrónica", ending_date: nil}
      ]

      assert {:ok, entries} = CrossValidator.reconcile(xsd_codes, xlsx_rows, @empty_overrides, [])

      assert length(entries) == 3

      assert Enum.map(entries, & &1.value) == ["01", "02", "03"]

      assert Enum.all?(entries, fn e -> e.deprecated == false end)
    end
  end

  describe "reconcile/4 XLSX code not in XSD" do
    test "returns error when XLSX has a code absent from XSD" do
      xsd_codes = ["01", "02"]

      xlsx_rows = [
        %{code: "01", label: "Efectivo", ending_date: nil},
        %{code: "02", label: "Cheque", ending_date: nil},
        %{code: "99", label: "Extra", ending_date: nil}
      ]

      assert {:error, {:xlsx_code_not_in_xsd, "99"}} =
               CrossValidator.reconcile(xsd_codes, xlsx_rows, @empty_overrides, [])
    end
  end

  describe "reconcile/4 XSD code absent from XLSX" do
    test "XSD code not in XLSX and no override: entry with deprecated: true, label empty string" do
      xsd_codes = ["01", "02"]

      xlsx_rows = [
        %{code: "01", label: "Efectivo", ending_date: nil}
      ]

      assert {:ok, entries} = CrossValidator.reconcile(xsd_codes, xlsx_rows, @empty_overrides, [])

      assert length(entries) == 2
      deprecated = Enum.find(entries, &(&1.value == "02"))
      assert deprecated.deprecated == true
      assert deprecated.label == ""
    end

    test "XSD code not in XLSX with override description: entry uses override label" do
      xsd_codes = ["01", "99"]

      xlsx_rows = [
        %{code: "01", label: "Efectivo", ending_date: nil}
      ]

      overrides = %{enum_names: %{}, descriptions: %{"99" => "Por definir"}}

      assert {:ok, entries} = CrossValidator.reconcile(xsd_codes, xlsx_rows, overrides, [])

      deprecated = Enum.find(entries, &(&1.value == "99"))
      assert deprecated.deprecated == true
      assert deprecated.label == "Por definir"
    end
  end

  describe "reconcile/4 ending_date deprecation" do
    test "entry with past ending_date is marked deprecated: true" do
      xsd_codes = ["630"]
      past_date = ~D[2020-01-01]

      xlsx_rows = [
        %{code: "630", label: "Régimen antiguo", ending_date: past_date}
      ]

      assert {:ok, entries} = CrossValidator.reconcile(xsd_codes, xlsx_rows, @empty_overrides, [])

      assert [entry] = entries
      assert entry.deprecated == true
    end
  end

  describe "reconcile/4 emit_atoms validation" do
    test "emit_atoms: true with missing override entry returns error" do
      xsd_codes = ["01", "02"]

      xlsx_rows = [
        %{code: "01", label: "Efectivo", ending_date: nil},
        %{code: "02", label: "Cheque", ending_date: nil}
      ]

      # override only has "01", missing "02"
      overrides = %{enum_names: %{"01" => :efectivo}, descriptions: %{}}

      assert {:error, {:missing_atom_override, "02"}} =
               CrossValidator.reconcile(xsd_codes, xlsx_rows, overrides, emit_atoms: true)
    end
  end

  describe "reconcile/4 extra columns flow-through" do
    test "extra columns from XLSX rows are preserved in output entries" do
      xsd_codes = ["601"]

      xlsx_rows = [
        %{
          code: "601",
          label: "General de Ley Personas Morales",
          ending_date: nil,
          persona_fisica: false,
          persona_moral: true
        }
      ]

      assert {:ok, entries} = CrossValidator.reconcile(xsd_codes, xlsx_rows, @empty_overrides, [])

      assert [entry] = entries
      assert entry.persona_fisica == false
      assert entry.persona_moral == true
    end
  end

  describe "reconcile/4 order preservation" do
    test "output entries follow XSD code order, not XLSX order" do
      xsd_codes = ["03", "01", "02"]

      xlsx_rows = [
        %{code: "01", label: "Uno", ending_date: nil},
        %{code: "02", label: "Dos", ending_date: nil},
        %{code: "03", label: "Tres", ending_date: nil}
      ]

      assert {:ok, entries} = CrossValidator.reconcile(xsd_codes, xlsx_rows, @empty_overrides, [])

      assert Enum.map(entries, & &1.value) == ["03", "01", "02"]
    end
  end
end
