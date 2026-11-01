defmodule Sat.Cfdi.Descarga.Masiva.Paquete.ReaderMetadataTest do
  @moduledoc """
  `Reader.parse_metadata/1` contra los casos que maneja phpcfdi
  (`MetadataFileFilter`, `MetadataPreprocessor`, `ThirdPartiesFileFilter`):

    * el ZIP puede traer el archivo de terceros (`*_tercero.txt`) y varios
      `.txt` de metadata: solo cuentan los que empiezan con `Uuid~RfcEmisor~`;
    * el EOL del SAT es `\\r\\n` y un campo puede traer un `\\n` adentro;
    * los datos de terceros se unen a cada fila por UUID.
  """
  use ExUnit.Case, async: true

  alias Sat.Cfdi.Descarga.Masiva.Paquete.Reader
  alias Sat.Cfdi.Descarga.Masiva.Types.Paquete

  @header "Uuid~RfcEmisor~NombreEmisor~RfcReceptor~NombreReceptor~RfcPac~" <>
            "FechaEmision~FechaCertificacionSat~Monto~EfectoComprobante~" <>
            "Estatus~FechaCancelacion"

  @uuid_a "AAAAAAAA-1111-4111-8111-111111111111"
  @uuid_b "BBBBBBBB-2222-4222-8222-222222222222"
  @uuid_c "CCCCCCCC-3333-4333-8333-333333333333"

  defp fila(uuid, nombre_emisor \\ "EMISOR SA DE CV", monto \\ "116.00", estatus \\ "1") do
    Enum.join(
      [
        uuid,
        "AAA010101AAA",
        nombre_emisor,
        "BBB010101BBB",
        "RECEPTOR SA DE CV",
        "SAT970701NN3",
        "2025-05-10 10:00:00",
        "2025-05-10 10:00:05",
        monto,
        "I",
        estatus,
        ""
      ],
      "~"
    )
  end

  defp txt(lineas, eol \\ "\r\n"), do: Enum.map_join(lineas, "", &(&1 <> eol))

  defp paquete(entries) do
    erl = Enum.map(entries, fn {name, data} -> {String.to_charlist(name), data} end)
    {:ok, {_name, zip}} = :zip.create(~c"in_memory.zip", erl, [:memory])
    %Paquete{id: "PKG-META", content: zip, size: byte_size(zip)}
  end

  test "lee el archivo de metadata aunque el de terceros venga primero en el ZIP" do
    terceros =
      txt(["Uuid~RfcACuentaTerceros~NombreACuentaTerceros", "#{@uuid_a}~TER010101TER~TERCERO SA"])

    pkg =
      paquete([
        {"0A1B_01_tercero.txt", terceros},
        {"0A1B_01.txt", txt([@header, fila(@uuid_a)])}
      ])

    assert {:ok, [row]} = Reader.parse_metadata(pkg)
    assert row[:uuid] == @uuid_a
    assert row[:rfcemisor] == "AAA010101AAA"
    assert row[:monto] == "116.00"
    assert row[:estatus] == "1"
  end

  test "une las filas de todos los .txt de metadata, en orden por nombre de archivo" do
    pkg =
      paquete([
        {"0A1B_02.txt", txt([@header, fila(@uuid_c)])},
        {"0A1B_01.txt", txt([@header, fila(@uuid_a), fila(@uuid_b)])}
      ])

    assert {:ok, rows} = Reader.parse_metadata(pkg)
    assert Enum.map(rows, & &1[:uuid]) == [@uuid_a, @uuid_b, @uuid_c]
  end

  test "repara un salto de linea dentro de un campo cuando el EOL es CRLF" do
    contenido = txt([@header, fila(@uuid_a, "EMISOR\nPARTIDO SA", "500.00"), fila(@uuid_b)])

    assert {:ok, [a, b]} = Reader.parse_metadata(paquete([{"0A1B_01.txt", contenido}]))
    assert a[:uuid] == @uuid_a
    assert a[:nombreemisor] == "EMISORPARTIDO SA"
    assert a[:monto] == "500.00"
    assert a[:estatus] == "1"
    assert b[:uuid] == @uuid_b
  end

  test "con EOL solo LF sigue leyendo cada linea como una fila" do
    contenido = txt([@header, fila(@uuid_a), fila(@uuid_b)], "\n")

    assert {:ok, rows} = Reader.parse_metadata(paquete([{"0A1B_01.txt", contenido}]))
    assert Enum.map(rows, & &1[:uuid]) == [@uuid_a, @uuid_b]
  end

  test "agrega RfcACuentaTerceros y NombreACuentaTerceros por UUID (sin importar mayusculas)" do
    terceros =
      txt([
        "Uuid~RfcACuentaTerceros~NombreACuentaTerceros",
        "#{String.downcase(@uuid_a)}~TER010101TER~TERCERO SA"
      ])

    pkg =
      paquete([
        {"0A1B_01.txt", txt([@header, fila(@uuid_a), fila(@uuid_b)])},
        {"0A1B_01_tercero.txt", terceros}
      ])

    assert {:ok, [a, b]} = Reader.parse_metadata(pkg)
    assert a[:rfcacuentaterceros] == "TER010101TER"
    assert a[:nombreacuentaterceros] == "TERCERO SA"
    refute Map.has_key?(b, :rfcacuentaterceros)
  end

  test "quita el BOM UTF-8 del inicio del archivo" do
    contenido = "﻿" <> txt([@header, fila(@uuid_a)])

    assert {:ok, [row]} = Reader.parse_metadata(paquete([{"0A1B_01.txt", contenido}]))
    assert row[:uuid] == @uuid_a
  end

  test "ignora .txt que no son metadata" do
    pkg =
      paquete([
        {"leeme.txt", "Este paquete fue generado por el SAT\r\n"},
        {"0A1B_01.txt", txt([@header, fila(@uuid_a)])}
      ])

    assert {:ok, [row]} = Reader.parse_metadata(pkg)
    assert row[:uuid] == @uuid_a
  end

  test "error si el ZIP no trae ningun .txt de metadata" do
    pkg =
      paquete([
        {"0A1B_01_tercero.txt", txt(["Uuid~RfcACuentaTerceros~NombreACuentaTerceros"])},
        {"leeme.txt", "hola\r\n"}
      ])

    assert {:error, {:metadata_not_found, :no_txt_file}} = Reader.parse_metadata(pkg)
  end

  test "un archivo de metadata con solo el encabezado devuelve cero filas" do
    assert {:ok, []} = Reader.parse_metadata(paquete([{"0A1B_01.txt", txt([@header])}]))
  end
end
