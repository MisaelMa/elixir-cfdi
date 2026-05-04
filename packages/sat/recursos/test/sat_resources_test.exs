defmodule Sat.Recursos.SatResourcesTest do
  use ExUnit.Case, async: true

  alias Sat.Recursos.SatResources

  # We use Req.Test stubs by passing `plug: {Req.Test, __MODULE__}` via the opts keyword.
  # download_xlsx/2 (struct-based) accepts opts as second arg (default []).
  # download_xlsx/3 (URL-based) requires all 3 args explicitly.

  @url "https://example.sat.gob.mx/catCFDI.xlsx"
  @stub_name __MODULE__

  # Tests for download_xlsx/1 (struct-based) use env vars, so we mark the describe
  # async: false to avoid test ordering issues (ExUnit does not support async: false
  # on individual describe blocks, so we isolate the module for it below).

  @hardcoded_xlsx_url "http://omawww.sat.gob.mx/tramitesyservicios/Paginas/documentos/catCFDI_V_4_20260422.xls"

  describe "download_xlsx/1 — struct-based convenience wrapper" do
    setup do
      tmp = System.tmp_dir!()
      output_dir = Path.join(tmp, "resources_test_#{System.unique_integer()}")
      File.mkdir_p!(output_dir)

      on_exit(fn ->
        System.delete_env("SAT_XLSX_URL")
        File.rm_rf!(output_dir)
      end)

      {:ok, output_dir: output_dir}
    end

    # --- Task 7.3: version 3.3 has nil hardcoded xlsx URL ---

    test "returns error when version is 3.3 and no SAT_XLSX_URL and no option set", %{
      output_dir: output_dir
    } do
      System.delete_env("SAT_XLSX_URL")
      resources = SatResources.new(version: "3.3", output_dir: output_dir)

      assert {:error, msg} = SatResources.download_xlsx(resources)
      assert String.contains?(msg, "SAT_XLSX_URL")
      assert String.contains?(msg, "Anexo 20")
      assert String.contains?(msg, "catCFDI.xlsx")
    end

    # --- Task 7.3: version 4.0 falls back to hardcoded URL ---

    test "new/1 for version 4.0 falls back to hardcoded xlsx URL when neither option nor env var is set",
         %{output_dir: output_dir} do
      System.delete_env("SAT_XLSX_URL")
      resources = SatResources.new(version: "4.0", output_dir: output_dir)

      assert resources.xlsx_url == @hardcoded_xlsx_url
    end

    test "resolution order: option > env var > hardcoded — option wins over both", %{
      output_dir: output_dir
    } do
      explicit_url = "https://my-server.example.com/catCFDI.xls"
      System.put_env("SAT_XLSX_URL", "https://env.example.com/ignored.xls")

      resources =
        SatResources.new(version: "4.0", output_dir: output_dir, xlsx_url: explicit_url)

      assert resources.xlsx_url == explicit_url
    end

    test "resolution order: env var > hardcoded — env var wins over hardcoded when no option given",
         %{output_dir: output_dir} do
      env_url = "https://env.example.com/override.xls"
      System.put_env("SAT_XLSX_URL", env_url)

      resources = SatResources.new(version: "4.0", output_dir: output_dir)

      assert resources.xlsx_url == env_url
    end

    test "version 3.3 has nil hardcoded xlsx URL", %{output_dir: output_dir} do
      System.delete_env("SAT_XLSX_URL")
      resources = SatResources.new(version: "3.3", output_dir: output_dir)

      assert resources.xlsx_url == nil
    end

    # --- Task 7.3: xlsx_last_verified/0 ---

    test "xlsx_last_verified/0 returns ~D[2026-04-22]" do
      assert SatResources.xlsx_last_verified() == ~D[2026-04-22]
    end

    # --- Task 7.3: download succeeds using hardcoded URL ---

    test "download_xlsx/2 succeeds with hardcoded URL when stub returns 200", %{
      output_dir: output_dir
    } do
      System.delete_env("SAT_XLSX_URL")
      body = "xlsx-from-hardcoded-url"

      Req.Test.stub(@stub_name, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, body)
      end)

      resources = SatResources.new(version: "4.0", output_dir: output_dir)
      assert resources.xlsx_url == @hardcoded_xlsx_url

      assert {:ok, dest} =
               SatResources.download_xlsx(resources, plug: {Req.Test, @stub_name})

      assert dest == Path.join(output_dir, "catCFDI.xlsx")
      assert File.read!(dest) == body
    end

    # --- Task 7.3: Logger warning when hardcoded URL fails with 404 ---

    test "Logger.warning emitted when hardcoded URL fails with 404, error tuple unchanged", %{
      output_dir: output_dir
    } do
      System.delete_env("SAT_XLSX_URL")

      Req.Test.stub(@stub_name, fn conn ->
        Plug.Conn.send_resp(conn, 404, "Not Found")
      end)

      resources = SatResources.new(version: "4.0", output_dir: output_dir)
      assert resources.xlsx_url == @hardcoded_xlsx_url

      log =
        ExUnit.CaptureLog.capture_log(fn ->
          assert {:error, {:http_status, 404}} =
                   SatResources.download_xlsx(resources, plug: {Req.Test, @stub_name})
        end)

      assert String.contains?(log, "verificada por última vez")
      assert String.contains?(log, "2026-04-22")
    end

    test "uses xlsx_url from new/1 option to download file", %{output_dir: output_dir} do
      stub_url = "https://stub.example.com/catCFDI.xlsx"
      body = "xlsx-stub-body"

      Req.Test.stub(@stub_name, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, body)
      end)

      resources = SatResources.new(version: "4.0", output_dir: output_dir, xlsx_url: stub_url)

      assert {:ok, dest} =
               SatResources.download_xlsx(resources, plug: {Req.Test, @stub_name})

      assert dest == Path.join(output_dir, "catCFDI.xlsx")
      assert File.read!(dest) == body
    end

    test "uses xlsx_url from SAT_XLSX_URL env var when option is missing", %{
      output_dir: output_dir
    } do
      env_url = "https://envstub.example.com/x.xlsx"
      body = "from-env-var"
      System.put_env("SAT_XLSX_URL", env_url)

      Req.Test.stub(@stub_name, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, body)
      end)

      resources = SatResources.new(version: "4.0", output_dir: output_dir)

      assert resources.xlsx_url == env_url

      assert {:ok, dest} =
               SatResources.download_xlsx(resources, plug: {Req.Test, @stub_name})

      assert File.read!(dest) == body
    end

    test "xlsx_url option overrides SAT_XLSX_URL env var", %{output_dir: output_dir} do
      System.put_env("SAT_XLSX_URL", "https://envstub.example.com/ignored.xlsx")

      resources =
        SatResources.new(version: "4.0", output_dir: output_dir, xlsx_url: "https://opt.example.com/chosen.xlsx")

      assert resources.xlsx_url == "https://opt.example.com/chosen.xlsx"
    end

    test "propagates errors from download_xlsx/3 (404)", %{output_dir: output_dir} do
      stub_url = "https://stub.example.com/notfound.xlsx"

      Req.Test.stub(@stub_name, fn conn ->
        Plug.Conn.send_resp(conn, 404, "Not Found")
      end)

      resources = SatResources.new(version: "4.0", output_dir: output_dir, xlsx_url: stub_url)

      assert {:error, {:http_status, 404}} =
               SatResources.download_xlsx(resources, plug: {Req.Test, @stub_name})
    end
  end

  describe "download_xlsx/3" do
    test "200 OK writes body to dest_path and returns :ok" do
      dest = Path.join(System.tmp_dir!(), "test_download_#{System.unique_integer()}.xlsx")
      body = <<0x50, 0x4B, 0x03, 0x04>>

      Req.Test.stub(@stub_name, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, body)
      end)

      assert :ok =
               SatResources.download_xlsx(@url, dest, plug: {Req.Test, @stub_name})

      assert File.exists?(dest)
      assert File.read!(dest) == body

      File.rm!(dest)
    end

    test "non-200 status returns {:error, {:http_status, 404}} and writes no file" do
      dest = Path.join(System.tmp_dir!(), "test_download_#{System.unique_integer()}.xlsx")

      Req.Test.stub(@stub_name, fn conn ->
        Plug.Conn.send_resp(conn, 404, "Not Found")
      end)

      assert {:error, {:http_status, 404}} =
               SatResources.download_xlsx(@url, dest, plug: {Req.Test, @stub_name})

      refute File.exists?(dest)
    end

    test "parent directory does not exist: created automatically on 200 success" do
      tmp = System.tmp_dir!()
      new_dir = Path.join(tmp, "new_dir_#{System.unique_integer()}")
      dest = Path.join(new_dir, "catCFDI.xlsx")
      body = "xlsx-content"

      Req.Test.stub(@stub_name, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, body)
      end)

      assert :ok =
               SatResources.download_xlsx(@url, dest, plug: {Req.Test, @stub_name})

      assert File.exists?(dest)
      assert File.read!(dest) == body

      File.rm_rf!(new_dir)
    end

    test "network error returns {:error, reason} and writes no file" do
      dest = Path.join(System.tmp_dir!(), "test_download_#{System.unique_integer()}.xlsx")

      Req.Test.stub(@stub_name, fn conn ->
        Req.Test.transport_error(conn, :econnrefused)
      end)

      result = SatResources.download_xlsx(@url, dest, plug: {Req.Test, @stub_name})

      assert match?({:error, _}, result)
      refute File.exists?(dest)
    end
  end
end
