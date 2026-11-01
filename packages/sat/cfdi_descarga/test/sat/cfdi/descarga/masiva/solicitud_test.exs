defmodule Sat.Cfdi.Descarga.Masiva.SolicitudTest do
  @moduledoc """
  Normalización de params: separación de `tipo_solicitud` (dirección/operación
  SOAP) y `tipo_descarga` (CFDI vs Metadata), con retrocompatibilidad del
  `tipo_solicitud` legacy que mezclaba ambos ejes.
  """
  use ExUnit.Case, async: true

  alias Sat.Cfdi.Descarga.Masiva.Solicitud
  alias Sat.Cfdi.Descarga.Masiva.Types.SolicitudParams

  describe "normalizar_params/1" do
    test "sin tipo_descarga → :cfdi, y CFDI sin estado fuerza :vigente" do
      p = Solicitud.normalizar_params(%SolicitudParams{tipo_solicitud: :emitidos})
      assert p.tipo_descarga == :cfdi
      assert p.estado_comprobante == :vigente
    end

    test "legacy tipo_solicitud: :metadata → tipo_descarga :metadata (NO fuerza vigente)" do
      p = Solicitud.normalizar_params(%SolicitudParams{tipo_solicitud: :metadata})
      assert p.tipo_descarga == :metadata
      # metadata SÍ incluye cancelados → no se fuerza :vigente
      assert p.estado_comprobante == nil
    end

    test "metadata explícito conserva la dirección y no fuerza vigente" do
      p =
        Solicitud.normalizar_params(%SolicitudParams{
          tipo_solicitud: :recibidos,
          tipo_descarga: :metadata
        })

      assert p.tipo_descarga == :metadata
      assert p.tipo_solicitud == :recibidos
      assert p.estado_comprobante == nil
    end

    test "estado explícito no se pisa (aunque sea cfdi)" do
      p =
        Solicitud.normalizar_params(%SolicitudParams{
          tipo_solicitud: :emitidos,
          estado_comprobante: :todos
        })

      assert p.estado_comprobante == :todos
    end
  end

  describe "validar_rfc_propio/2 (candado local del 5001)" do
    # El SAT exige que RfcSolicitante sea emisor o receptor de lo que pides:
    # "Solo el Emisor o Receptor podran realizar la consulta y recuperacion".
    # Si no, contesta 5001 "Tercero no autorizado". Cortamos antes de la red.

    test "emitidos: rfc_emisor ajeno es rechazado localmente" do
      p = %SolicitudParams{tipo_solicitud: :emitidos, rfc_emisor: "XAXX010101000"}

      assert {:error, {:rfc_ajeno, :emitidos, "XAXX010101000", "MACA961017759"}} =
               Solicitud.validar_rfc_propio(p, "MACA961017759")
    end

    test "emitidos: rfc_emisor propio pasa (case/espacios no importan)" do
      p = %SolicitudParams{tipo_solicitud: :emitidos, rfc_emisor: " maca961017759 "}
      assert :ok = Solicitud.validar_rfc_propio(p, "MACA961017759")
    end

    test "emitidos: sin rfc_emisor pasa (el sobre usa el solicitante)" do
      p = %SolicitudParams{tipo_solicitud: :emitidos}
      assert :ok = Solicitud.validar_rfc_propio(p, "MACA961017759")
    end

    test "emitidos: rfc_receptor ajeno SI se permite — es filtro de contraparte" do
      p = %SolicitudParams{
        tipo_solicitud: :emitidos,
        rfc_receptor: ["XAXX010101000", "XEXX010101000"]
      }

      assert :ok = Solicitud.validar_rfc_propio(p, "MACA961017759")
    end

    test "recibidos: rfc_receptor ajeno es rechazado localmente" do
      p = %SolicitudParams{tipo_solicitud: :recibidos, rfc_receptor: "XAXX010101000"}

      assert {:error, {:rfc_ajeno, :recibidos, "XAXX010101000", "MACA961017759"}} =
               Solicitud.validar_rfc_propio(p, "MACA961017759")
    end

    test "recibidos: rfc_emisor ajeno SI se permite — es filtro de proveedor" do
      p = %SolicitudParams{tipo_solicitud: :recibidos, rfc_emisor: "XAXX010101000"}
      assert :ok = Solicitud.validar_rfc_propio(p, "MACA961017759")
    end

    test "folio: no aplica el candado (la consulta va por UUID)" do
      p = %SolicitudParams{tipo_solicitud: :folio, uuid: "790040c0-1135-4a30-bf03-9cb25f863396"}
      assert :ok = Solicitud.validar_rfc_propio(p, "MACA961017759")
    end
  end

  describe "soap_operation/1 (dirección → operación)" do
    test "mapea cada dirección" do
      assert Solicitud.soap_operation(:emitidos) == "SolicitaDescargaEmitidos"
      assert Solicitud.soap_operation(:recibidos) == "SolicitaDescargaRecibidos"
      assert Solicitud.soap_operation(:folio) == "SolicitaDescargaFolio"
    end
  end
end
