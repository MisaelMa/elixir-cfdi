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

  describe "soap_operation/1 (dirección → operación)" do
    test "mapea cada dirección" do
      assert Solicitud.soap_operation(:emitidos) == "SolicitaDescargaEmitidos"
      assert Solicitud.soap_operation(:recibidos) == "SolicitaDescargaRecibidos"
      assert Solicitud.soap_operation(:folio) == "SolicitaDescargaFolio"
    end
  end
end
