defmodule Sat.WsDescargaMasivaTest do
  use ExUnit.Case, async: true

  alias Sat.WsDescargaMasiva
  alias Sat.WsDescargaMasiva.{Autenticacion, Descarga, PackageReader, Solicitud, Verificacion}
  alias Sat.WsDescargaMasiva.Types.{Paquete, SolicitudParams, Token}

  test "version/0 retorna la version del paquete" do
    assert is_list(WsDescargaMasiva.version()) or
             is_binary(to_string(WsDescargaMasiva.version()))
  end

  describe "endpoints" do
    test "Autenticacion expone el endpoint oficial" do
      assert Autenticacion.endpoint() ==
               "https://cfdidescargamasiva.clouda.sat.gob.mx/Autenticacion/Autenticacion.svc"
    end

    test "Solicitud expone el endpoint oficial" do
      assert Solicitud.endpoint() ==
               "https://cfdidescargamasiva.clouda.sat.gob.mx/SolicitaDescargaService.svc"
    end

    test "Verificacion expone el endpoint oficial" do
      assert Verificacion.endpoint() ==
               "https://cfdidescargamasiva.clouda.sat.gob.mx/VerificaSolicitudDescargaService.svc"
    end

    test "Descarga expone el endpoint oficial" do
      assert Descarga.endpoint() ==
               "https://cfdidescargamasiva.clouda.sat.gob.mx/DescargaMasivaService.svc"
    end
  end

  describe "soap_action" do
    test "Autenticacion expone su SOAPAction" do
      assert Autenticacion.soap_action() ==
               "http://DescargaMasivaTerceros.gob.mx/IAutenticacion/Autentica"
    end

    test "Solicitud expone su SOAPAction" do
      assert Solicitud.soap_action() =~ "ISolicitaDescargaService"
    end

    test "Verificacion expone su SOAPAction" do
      assert Verificacion.soap_action() =~ "IVerificaSolicitudDescargaService"
    end

    test "Descarga expone su SOAPAction" do
      assert Descarga.soap_action() =~ "IDescargaMasivaTercerosService"
    end
  end

  describe "validacion de opciones" do
    setup do
      now = DateTime.utc_now()
      token = %Token{value: "fake-token", issued_at: now, expires_at: DateTime.add(now, 300)}

      params = %SolicitudParams{
        rfc_solicitante: "AAA010101AAA",
        fecha_inicial: ~U[2025-01-01 00:00:00Z],
        fecha_final: ~U[2025-01-31 23:59:59Z],
        tipo_solicitud: :cfdi
      }

      %{token: token, params: params}
    end

    test "Autenticacion.autenticar/1 sin credential" do
      assert {:error, {:missing_option, :credential}} = Autenticacion.autenticar([])
    end

    test "Solicitud.solicitar/3 sin credential", %{token: token, params: params} do
      assert {:error, {:missing_option, :credential}} = Solicitud.solicitar(token, params)
    end

    test "Verificacion.verificar/3 sin credential", %{token: token} do
      assert {:error, {:missing_option, :credential}} = Verificacion.verificar(token, "ID-1")
    end

    test "Descarga.descargar/3 sin credential", %{token: token} do
      assert {:error, {:missing_option, :credential}} = Descarga.descargar(token, "PKG-1")
    end
  end

  describe "PackageReader" do
    test "stream_cfdis con paquete vacio retorna error de zip" do
      paquete = %Paquete{id: "PKG-X", content: <<>>, size: 0}
      assert {:error, {:zip_error, _}} = PackageReader.stream_cfdis(paquete)
    end

    test "stream_cfdis filtra solo .xml de un ZIP real" do
      zip = build_zip([{"factura1.xml", "<cfdi>1</cfdi>"}, {"factura2.xml", "<cfdi>2</cfdi>"}, {"readme.txt", "ignored"}])
      paquete = %Paquete{id: "PKG-1", content: zip, size: byte_size(zip)}

      {:ok, stream} = PackageReader.stream_cfdis(paquete)
      list = Enum.to_list(stream)

      assert length(list) == 2
      assert Enum.all?(list, fn {name, _} -> String.ends_with?(name, ".xml") end)
      assert {"factura1.xml", "<cfdi>1</cfdi>"} in list
    end

    test "list_files devuelve nombres dentro del ZIP" do
      zip = build_zip([{"a.xml", "x"}, {"b.txt", "y"}])
      paquete = %Paquete{id: "PKG-2", content: zip, size: byte_size(zip)}

      {:ok, files} = PackageReader.list_files(paquete)
      assert Enum.sort(files) == ["a.xml", "b.txt"]
    end

    test "parse_metadata parsea TSV con separador tilde" do
      tsv =
        "UUID~RfcEmisor~RfcReceptor~Total\r\n" <>
          "11111111-1111-1111-1111-111111111111~AAA010101AAA~BBB010101BBB~100.00\r\n" <>
          "22222222-2222-2222-2222-222222222222~CCC010101CCC~DDD010101DDD~250.50\r\n"

      zip = build_zip([{"metadata.txt", tsv}])
      paquete = %Paquete{id: "PKG-META", content: zip, size: byte_size(zip)}

      {:ok, rows} = PackageReader.parse_metadata(paquete)

      assert length(rows) == 2
      first = hd(rows)
      assert first[:uuid] == "11111111-1111-1111-1111-111111111111"
      assert first[:rfcemisor] == "AAA010101AAA"
      assert first[:total] == "100.00"
    end
  end

  defp build_zip(entries) do
    erl_entries = Enum.map(entries, fn {name, data} -> {String.to_charlist(name), data} end)
    {:ok, {_filename, zip_bin}} = :zip.create(~c"in_memory.zip", erl_entries, [:memory])
    zip_bin
  end
end
