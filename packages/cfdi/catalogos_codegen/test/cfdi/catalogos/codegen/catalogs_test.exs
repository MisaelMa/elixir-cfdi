defmodule Cfdi.Catalogos.Codegen.CatalogsTest do
  use ExUnit.Case, async: true

  alias Cfdi.Catalogos.Codegen.Catalogs
  alias Cfdi.Catalogos.Codegen.Catalogs.Spec

  describe "specs/0" do
    test "returns exactly 15 entries" do
      assert length(Catalogs.specs()) == 15
    end

    test "first entry is c_FormaPago" do
      first = hd(Catalogs.specs())
      assert first.simpletype == "c_FormaPago"
    end

    test "entries follow the specified order" do
      expected_simpletypes = [
        "c_FormaPago",
        "c_MetodoPago",
        "c_TipoDeComprobante",
        "c_Impuesto",
        "c_UsoCFDI",
        "c_Exportacion",
        "c_Moneda",
        "c_Periodicidad",
        "c_Meses",
        "c_TipoRelacion",
        "c_ObjetoImp",
        "c_TipoFactor",
        "c_Pais",
        "c_Estado",
        "c_RegimenFiscal"
      ]

      actual = Enum.map(Catalogs.specs(), & &1.simpletype)
      assert actual == expected_simpletypes
    end

    test "variant counts: 7 with_atoms, 7 strings_only, 1 regimen_fiscal" do
      specs = Catalogs.specs()
      assert Enum.count(specs, &(&1.variant == :with_atoms)) == 7
      assert Enum.count(specs, &(&1.variant == :strings_only)) == 7
      assert Enum.count(specs, &(&1.variant == :regimen_fiscal)) == 1
    end

    test "excluded simpletypes are NOT present" do
      simpletypes = MapSet.new(Catalogs.specs(), & &1.simpletype)
      refute MapSet.member?(simpletypes, "c_ClaveProdServ")
      refute MapSet.member?(simpletypes, "c_ClaveUnidad")
      refute MapSet.member?(simpletypes, "c_CodigoPostal")
      refute MapSet.member?(simpletypes, "c_Colonia")
      refute MapSet.member?(simpletypes, "c_Localidad")
      refute MapSet.member?(simpletypes, "c_Municipio")
    end

    test "RegimenFiscal spec has 4 extra_columns keys" do
      regimen = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_RegimenFiscal"))
      assert regimen != nil
      extra_keys = Keyword.keys(regimen.extra_columns)
      assert :persona_fisica in extra_keys
      assert :persona_moral in extra_keys
      assert :inicio_vigencia in extra_keys
      assert :fin_vigencia in extra_keys
    end

    test "RegimenFiscal variant is :regimen_fiscal" do
      regimen = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_RegimenFiscal"))
      assert regimen.variant == :regimen_fiscal
    end

    test "module name and file name conventions hold for every spec" do
      for spec <- Catalogs.specs() do
        # module_name must be an atom (module)
        assert is_atom(spec.module_name),
               "expected module_name to be atom for #{spec.simpletype}, got: #{inspect(spec.module_name)}"

        # file_name must be a .ex string
        assert String.ends_with?(spec.file_name, ".ex"),
               "expected file_name to end with .ex for #{spec.simpletype}"

        # file_name should be snake_case
        assert Regex.match?(~r/^[a-z_]+\.ex$/, spec.file_name),
               "expected snake_case file_name for #{spec.simpletype}, got: #{spec.file_name}"
      end
    end

    test "with_atoms specs have nil extra_columns" do
      with_atoms = Enum.filter(Catalogs.specs(), &(&1.variant == :with_atoms))

      for spec <- with_atoms do
        assert spec.extra_columns == [],
               "expected empty extra_columns for #{spec.simpletype}"
      end
    end

    test "all specs are Spec structs with required keys populated" do
      for spec <- Catalogs.specs() do
        assert %Spec{} = spec
        assert is_binary(spec.simpletype)
        assert is_atom(spec.module_name)
        assert is_binary(spec.file_name)
        assert spec.variant in [:with_atoms, :strings_only, :regimen_fiscal]
      end
    end

    test "all specs have code_pad_start as a non_neg_integer" do
      for spec <- Catalogs.specs() do
        assert is_integer(spec.code_pad_start) and spec.code_pad_start >= 0,
               "expected non-negative integer code_pad_start for #{spec.simpletype}"
      end
    end

    test "c_FormaPago has code_pad_start 2" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_FormaPago"))
      assert spec.code_pad_start == 2
    end

    test "c_Impuesto has code_pad_start 3" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_Impuesto"))
      assert spec.code_pad_start == 3
    end

    test "c_TipoRelacion has code_pad_start 2" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_TipoRelacion"))
      assert spec.code_pad_start == 2
    end

    test "c_MetodoPago has code_pad_start 0" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_MetodoPago"))
      assert spec.code_pad_start == 0
    end

    # ── label_column tests ────────────────────────────────────────────────────

    test "all specs have label_column as a non_neg_integer" do
      for spec <- Catalogs.specs() do
        assert is_integer(spec.label_column) and spec.label_column >= 0,
               "expected non-negative integer label_column for #{spec.simpletype}"
      end
    end

    test "c_Estado has label_column: 2 (col C = state name, col B = country code)" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_Estado"))
      assert spec.label_column == 2
    end

    test "c_TipoFactor has label_column: 0 (no description column; code IS the label)" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_TipoFactor"))
      assert spec.label_column == 0
    end

    test "all other specs default to label_column: 1 (col B = description)" do
      exceptions = MapSet.new(["c_Estado", "c_TipoFactor"])

      for spec <- Catalogs.specs(), spec.simpletype not in exceptions do
        assert spec.label_column == 1,
               "expected label_column: 1 for #{spec.simpletype}, got: #{spec.label_column}"
      end
    end

    # ── overrides_file tests ──────────────────────────────────────────────────

    test "c_TipoRelacion has overrides_file: 'tipo_relacion.exs'" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_TipoRelacion"))
      assert spec.overrides_file == "tipo_relacion.exs"
    end

    test "c_Estado has overrides_file: 'estado.exs'" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_Estado"))
      assert spec.overrides_file == "estado.exs"
    end

    test "c_RegimenFiscal has overrides_file: 'regimen_fiscal.exs'" do
      spec = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_RegimenFiscal"))
      assert spec.overrides_file == "regimen_fiscal.exs"
    end

    test "c_RegimenFiscal extra_columns indices map to correct columns (1-based: persona_fisica=3, moral=4, inicio=5, fin=6)" do
      regimen = Enum.find(Catalogs.specs(), &(&1.simpletype == "c_RegimenFiscal"))
      assert Keyword.get(regimen.extra_columns, :persona_fisica) == 3
      assert Keyword.get(regimen.extra_columns, :persona_moral) == 4
      assert Keyword.get(regimen.extra_columns, :inicio_vigencia) == 5
      assert Keyword.get(regimen.extra_columns, :fin_vigencia) == 6
    end
  end
end
