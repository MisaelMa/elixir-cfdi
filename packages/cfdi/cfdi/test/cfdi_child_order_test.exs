defmodule CFDIChildOrderTest do
  use ExUnit.Case, async: true

  alias Cfdi.{Complemento, Comprobante}
  alias Cfdi.Complementos.{Nomina12, Pago20}

  # Los payloads de complemento son mapas opacos, y un mapa no expresa orden:
  # los mapas chicos de Elixir iteran por término, o sea alfabético. El XSD del
  # SAT declara `<xs:sequence>`, así que el orden es parte del contrato y un
  # documento desordenado se rechaza en validación de esquema.
  #
  # Estos tests fijan las dos fuentes de orden que resuelven eso:
  #   * el catálogo generado desde los XSLT del SAT, para lo armado a mano
  #   * `:__order__`, para lo que viene de un XML (ver cfdi_from_xml_test)

  defp xml_de(complemento) do
    %Comprobante{Version: "4.0"}
    |> Comprobante.add_complemento(%Complemento{children: [complemento]})
    |> CFDI.new()
    |> CFDI.to_xml()
  end

  # El tag tiene que TERMINAR ahí: buscar "<pago20:Pago" a secas matchearía
  # primero contra su propio padre `<pago20:Pagos>`.
  defp posiciones(xml, tags) do
    Enum.map(tags, fn tag ->
      case Regex.run(~r/<#{Regex.escape(tag)}[\s\/>]/, xml, return: :index) do
        [{pos, _}] -> pos
        nil -> flunk("no encontré <#{tag}> en:\n#{xml}")
      end
    end)
  end

  defp assert_orden(xml, tags) do
    posiciones = posiciones(xml, tags)

    assert posiciones == Enum.sort(posiciones),
           "los tags no salieron en el orden #{inspect(tags)}:\n#{xml}"
  end

  describe "catálogo generado — complementos armados a mano" do
    test "Pago20 emite Totales antes que Pago, no en orden alfabético" do
      xml =
        Pago20.new(%{
          :"xmlns:pago20" => "http://www.sat.gob.mx/Pagos20",
          :Version => "2.0",
          "pago20:Totales" => %{MontoTotalPagos: "100"},
          "pago20:Pago" => %{FechaPago: "2026-01-01"}
        })
        |> xml_de()

      # Alfabéticamente "Pago" < "Totales" — el SAT exige lo contrario.
      assert_orden(xml, ["pago20:Totales", "pago20:Pago"])
    end

    test "Nomina12 respeta la secuencia del Anexo 20" do
      xml =
        Nomina12.new(%{
          :"xmlns:nomina12" => "http://www.sat.gob.mx/nomina12",
          :Version => "1.2",
          "nomina12:Deducciones" => %{TotalOtrasDeducciones: "10"},
          "nomina12:Percepciones" => %{TotalSueldos: "100"},
          "nomina12:Receptor" => %{Curp: "XEXX010101HNEXXXA4"},
          "nomina12:Emisor" => %{RegistroPatronal: "X"}
        })
        |> xml_de()

      assert_orden(xml, [
        "nomina12:Emisor",
        "nomina12:Receptor",
        "nomina12:Percepciones",
        "nomina12:Deducciones"
      ])
    end
  end

  describe ":__order__ explícito" do
    test "gana sobre el catálogo generado" do
      xml =
        Pago20.new(%{
          :"xmlns:pago20" => "http://www.sat.gob.mx/Pagos20",
          :__order__ => ["pago20:Pago", "pago20:Totales"],
          "pago20:Totales" => %{MontoTotalPagos: "100"},
          "pago20:Pago" => %{FechaPago: "2026-01-01"}
        })
        |> xml_de()

      # El catálogo diría Totales→Pago; el orden explícito manda.
      assert_orden(xml, ["pago20:Pago", "pago20:Totales"])
    end

    test "nunca se emite como atributo XML" do
      xml =
        Pago20.new(%{
          :"xmlns:pago20" => "http://www.sat.gob.mx/Pagos20",
          :__order__ => ["pago20:Totales", "pago20:Pago"],
          "pago20:Totales" => %{MontoTotalPagos: "100"},
          "pago20:Pago" => %{FechaPago: "2026-01-01"}
        })
        |> xml_de()

      refute xml =~ "__order__"
    end

    test "no aparece en to_map/2 ni en to_json/2 — es metadata, no dato fiscal" do
      cfdi =
        %Comprobante{Version: "4.0"}
        |> Comprobante.set_addenda(%{
          :__order__ => ["x:B", "x:A"],
          "x:A" => %{v: "1"},
          "x:B" => %{v: "2"}
        })
        |> CFDI.new()

      refute inspect(CFDI.to_map(cfdi)) =~ "__order__"
      refute CFDI.to_json(cfdi) =~ "__order__"
      # …pero el XML sí lo respeta.
      assert_orden(CFDI.to_xml(cfdi), ["x:B", "x:A"])
    end
  end

  describe "complementos planos" do
    test "un complemento sin hijos no lleva orden ni se rompe" do
      xml =
        Cfdi.Complementos.Tfd.new(%{
          :"xmlns:tfd" => "http://www.sat.gob.mx/TimbreFiscalDigital",
          :UUID => "5e2d6aff-2dd7-43d1-83d3-14c1aca396d9"
        })
        |> xml_de()

      assert xml =~ ~s(UUID="5e2d6aff-2dd7-43d1-83d3-14c1aca396d9")
      refute xml =~ "__order__"
    end
  end
end
