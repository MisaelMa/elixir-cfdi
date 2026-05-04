defmodule Cfdi.Catalogos.Codegen.RendererTest do
  use ExUnit.Case, async: true

  alias Cfdi.Catalogos.Codegen.Catalogs.Spec
  alias Cfdi.Catalogos.Codegen.Renderer

  @golden_with_atoms_path Path.expand("../../../fixtures/golden_with_atoms.ex", __DIR__)
  @golden_strings_only_path Path.expand("../../../fixtures/golden_strings_only.ex", __DIR__)
  @golden_regimen_fiscal_path Path.expand("../../../fixtures/golden_regimen_fiscal.ex", __DIR__)

  defp forma_pago_spec do
    %Spec{
      simpletype: "c_FormaPago",
      module_name: Cfdi.Catalogos.FormaPago,
      file_name: "forma_pago.ex",
      variant: :with_atoms,
      overrides_file: "forma_pago.exs"
    }
  end

  defp tipo_relacion_spec do
    %Spec{
      simpletype: "c_TipoRelacion",
      module_name: Cfdi.Catalogos.TipoRelacion,
      file_name: "tipo_relacion.ex",
      variant: :strings_only
    }
  end

  defp regimen_fiscal_spec do
    %Spec{
      simpletype: "c_RegimenFiscal",
      module_name: Cfdi.Catalogos.RegimenFiscal,
      file_name: "regimen_fiscal.ex",
      variant: :regimen_fiscal,
      extra_columns: [
        persona_fisica: 2,
        persona_moral: 3,
        inicio_vigencia: 4,
        fin_vigencia: 5
      ]
    }
  end

  defp forma_pago_entries do
    [
      %{value: :efectivo, code: "01", label: "Efectivo", deprecated: false},
      %{value: :cheque_nominativo, code: "02", label: "Cheque nominativo", deprecated: false}
    ]
  end

  defp tipo_relacion_entries do
    [
      %{
        value: "01",
        label: "Nota de crédito de los documentos relacionados",
        deprecated: false
      },
      %{
        value: "02",
        label: "Nota de débito de los documentos relacionados",
        deprecated: false
      }
    ]
  end

  defp regimen_fiscal_entries do
    [
      %{
        value: "601",
        label: "General de Ley Personas Morales",
        persona_fisica: false,
        persona_moral: true,
        inicio_vigencia: ~D[2022-01-01],
        fin_vigencia: nil,
        deprecated: false
      }
    ]
  end

  # ─── Variant A: with_atoms ─────────────────────────────────────────────────

  describe "render/1 — Variant A (:with_atoms)" do
    test "renders 2-entry FormaPago and matches golden file byte-for-byte" do
      input = %{spec: forma_pago_spec(), entries: forma_pago_entries()}
      golden = File.read!(@golden_with_atoms_path)

      assert {:ok, output} = Renderer.render(input)
      assert output == golden
    end

    test "output is mix-format-compliant (parseable Elixir)" do
      input = %{spec: forma_pago_spec(), entries: forma_pago_entries()}
      assert {:ok, output} = Renderer.render(input)
      assert {:ok, _quoted} = Code.string_to_quoted(output)
    end

    test "render/1 is idempotent — two calls return the same string" do
      input = %{spec: forma_pago_spec(), entries: forma_pago_entries()}
      assert {:ok, first} = Renderer.render(input)
      assert {:ok, second} = Renderer.render(input)
      assert first == second
    end

    test "header contains exactly the 4-line banner" do
      input = %{spec: forma_pago_spec(), entries: forma_pago_entries()}
      assert {:ok, output} = Renderer.render(input)

      expected_header = """
      # ─────────────────────────────────────────────────────────────
      #  Generado por Cfdi.Catalogos.Codegen — NO EDITAR.
      #  Source: packages/files/4.0/catCFDI.xsd + catCFDI.xlsx
      # ─────────────────────────────────────────────────────────────
      """

      assert String.starts_with?(output, expected_header)
    end
  end

  # ─── Variant B: strings_only ───────────────────────────────────────────────

  describe "render/1 — Variant B (:strings_only)" do
    test "renders 2-entry TipoRelacion and matches golden file byte-for-byte" do
      input = %{spec: tipo_relacion_spec(), entries: tipo_relacion_entries()}
      golden = File.read!(@golden_strings_only_path)

      assert {:ok, output} = Renderer.render(input)
      assert output == golden
    end

    test "output is mix-format-compliant" do
      input = %{spec: tipo_relacion_spec(), entries: tipo_relacion_entries()}
      assert {:ok, output} = Renderer.render(input)
      assert {:ok, _quoted} = Code.string_to_quoted(output)
    end

    test "render/1 is idempotent" do
      input = %{spec: tipo_relacion_spec(), entries: tipo_relacion_entries()}
      assert {:ok, first} = Renderer.render(input)
      assert {:ok, second} = Renderer.render(input)
      assert first == second
    end

    test "no value/1 function and no @type t atom union in strings_only output" do
      input = %{spec: tipo_relacion_spec(), entries: tipo_relacion_entries()}
      assert {:ok, output} = Renderer.render(input)
      # No value/1 function that takes an atom
      refute output =~ ~r/def value\(:/
      # No @type t :: :atom_a | :atom_b style union (atoms use | syntax)
      refute output =~ ~r/@type t :: :/
    end
  end

  # ─── Variant C: regimen_fiscal ─────────────────────────────────────────────

  describe "render/1 — Variant C (:regimen_fiscal)" do
    test "renders 1-entry RegimenFiscal and matches golden file byte-for-byte" do
      input = %{spec: regimen_fiscal_spec(), entries: regimen_fiscal_entries()}
      golden = File.read!(@golden_regimen_fiscal_path)

      assert {:ok, output} = Renderer.render(input)
      assert output == golden
    end

    test "output is mix-format-compliant" do
      input = %{spec: regimen_fiscal_spec(), entries: regimen_fiscal_entries()}
      assert {:ok, output} = Renderer.render(input)
      assert {:ok, _quoted} = Code.string_to_quoted(output)
    end

    test "date sigil ~D[] rendered correctly and nil renders as nil" do
      input = %{spec: regimen_fiscal_spec(), entries: regimen_fiscal_entries()}
      assert {:ok, output} = Renderer.render(input)
      assert output =~ "~D[2022-01-01]"
      assert output =~ "fin_vigencia: nil"
    end

    test "@type t includes all 4 extra fields" do
      input = %{spec: regimen_fiscal_spec(), entries: regimen_fiscal_entries()}
      assert {:ok, output} = Renderer.render(input)
      assert output =~ "persona_fisica:"
      assert output =~ "persona_moral:"
      assert output =~ "inicio_vigencia:"
      assert output =~ "fin_vigencia:"
    end
  end
end
