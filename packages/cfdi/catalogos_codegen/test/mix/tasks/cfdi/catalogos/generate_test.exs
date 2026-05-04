defmodule Mix.Tasks.Cfdi.Catalogos.GenerateTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Mix.Tasks.Cfdi.Catalogos.Generate

  @tiny_xsd_path Path.expand("../../../../fixtures/tiny.xsd", __DIR__)
  @tiny_xlsx_path Path.expand("../../../../fixtures/tiny.xlsx", __DIR__)

  defp make_tmp_dir do
    dir = System.tmp_dir!() |> Path.join("mix_task_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    dir
  end

  describe "run/1 — successful run" do
    test "runs without error when XSD and XLSX exist (generates 0 catalogs from tiny fixtures)" do
      # tiny.xsd only has c_A and c_B, which are not in Catalogs.specs/0.
      # All 15 specs are skipped because their simpletypes are absent from the XSD.
      # This verifies the task runs cleanly end-to-end and prints a summary.
      out = make_tmp_dir()

      output =
        capture_io(fn ->
          Generate.run([
            "--xsd",
            @tiny_xsd_path,
            "--xlsx",
            @tiny_xlsx_path,
            "--output",
            out
          ])
        end)

      assert output =~ "catálogos generados"
    end

    test "--only filter narrows down specs" do
      out = make_tmp_dir()

      # "forma_pago" is not in tiny.xsd, so it will be skipped → 0 files
      output =
        capture_io(fn ->
          Generate.run([
            "--xsd",
            @tiny_xsd_path,
            "--xlsx",
            @tiny_xlsx_path,
            "--output",
            out,
            "--only",
            "forma_pago"
          ])
        end)

      # No error raised, and summary printed
      assert output =~ "catálogos generados"
      # Only forma_pago was in the filter — nothing else should be written
      assert File.ls!(out) == []
    end
  end

  describe "run/1 — missing XSD" do
    test "raises Mix.Error when XSD does not exist" do
      out = make_tmp_dir()

      assert_raise Mix.Error, fn ->
        capture_io(:stderr, fn ->
          Generate.run([
            "--xsd",
            "/nonexistent/catCFDI.xsd",
            "--xlsx",
            @tiny_xlsx_path,
            "--output",
            out
          ])
        end)
      end
    end
  end

  describe "run/1 — missing XLSX" do
    test "raises Mix.Error when XLSX does not exist" do
      out = make_tmp_dir()

      assert_raise Mix.Error, fn ->
        capture_io(:stderr, fn ->
          Generate.run([
            "--xsd",
            @tiny_xsd_path,
            "--xlsx",
            "/nonexistent/catCFDI.xlsx",
            "--output",
            out
          ])
        end)
      end
    end
  end

  describe "run/1 — idempotence" do
    test "running the task twice produces no error" do
      out = make_tmp_dir()

      args = [
        "--xsd",
        @tiny_xsd_path,
        "--xlsx",
        @tiny_xlsx_path,
        "--output",
        out
      ]

      # Run once
      output1 = capture_io(fn -> Generate.run(args) end)
      # Run again — must not raise
      output2 = capture_io(fn -> Generate.run(args) end)

      assert output1 =~ "catálogos generados"
      assert output2 =~ "catálogos generados"
    end
  end

  describe "run/1 — --force-download wiring" do
    # Regression test for the bug where --force-download + absent XLSX produced
    # {:missing_xlsx_no_resources, ...} instead of an HTTP/network error.
    #
    # Root cause: maybe_add_sat_resources/4 was gating on File.exists?(xlsx_path),
    # so when the file was absent AND force_download was true, sat_resources was
    # NOT injected. Codegen then called download_xlsx(path, nil) → the error above.
    #
    # After the fix: sat_resources is ALWAYS built when force_download is true.
    # The error becomes a real HTTP or network error (not the nil-guard error),
    # proving the wiring is correct.
    @tag :network
    test "--force-download with absent XLSX does not produce missing_xlsx_no_resources" do
      out = make_tmp_dir()
      # Deliberately absent XLSX path — file does not exist
      absent_xlsx = Path.join(out, "catCFDI.xlsx")

      # The task will attempt to download (sat_resources is now wired).
      # It will raise Mix.Error because the download fails (network / HTTP),
      # but NOT with the "missing_xlsx_no_resources" sentinel.
      error =
        assert_raise Mix.Error, fn ->
          capture_io(:stderr, fn ->
            Generate.run([
              "--xsd",
              @tiny_xsd_path,
              "--xlsx",
              absent_xlsx,
              "--output",
              out,
              "--force-download"
            ])
          end)
        end

      refute String.contains?(error.message, "missing_xlsx_no_resources"),
             "Expected sat_resources to be wired; got the nil-guard error instead: #{error.message}"
    end
  end
end
