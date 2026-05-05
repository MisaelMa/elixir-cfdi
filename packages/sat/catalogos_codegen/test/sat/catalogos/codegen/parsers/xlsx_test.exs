defmodule Sat.Catalogos.Codegen.Parsers.XlsxTest do
  use ExUnit.Case, async: true

  alias Sat.Catalogos.Codegen.Parsers.Xlsx

  @fixture_path Path.expand("../../../../fixtures/tiny.xlsx", __DIR__)

  describe "read_sheet/2 — sheet c_A (matches tiny.xsd)" do
    test "reads c_A sheet and returns all 4 rows as list of lists of strings" do
      assert {:ok, rows} = Xlsx.read_sheet(@fixture_path, "c_A")

      # Fixture (SAT-aligned): 1 simpleType header row + 3 data rows
      # The simpleType name in col A IS the column header (no separate header row)
      assert length(rows) == 4
      # First row has the simpleType name in column A
      assert Enum.at(rows, 0) == ["c_A", "Nombre"]
      # Data rows start at index 1
      assert Enum.at(rows, 1) == ["01", "Alfa"]
      assert Enum.at(rows, 2) == ["02", "Beta"]
      assert Enum.at(rows, 3) == ["03", "Gamma"]
    end

    test "resolves sharedString references correctly for c_A" do
      assert {:ok, rows} = Xlsx.read_sheet(@fixture_path, "c_A")

      assert Enum.all?(rows, fn row ->
               Enum.all?(row, fn cell -> is_binary(cell) or is_nil(cell) end)
             end)
    end
  end

  describe "read_sheet/2 — sheet c_B (matches tiny.xsd)" do
    test "reads c_B sheet and returns all 3 rows" do
      assert {:ok, rows} = Xlsx.read_sheet(@fixture_path, "c_B")

      # Fixture (SAT-aligned): 1 simpleType header row + 2 data rows
      assert length(rows) == 3
      assert Enum.at(rows, 0) == ["c_B", "Nombre"]
      assert Enum.at(rows, 1) == ["X", "Equis"]
      assert Enum.at(rows, 2) == ["Y", "Ye"]
    end

    test "resolves sharedString references correctly for c_B" do
      assert {:ok, rows} = Xlsx.read_sheet(@fixture_path, "c_B")

      assert Enum.all?(rows, fn row ->
               Enum.all?(row, fn cell -> is_binary(cell) or is_nil(cell) end)
             end)
    end
  end

  describe "read_sheet/2 — error cases" do
    test "returns error for missing file" do
      result = Xlsx.read_sheet("/nonexistent/path/file.xlsx", "Sheet1")
      assert {:error, _} = result
    end

    test "returns error for missing sheet name" do
      assert {:error, _} = Xlsx.read_sheet(@fixture_path, "NonexistentSheet")
    end
  end
end
