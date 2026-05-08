defmodule Sat.CsfTest do
  use ExUnit.Case, async: true

  alias Sat.Csf
  alias Sat.Csf.{ActividadEconomica, Document, Domicilio, Identificacion, Obligacion}

  @csf_path Path.join([__DIR__, "..", "fixtures", "csf.pdf"])
  @csf2_path Path.join([__DIR__, "..", "fixtures", "csf2.pdf"])

  describe "from_file/1 — csf.pdf (Omar Alexis Juan Perez)" do
    setup do
      assert {:ok, %Document{} = csf} = Csf.from_file(@csf_path)
      {:ok, csf: csf}
    end

    test "extrae datos de identificación", %{csf: csf} do
      assert %Identificacion{
               rfc: "XAXX010101000",
               curp: "XEXX010101HNEXXXA4",
               nombre: "OMAR ALEXIS",
               primer_apellido: "JUAN",
               segundo_apellido: "PEREZ"
             } = csf.identificacion
    end

    test "extrae el domicilio registrado", %{csf: csf} do
      assert %Domicilio{
               codigo_postal: "77710",
               entidad_federativa: "QUINTANA ROO",
               municipio_demarcacion_territorial: "SOLIDARIDAD"
             } = csf.domicilio
    end

    test "extrae actividades económicas como una lista de structs ordenada", %{csf: csf} do
      assert [%ActividadEconomica{orden: 1} | _] = csf.actividades_economicas
      assert Enum.all?(csf.actividades_economicas, &(&1.orden in 1..10))
      assert Enum.all?(csf.actividades_economicas, &(is_integer(&1.porcentaje) and &1.porcentaje in 0..100))

      first = hd(csf.actividades_economicas)
      assert String.match?(first.fecha_inicio, ~r/^\d{2}\/\d{2}\/\d{4}$/)
    end

    test "extrae al menos un régimen y enriquece con código de catálogo", %{csf: csf} do
      assert csf.regimenes != []

      Enum.each(csf.regimenes, fn r ->
        assert is_binary(r.regimen)
        assert String.match?(r.fecha_inicio, ~r/^\d{2}\/\d{2}\/\d{4}$/)
      end)

      # Al menos un régimen reconocible debe tener código del catálogo SAT.
      assert Enum.any?(csf.regimenes, &(not is_nil(&1.codigo)))
    end
  end

  describe "from_file/1 — csf2.pdf (Amir Misael Marin Coh)" do
    setup do
      assert {:ok, %Document{} = csf} = Csf.from_file(@csf2_path)
      {:ok, csf: csf}
    end

    test "RFC, CURP y nombre del contribuyente", %{csf: csf} do
      IO.inspect(csf, label: "Identificación extraída")
      assert csf.identificacion.rfc == "XAXX010101000"
      assert csf.identificacion.curp == "XEXX010101HNEXXXA4"
      assert csf.identificacion.nombre == "AMIR MISAEL"
      assert csf.identificacion.primer_apellido == "MARIN"
      assert csf.identificacion.segundo_apellido == "COH"
    end

    test "domicilio completo", %{csf: csf} do
      assert csf.domicilio.codigo_postal == "77728"
      assert csf.domicilio.tipo_vialidad =~ "AVENIDA"
      assert csf.domicilio.numero_exterior == "345"
      assert csf.domicilio.numero_interior == "11"
      assert csf.domicilio.colonia == "LUIS DONALDO COLOSIO"
      assert csf.domicilio.localidad == "PLAYA DEL CARMEN"
      assert csf.domicilio.municipio_demarcacion_territorial == "SOLIDARIDAD"
      assert csf.domicilio.entidad_federativa == "QUINTANA ROO"
    end

    test "dos actividades económicas con porcentajes 90 y 10", %{csf: csf} do
      assert length(csf.actividades_economicas) == 2

      [a1, a2] = csf.actividades_economicas
      assert a1.orden == 1
      assert a1.actividad_economica == "Asalariado"
      assert a1.porcentaje == 90
      assert a1.fecha_inicio == "29/06/2015"
      assert a1.fecha_fin == nil

      assert a2.orden == 2
      assert a2.actividad_economica =~ "consultoría"
      assert a2.porcentaje == 10
      assert a2.fecha_inicio == "31/10/2023"
    end

    test "régimenes con código del catálogo SAT", %{csf: csf} do
      assert length(csf.regimenes) == 2

      sueldos = Enum.find(csf.regimenes, &(&1.regimen =~ "Sueldos"))
      assert sueldos.codigo == "605"
      assert sueldos.fecha_inicio == "29/06/2015"

      resico = Enum.find(csf.regimenes, &(&1.regimen =~ "Simplificado de Confianza"))
      assert resico.codigo == "626"
      assert resico.fecha_inicio == "31/10/2023"
    end

    test "obligaciones se reconstruyen desde múltiples líneas", %{csf: csf} do
      assert length(csf.obligaciones) == 3

      Enum.each(csf.obligaciones, fn ob ->
        assert %Obligacion{} = ob
        assert ob.fecha_inicio == "31/10/2023"
        assert is_binary(ob.descripcion_obligacion) and ob.descripcion_obligacion != ""
        assert is_binary(ob.descripcion_vencimiento) and ob.descripcion_vencimiento != ""
      end)

      pago_isr = Enum.find(csf.obligaciones, &(&1.descripcion_obligacion =~ "ISR"))
      assert pago_isr != nil
      assert pago_isr.descripcion_obligacion =~ "Régimen Simplificado de Confianza"
      assert pago_isr.descripcion_vencimiento =~ "día 17"
    end
  end

  describe "from_binary/1" do
    test "acepta el contenido del PDF como binario" do
      bin = File.read!(@csf2_path)
      assert {:ok, %Document{identificacion: %{rfc: "XAXX010101000"}}} = Csf.from_binary(bin)
    end
  end

  describe "from_result/1" do
    test "acepta un %Pdf.Reader.Result{} ya extraído" do
      {:ok, doc} = Pdf.Reader.open(@csf2_path)
      {:ok, result, _} = Pdf.Reader.read(doc, dictionary: :es)

      assert {:ok, %Document{identificacion: %{rfc: "XAXX010101000"}}} = Csf.from_result(result)
    end
  end

  describe "guards" do
    test "from_binary/1 sólo acepta binarios que comiencen con %PDF-" do
      assert_raise FunctionClauseError, fn ->
        Csf.from_binary("not a pdf")
      end
    end
  end
end
