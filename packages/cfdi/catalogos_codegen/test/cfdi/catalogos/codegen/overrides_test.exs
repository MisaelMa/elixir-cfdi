defmodule Cfdi.Catalogos.Codegen.OverridesTest do
  use ExUnit.Case, async: true

  alias Cfdi.Catalogos.Codegen.Overrides

  @fixtures_dir Path.expand("../../../fixtures", __DIR__)

  describe "load/1" do
    test "returns default empty maps when file does not exist" do
      path = Path.join(@fixtures_dir, "nonexistent_override.exs")
      assert {:ok, result} = Overrides.load(path)

      assert result == %{enum_names: %{}, descriptions: %{}}
    end

    test "returns populated maps for a valid override file" do
      path = Path.join(@fixtures_dir, "sample_override.exs")
      assert {:ok, result} = Overrides.load(path)

      assert result.enum_names == %{"01" => :efectivo, "02" => :cheque_nominativo}
      assert result.descriptions == %{"99" => "Por definir"}
    end

    test "returns error when file evaluates to a non-map" do
      path = write_temp_fixture("not_a_map_override.exs", ~S|[1, 2, 3]|)
      assert {:error, _reason} = Overrides.load(path)
    after
      File.rm(Path.join(System.tmp_dir!(), "not_a_map_override.exs"))
    end

    test "returns error when file raises during eval" do
      path = write_temp_fixture("raises_override.exs", ~S|raise "bad override"|)
      assert {:error, _reason} = Overrides.load(path)
    after
      File.rm(Path.join(System.tmp_dir!(), "raises_override.exs"))
    end
  end

  defp write_temp_fixture(filename, content) do
    path = Path.join(System.tmp_dir!(), filename)
    File.write!(path, content)
    path
  end
end
