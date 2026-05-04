defmodule Sat.Contabilidad.Xml.Catalogo do
  @moduledoc """
  Generates Catálogo de Cuentas XML per Anexo 24.
  """

  alias Sat.Contabilidad.Types
  alias Sat.Contabilidad.Types.{ContribuyenteInfo, CuentaCatalogo}

  @ns_catalogo_13 "http://www.sat.gob.mx/esquemas/ContabilidadE/1_3/CatalogoCuentas"

  @spec build(ContribuyenteInfo.t(), [CuentaCatalogo.t()], String.t()) :: String.t()
  def build(info, cuentas, version \\ "1.3") do
    ns = if version == "1.3", do: @ns_catalogo_13, else: String.replace(@ns_catalogo_13, "1_3", "1_1")
    tipo_envio = Types.tipo_envio_value(info.tipo_envio)
    natur_value = fn n -> Types.naturaleza_cuenta_value(n) end

    cuentas_xml =
      cuentas
      |> Enum.map(fn c ->
        sub_cta = if c.sub_cta_de, do: ~s( SubCtaDe="#{c.sub_cta_de}"), else: ""
        ~s(  <catalogocuentas:Ctas CodAgrup="#{c.cod_agrup}" NumCta="#{c.num_cta}" Desc="#{c.desc}"#{sub_cta} Nivel="#{c.nivel}" Natur="#{natur_value.(c.natur)}"/>)
      end)
      |> Enum.join("\n")

    """
    <?xml version="1.0" encoding="utf-8"?>
    <catalogocuentas:Catalogo xmlns:catalogocuentas="#{ns}"
                              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                              Version="#{version}"
                              RFC="#{info.rfc}"
                              Mes="#{info.mes}"
                              Anio="#{info.anio}"
                              TipoEnvio="#{tipo_envio}">
    #{cuentas_xml}
    </catalogocuentas:Catalogo>\
    """
    |> String.trim_leading()
  end
end
