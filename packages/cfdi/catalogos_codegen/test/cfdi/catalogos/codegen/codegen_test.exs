defmodule Cfdi.Catalogos.CodegenTest do
  use ExUnit.Case, async: true

  alias Cfdi.Catalogos.Codegen
  alias Cfdi.Catalogos.Codegen.Catalogs.Spec

  @tiny_xsd_path Path.expand("../../../fixtures/tiny.xsd", __DIR__)
  @tiny_xlsx_path Path.expand("../../../fixtures/tiny.xlsx", __DIR__)

  # ─── Tests for normalize_code/2 (Bug 2) ────────────────────────────────────

  describe "normalize_code/2" do
    test "integer 1 with pad 2 becomes '01'" do
      assert Cfdi.Catalogos.Codegen.normalize_code(1, 2) == "01"
    end

    test "integer 12 with pad 2 stays '12' (already 2 chars)" do
      assert Cfdi.Catalogos.Codegen.normalize_code(12, 2) == "12"
    end

    test "integer 1 with pad 3 becomes '001'" do
      assert Cfdi.Catalogos.Codegen.normalize_code(1, 3) == "001"
    end

    test "integer 1 with pad 0 becomes '1' (no padding)" do
      assert Cfdi.Catalogos.Codegen.normalize_code(1, 0) == "1"
    end

    test "string '01' with pad 2 stays '01' (strings pass through untouched)" do
      assert Cfdi.Catalogos.Codegen.normalize_code("01", 2) == "01"
    end

    test "string 'PUE' with pad 0 stays 'PUE'" do
      assert Cfdi.Catalogos.Codegen.normalize_code("PUE", 0) == "PUE"
    end

    test "string '1' (numeric-looking string) with pad 2 is padded to '01'" do
      assert Cfdi.Catalogos.Codegen.normalize_code("1", 2) == "01"
    end

    test "string '601' with pad 0 stays '601'" do
      assert Cfdi.Catalogos.Codegen.normalize_code("601", 0) == "601"
    end

    test "nil with pad 0 becomes empty string" do
      assert Cfdi.Catalogos.Codegen.normalize_code(nil, 0) == ""
    end
  end

  # ─── Tests for parse_date/1 (Bug 3) ─────────────────────────────────────────

  describe "parse_date/1 — integer serial dates" do
    test "serial string '44562' resolves to ~D[2022-01-01]" do
      assert Cfdi.Catalogos.Codegen.parse_date("44562") == ~D[2022-01-01]
    end

    test "serial integer 44562 resolves to ~D[2022-01-01]" do
      assert Cfdi.Catalogos.Codegen.parse_date(44562) == ~D[2022-01-01]
    end

    test "serial string '1' resolves to ~D[1899-12-31]" do
      assert Cfdi.Catalogos.Codegen.parse_date("1") == ~D[1899-12-31]
    end

    test "existing DD/MM/YYYY format still works" do
      assert Cfdi.Catalogos.Codegen.parse_date("01/01/2022") == ~D[2022-01-01]
    end

    test "nil returns nil" do
      assert Cfdi.Catalogos.Codegen.parse_date(nil) == nil
    end

    test "empty string returns nil" do
      assert Cfdi.Catalogos.Codegen.parse_date("") == nil
    end

    test "unreasonable serial (too large) returns nil" do
      # year 2100+ is considered unreasonable
      assert Cfdi.Catalogos.Codegen.parse_date("999999") == nil
    end
  end

  # ─── Tests for auto-detect header row (Bug 1) ────────────────────────────────

  describe "parse_xlsx_rows/2 — auto-detect simpletype header" do
    # The real SAT XLSX has 4 header rows: title, metadata headers, metadata values,
    # then row with simpletype in col A. Data comes AFTER that row.
    # We test via generate/1 using a fixture that mimics this 4-row structure.
    test "auto-detects data start when simpletype header is at row 0 (tiny.xlsx format)" do
      tmp_dir =
        System.tmp_dir!()
        |> Path.join("codegen_autodetect_#{System.unique_integer([:positive])}")

      overrides_dir =
        System.tmp_dir!()
        |> Path.join("overrides_autodetect_#{System.unique_integer([:positive])}")

      File.mkdir_p!(tmp_dir)
      File.mkdir_p!(overrides_dir)

      # tiny.xlsx has simpletype at row 0, col headers at row 1, data at row 2+
      opts = [
        xsd_path: @tiny_xsd_path,
        xlsx_path: @tiny_xlsx_path,
        output_dir: tmp_dir,
        overrides_dir: overrides_dir,
        skip_download: true,
        specs: [spec_c_a()]
      ]

      assert {:ok, [path]} = Codegen.generate(opts)
      content = File.read!(path)
      # Should contain c_A codes from tiny.xlsx
      assert content =~ ~s("01")
      assert content =~ ~s("02")
      assert content =~ ~s("03")
    end
  end

  describe "parse_xlsx_rows/2 — label_column" do
    # Test that label_column: 2 picks column C instead of column B.
    # We build a synthetic XLSX using the support module and a spec with label_column: 2.
    test "label_column: 2 extracts col C as label, NOT col B" do
      # Build a tiny.xlsx-like structure for a fake catalog c_A but with an
      # extra column B inserted before the real labels (simulating c_Estado shape:
      # col A = code, col B = country code, col C = state name).
      # We do this by writing an override-free codegen test against the real
      # catCFDI.xlsx, only reading c_Estado, and asserting the label is NOT "MEX".
      xlsx_path = Path.expand("../../../../../../files/4.0/catCFDI.xlsx", __DIR__)

      unless File.exists?(xlsx_path) do
        IO.puts("Skipping label_column test — catCFDI.xlsx not available at #{xlsx_path}")
      else
        xsd_path = Path.expand("../../../../../../files/4.0/catCFDI.xsd", __DIR__)

        tmp_dir =
          System.tmp_dir!()
          |> Path.join("codegen_labelcol_#{System.unique_integer([:positive])}")

        overrides_dir =
          System.tmp_dir!()
          |> Path.join("overrides_labelcol_#{System.unique_integer([:positive])}")

        File.mkdir_p!(tmp_dir)
        File.mkdir_p!(overrides_dir)

        # Write a minimal estado.exs override so codegen can load it
        File.write!(Path.join(overrides_dir, "estado.exs"), ~s(%{enum_names: %{}, descriptions: %{}}))

        estado_spec = %Spec{
          simpletype: "c_Estado",
          module_name: Cfdi.Catalogos.Estado,
          file_name: "estado.ex",
          variant: :strings_only,
          overrides_file: "estado.exs",
          code_pad_start: 0,
          label_column: 2
        }

        opts = [
          xsd_path: xsd_path,
          xlsx_path: xlsx_path,
          output_dir: tmp_dir,
          overrides_dir: overrides_dir,
          skip_download: true,
          specs: [estado_spec]
        ]

        assert {:ok, [path]} = Codegen.generate(opts)
        content = File.read!(path)

        # The first state in the XLSX is AGU = Aguascalientes (col C), NOT MEX (col B)
        assert content =~ ~s("AGU"), "expected AGU code to be present"
        refute content =~ ~s(label: "MEX"), "label should be the state name, not the country code MEX"
        assert content =~ "Aguascalientes", "expected state name Aguascalientes as label"
      end
    end

    test "label_column: 0 uses the code itself as label (for c_TipoFactor shape)" do
      xlsx_path = Path.expand("../../../../../../files/4.0/catCFDI.xlsx", __DIR__)

      unless File.exists?(xlsx_path) do
        IO.puts("Skipping label_column test — catCFDI.xlsx not available at #{xlsx_path}")
      else
        xsd_path = Path.expand("../../../../../../files/4.0/catCFDI.xsd", __DIR__)

        tmp_dir =
          System.tmp_dir!()
          |> Path.join("codegen_tipofactor_#{System.unique_integer([:positive])}")

        overrides_dir =
          System.tmp_dir!()
          |> Path.join("overrides_tipofactor_#{System.unique_integer([:positive])}")

        File.mkdir_p!(tmp_dir)
        File.mkdir_p!(overrides_dir)

        tipo_factor_spec = %Spec{
          simpletype: "c_TipoFactor",
          module_name: Cfdi.Catalogos.TipoFactor,
          file_name: "tipo_factor.ex",
          variant: :strings_only,
          code_pad_start: 0,
          label_column: 0
        }

        opts = [
          xsd_path: xsd_path,
          xlsx_path: xlsx_path,
          output_dir: tmp_dir,
          overrides_dir: overrides_dir,
          skip_download: true,
          specs: [tipo_factor_spec]
        ]

        assert {:ok, [path]} = Codegen.generate(opts)
        content = File.read!(path)

        # With label_column: 0, the label should be the code itself ("Tasa", "Cuota", "Exento")
        assert content =~ ~s(label: "Tasa"), "expected label: \"Tasa\" (code is the label)"
        assert content =~ ~s(label: "Cuota"), "expected label: \"Cuota\" (code is the label)"
        assert content =~ ~s(label: "Exento"), "expected label: \"Exento\" (code is the label)"
        # Should NOT contain date serial as label
        refute content =~ ~s(label: "44562"), "label should not be the date serial 44562"
      end
    end
  end

  describe "overrides.descriptions — deprecated label fallback" do
    test "a deprecated code with override description gets that label instead of empty string" do
      xlsx_path = Path.expand("../../../../../../files/4.0/catCFDI.xlsx", __DIR__)

      unless File.exists?(xlsx_path) do
        IO.puts("Skipping override description test — catCFDI.xlsx not available at #{xlsx_path}")
      else
        xsd_path = Path.expand("../../../../../../files/4.0/catCFDI.xsd", __DIR__)

        tmp_dir =
          System.tmp_dir!()
          |> Path.join("codegen_overridedesc_#{System.unique_integer([:positive])}")

        overrides_dir =
          System.tmp_dir!()
          |> Path.join("overrides_overridedesc_#{System.unique_integer([:positive])}")

        File.mkdir_p!(tmp_dir)
        File.mkdir_p!(overrides_dir)

        # Write a tipo_relacion.exs override with descriptions for deprecated codes 08 and 09
        File.write!(
          Path.join(overrides_dir, "tipo_relacion.exs"),
          ~s(%{enum_names: %{}, descriptions: %{"08" => "Factura generada por pagos en parcialidades", "09" => "Factura generada por pagos diferidos"}})
        )

        tipo_relacion_spec = %Spec{
          simpletype: "c_TipoRelacion",
          module_name: Cfdi.Catalogos.TipoRelacion,
          file_name: "tipo_relacion.ex",
          variant: :strings_only,
          overrides_file: "tipo_relacion.exs",
          code_pad_start: 2
        }

        opts = [
          xsd_path: xsd_path,
          xlsx_path: xlsx_path,
          output_dir: tmp_dir,
          overrides_dir: overrides_dir,
          skip_download: true,
          specs: [tipo_relacion_spec]
        ]

        assert {:ok, [path]} = Codegen.generate(opts)
        content = File.read!(path)

        # Deprecated codes should have their override descriptions, not empty strings
        assert content =~ "Factura generada por pagos en parcialidades",
               "expected override description for code 08"

        assert content =~ "Factura generada por pagos diferidos",
               "expected override description for code 09"

        # Neither deprecated code should have an empty label
        refute content =~ ~s(value: "08", label: "", deprecated: true),
               "code 08 should not have empty label when override description is provided"

        refute content =~ ~s(value: "09", label: "", deprecated: true),
               "code 09 should not have empty label when override description is provided"
      end
    end

    test "regimen_fiscal deprecated codes 609, 628, 629, 630 get canonical descriptions from override" do
      xlsx_path = Path.expand("../../../../../../files/4.0/catCFDI.xlsx", __DIR__)

      unless File.exists?(xlsx_path) do
        IO.puts("Skipping override description test — catCFDI.xlsx not available at #{xlsx_path}")
      else
        xsd_path = Path.expand("../../../../../../files/4.0/catCFDI.xsd", __DIR__)

        tmp_dir =
          System.tmp_dir!()
          |> Path.join("codegen_regimenfiscal_#{System.unique_integer([:positive])}")

        overrides_dir =
          System.tmp_dir!()
          |> Path.join("overrides_regimenfiscal_#{System.unique_integer([:positive])}")

        File.mkdir_p!(tmp_dir)
        File.mkdir_p!(overrides_dir)

        File.write!(
          Path.join(overrides_dir, "regimen_fiscal.exs"),
          ~s(%{enum_names: %{}, descriptions: %{"609" => "Consolidación", "628" => "Hidrocarburos", "629" => "De los Regímenes Fiscales Preferentes y de las Empresas Multinacionales", "630" => "Enajenación de acciones en bolsa de valores"}})
        )

        regimen_spec = %Spec{
          simpletype: "c_RegimenFiscal",
          module_name: Cfdi.Catalogos.RegimenFiscal,
          file_name: "regimen_fiscal.ex",
          variant: :regimen_fiscal,
          overrides_file: "regimen_fiscal.exs",
          code_pad_start: 0,
          extra_columns: [
            persona_fisica: 3,
            persona_moral: 4,
            inicio_vigencia: 5,
            fin_vigencia: 6
          ]
        }

        opts = [
          xsd_path: xsd_path,
          xlsx_path: xlsx_path,
          output_dir: tmp_dir,
          overrides_dir: overrides_dir,
          skip_download: true,
          specs: [regimen_spec]
        ]

        assert {:ok, [path]} = Codegen.generate(opts)
        content = File.read!(path)

        assert content =~ "Consolidación", "expected canonical description for code 609"
        assert content =~ "Hidrocarburos", "expected canonical description for code 628"
        assert content =~ "De los Regímenes Fiscales Preferentes", "expected canonical description for code 629"
        assert content =~ "Enajenación de acciones en bolsa de valores", "expected canonical description for code 630"

        refute content =~ ~s(label: ""), "no deprecated code should have an empty label"
      end
    end
  end

  # Synthetic spec for c_A (strings_only — no atom overrides needed)
  defp spec_c_a do
    %Spec{
      simpletype: "c_A",
      module_name: Cfdi.Catalogos.TestCatalogA,
      file_name: "test_catalog_a.ex",
      variant: :strings_only,
      sheet_name: "c_A",
      overrides_file: nil
    }
  end

  # Synthetic spec for c_B (strings_only)
  defp spec_c_b do
    %Spec{
      simpletype: "c_B",
      module_name: Cfdi.Catalogos.TestCatalogB,
      file_name: "test_catalog_b.ex",
      variant: :strings_only,
      sheet_name: "c_B",
      overrides_file: nil
    }
  end

  describe "generate/1 — happy path" do
    test "writes one .ex file when catalogs: filtered to c_A" do
      tmp_dir = System.tmp_dir!() |> Path.join("codegen_test_#{System.unique_integer([:positive])}")
      overrides_dir = System.tmp_dir!() |> Path.join("overrides_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      File.mkdir_p!(overrides_dir)

      opts = [
        xsd_path: @tiny_xsd_path,
        xlsx_path: @tiny_xlsx_path,
        output_dir: tmp_dir,
        overrides_dir: overrides_dir,
        skip_download: true,
        specs: [spec_c_a()]
      ]

      assert {:ok, written_paths} = Codegen.generate(opts)
      assert length(written_paths) == 1
      [path] = written_paths
      assert Path.basename(path) == "test_catalog_a.ex"
      assert File.exists?(path)

      content = File.read!(path)
      assert {:ok, _quoted} = Code.string_to_quoted(content)
      assert content =~ "defmodule Cfdi.Catalogos.TestCatalogA"
    end

    test "writes two .ex files for both specs" do
      tmp_dir = System.tmp_dir!() |> Path.join("codegen_test_#{System.unique_integer([:positive])}")
      overrides_dir = System.tmp_dir!() |> Path.join("overrides_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      File.mkdir_p!(overrides_dir)

      opts = [
        xsd_path: @tiny_xsd_path,
        xlsx_path: @tiny_xlsx_path,
        output_dir: tmp_dir,
        overrides_dir: overrides_dir,
        skip_download: true,
        specs: [spec_c_a(), spec_c_b()]
      ]

      assert {:ok, written_paths} = Codegen.generate(opts)
      assert length(written_paths) == 2

      basenames = Enum.map(written_paths, &Path.basename/1) |> Enum.sort()
      assert basenames == ["test_catalog_a.ex", "test_catalog_b.ex"]

      for path <- written_paths do
        content = File.read!(path)
        assert {:ok, _} = Code.string_to_quoted(content)
      end
    end
  end

  describe "generate/1 — error cases" do
    test "returns {:error, {:missing_xsd, path}} when XSD file does not exist" do
      tmp_dir = System.tmp_dir!() |> Path.join("codegen_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)

      opts = [
        xsd_path: "/nonexistent/path/catCFDI.xsd",
        xlsx_path: @tiny_xlsx_path,
        output_dir: tmp_dir,
        skip_download: true,
        specs: [spec_c_a()]
      ]

      assert {:error, {:missing_xsd, "/nonexistent/path/catCFDI.xsd"}} = Codegen.generate(opts)
    end

    test "returns {:error, {:missing_xlsx, path}} when XLSX missing and skip_download: true" do
      tmp_dir = System.tmp_dir!() |> Path.join("codegen_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)

      opts = [
        xsd_path: @tiny_xsd_path,
        xlsx_path: "/nonexistent/path/catCFDI.xlsx",
        output_dir: tmp_dir,
        skip_download: true,
        specs: [spec_c_a()]
      ]

      assert {:error, {:missing_xlsx, "/nonexistent/path/catCFDI.xlsx"}} = Codegen.generate(opts)
    end
  end

  describe "generate/1 — idempotence" do
    test "calling generate/1 twice with the same inputs produces byte-identical files" do
      tmp_dir = System.tmp_dir!() |> Path.join("codegen_test_#{System.unique_integer([:positive])}")
      overrides_dir = System.tmp_dir!() |> Path.join("overrides_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      File.mkdir_p!(overrides_dir)

      opts = [
        xsd_path: @tiny_xsd_path,
        xlsx_path: @tiny_xlsx_path,
        output_dir: tmp_dir,
        overrides_dir: overrides_dir,
        skip_download: true,
        specs: [spec_c_a()]
      ]

      assert {:ok, [path1_first]} = Codegen.generate(opts)
      content_first = File.read!(path1_first)

      assert {:ok, [path1_second]} = Codegen.generate(opts)
      content_second = File.read!(path1_second)

      assert path1_first == path1_second
      assert content_first == content_second
    end
  end

  describe "generate/1 — catalogs filter" do
    test "specs: option filters which catalogs are generated" do
      tmp_dir = System.tmp_dir!() |> Path.join("codegen_test_#{System.unique_integer([:positive])}")
      overrides_dir = System.tmp_dir!() |> Path.join("overrides_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      File.mkdir_p!(overrides_dir)

      opts = [
        xsd_path: @tiny_xsd_path,
        xlsx_path: @tiny_xlsx_path,
        output_dir: tmp_dir,
        overrides_dir: overrides_dir,
        skip_download: true,
        specs: [spec_c_a()]
      ]

      assert {:ok, written_paths} = Codegen.generate(opts)
      assert length(written_paths) == 1
      assert Path.basename(hd(written_paths)) == "test_catalog_a.ex"
    end
  end
end
