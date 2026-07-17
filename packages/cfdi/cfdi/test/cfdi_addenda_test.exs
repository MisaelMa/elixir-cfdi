defmodule CFDIAddendaTest do
  use ExUnit.Case, async: true

  alias Cfdi.Comprobante

  @files Path.expand("../../../files", __DIR__)
  @xslt_path Path.join(@files, "4.0/cadenaoriginal.xslt")

  # `<xs:any maxOccurs="unbounded"/>`: contenido arbitrario, sin validar.
  # Esta addenda mezcla atributos, elementos anidados, repetidos y texto.
  @addenda_xml """
  <?xml version="1.0" encoding="UTF-8"?>
  <cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0" Total="100.00">
    <cfdi:Emisor Rfc="EKU9003173C9" Nombre="ESCUELA KEMPER URGATE" RegimenFiscal="601"/>
    <cfdi:Addenda>
      <proveedor:Pedido xmlns:proveedor="http://ejemplo.com/proveedor" numero="OC-4471" area="Compras">
        <proveedor:Contacto correo="pagos@ejemplo.com"/>
        <proveedor:Linea sku="A-1" cantidad="2"/>
        <proveedor:Linea sku="B-7" cantidad="5"/>
        <proveedor:Comentarios>Entregar en almacén 3</proveedor:Comentarios>
      </proveedor:Pedido>
    </cfdi:Addenda>
  </cfdi:Comprobante>
  """

  defp decoded_addenda() do
    {:ok, cfdi} = CFDI.from_xml(@addenda_xml)
    Map.get(cfdi.comprobante, :"cfdi:Addenda")
  end

  defp tree!(xml) do
    {:ok, parsed} = Saxy.SimpleForm.parse_string(xml)
    norm(parsed)
  end

  defp norm({name, attrs, children}) do
    kids =
      children
      |> Enum.reject(&(is_binary(&1) and String.trim(&1) == ""))
      |> Enum.map(&norm/1)

    {name, Enum.sort(attrs), kids}
  end

  defp norm(text) when is_binary(text), do: String.trim(text)

  describe "from_xml/2 — decodificación" do
    test "preserva la addenda como carga opaca" do
      addenda = decoded_addenda()

      assert is_map(addenda)
      assert %{"proveedor:Pedido" => pedido} = addenda
      assert pedido[:numero] == "OC-4471"
      assert pedido[:area] == "Compras"
    end

    test "conserva la declaración xmlns del contenido de la addenda" do
      %{"proveedor:Pedido" => pedido} = decoded_addenda()

      assert pedido[:"xmlns:proveedor"] == "http://ejemplo.com/proveedor"
    end

    test "respeta la convención átomo=atributo / string=elemento" do
      %{"proveedor:Pedido" => pedido} = decoded_addenda()

      assert pedido[:numero] == "OC-4471"
      assert %{"proveedor:Contacto" => %{correo: "pagos@ejemplo.com"}} = pedido
    end

    test "elementos repetidos se decodifican como lista" do
      %{"proveedor:Pedido" => pedido} = decoded_addenda()

      assert [%{sku: "A-1", cantidad: "2"}, %{sku: "B-7", cantidad: "5"}] =
               pedido["proveedor:Linea"]
    end

    test "un elemento de solo texto se decodifica como texto, no como atributo" do
      %{"proveedor:Pedido" => pedido} = decoded_addenda()

      assert pedido["proveedor:Comentarios"] == "Entregar en almacén 3"
    end

    test "sin addenda el campo queda en nil" do
      {:ok, cfdi} =
        CFDI.from_xml(~s(<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" Version="4.0"/>))

      assert Map.get(cfdi.comprobante, :"cfdi:Addenda") == nil
    end
  end

  describe "roundtrip" do
    test "la addenda sobrevive el ida y vuelta completa" do
      {:ok, cfdi} = CFDI.from_xml(@addenda_xml)

      assert tree!(CFDI.to_xml(cfdi)) == tree!(@addenda_xml)
    end

    test "sin addenda no se emite el nodo" do
      cfdi = CFDI.new(%Comprobante{Version: "4.0"})

      refute CFDI.to_xml(cfdi) =~ "Addenda"
    end
  end

  describe "orden del Anexo 20" do
    test "la addenda se emite al final, después del complemento" do
      comprobante =
        %Comprobante{Version: "4.0"}
        |> Comprobante.add_emisor(%{Rfc: "EKU9003173C9", Nombre: "X", RegimenFiscal: "601"})
        |> Comprobante.add_complemento(%Cfdi.Complemento{
          children: [Cfdi.Complementos.Tfd.new(%{UUID: "abc"})]
        })
        |> Comprobante.set_addenda(%{"mi:Dato" => %{valor: "1"}})

      xml = CFDI.to_xml(comprobante |> CFDI.new())

      # El Anexo 20 exige Addenda como último hijo del Comprobante.
      assert Regex.run(~r/<cfdi:Complemento>/, xml)
      posicion_complemento = :binary.match(xml, "<cfdi:Complemento>") |> elem(0)
      posicion_addenda = :binary.match(xml, "<cfdi:Addenda>") |> elem(0)

      assert posicion_addenda > posicion_complemento
    end
  end

  describe "set_addenda/2" do
    test "acepta un mapa opaco" do
      comprobante = %Comprobante{} |> Comprobante.set_addenda(%{"x:Y" => %{a: "1"}})

      assert Map.get(comprobante, :"cfdi:Addenda") == %{"x:Y" => %{a: "1"}}
    end

    test "nil borra la addenda" do
      comprobante =
        %Comprobante{}
        |> Comprobante.set_addenda(%{"x:Y" => %{a: "1"}})
        |> Comprobante.set_addenda(nil)

      assert Map.get(comprobante, :"cfdi:Addenda") == nil
    end
  end

  describe "la addenda NO afecta el sello" do
    # El XSLT oficial de cadena original (packages/files/4.0/cadenaoriginal.xslt)
    # no tiene ni un template para Addenda: el template raíz aplica sólo a
    # InformacionGlobal, Emisor, Receptor, Conceptos, Impuestos y Complemento.
    # Por eso la addenda es lo único que se puede tocar en un CFDI ya timbrado
    # sin invalidar su sello. Esto lo verificamos contra el XSLT real, no de
    # memoria.
    test "la cadena original es idéntica con y sin addenda" do
      base =
        %Comprobante{Version: "4.0", Fecha: "2026-03-03T09:50:20", SubTotal: "1", Total: "1"}
        |> Comprobante.add_emisor(%{
          Rfc: "LAN7008173R5",
          Nombre: "CINDEMEX SA DE CV",
          RegimenFiscal: "601"
        })

      con_addenda =
        Comprobante.set_addenda(base, %{
          "proveedor:Pedido" => %{
            :"xmlns:proveedor" => "http://ejemplo.com/proveedor",
            :numero => "OC-4471"
          }
        })

      {:ok, cadena_sin} = base |> CFDI.new() |> CFDI.generar_cadena_original(xslt: @xslt_path)
      {:ok, cadena_con} = con_addenda |> CFDI.new() |> CFDI.generar_cadena_original(xslt: @xslt_path)

      assert cadena_con == cadena_sin
    end
  end
end
