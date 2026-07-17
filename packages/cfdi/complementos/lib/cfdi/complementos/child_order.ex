defmodule Cfdi.Complementos.ChildOrder do
  @moduledoc """
  Orden canónico de los hijos de cada complemento, según el SAT.

  **Módulo generado — no editar a mano.** Se regenera con:

      mix cfdi.complementos.gen_child_order

  La fuente son los XSLT oficiales de cadena original
  (`packages/files/4.0/complementos/`), que recorren los hijos en la
  secuencia que declara el XSD. Ver
  `Mix.Tasks.Cfdi.Complementos.GenChildOrder`.

  Lo consume `CFDI.to_xml/2` para serializar complementos armados a mano
  en el orden que exige el SAT — un mapa no puede expresar orden por sí
  solo, e ir alfabético produce XML que el PAC rechaza.

  Sólo aparecen elementos con 2+ nombres de hijo distintos.
  """

  @order %{
    "cartaporte20:Autotransporte" => [
      "cartaporte20:IdentificacionVehicular",
      "cartaporte20:Seguros",
      "cartaporte20:Remolques"
    ],
    "cartaporte20:CartaPorte" => [
      "cartaporte20:Ubicaciones",
      "cartaporte20:Mercancias",
      "cartaporte20:FiguraTransporte"
    ],
    "cartaporte20:Mercancia" => [
      "cartaporte20:Pedimentos",
      "cartaporte20:GuiasIdentificacion",
      "cartaporte20:CantidadTransporta",
      "cartaporte20:DetalleMercancia"
    ],
    "cartaporte20:Mercancias" => [
      "cartaporte20:Mercancia",
      "cartaporte20:Autotransporte",
      "cartaporte20:TransporteMaritimo",
      "cartaporte20:TransporteAereo",
      "cartaporte20:TransporteFerroviario"
    ],
    "cartaporte20:TransporteFerroviario" => ["cartaporte20:DerechosDePaso", "cartaporte20:Carro"],
    "cartaporte30:Autotransporte" => [
      "cartaporte30:IdentificacionVehicular",
      "cartaporte30:Seguros",
      "cartaporte30:Remolques"
    ],
    "cartaporte30:CartaPorte" => [
      "cartaporte30:Ubicaciones",
      "cartaporte30:Mercancias",
      "cartaporte30:FiguraTransporte"
    ],
    "cartaporte30:Mercancia" => [
      "cartaporte30:DocumentacionAduanera",
      "cartaporte30:GuiasIdentificacion",
      "cartaporte30:CantidadTransporta",
      "cartaporte30:DetalleMercancia"
    ],
    "cartaporte30:Mercancias" => [
      "cartaporte30:Mercancia",
      "cartaporte30:Autotransporte",
      "cartaporte30:TransporteMaritimo",
      "cartaporte30:TransporteAereo",
      "cartaporte30:TransporteFerroviario"
    ],
    "cartaporte30:TransporteFerroviario" => ["cartaporte30:DerechosDePaso", "cartaporte30:Carro"],
    "cartaporte30:TransporteMaritimo" => ["cartaporte30:Contenedor", "cartaporte30:RemolquesCCP"],
    "cartaporte31:Autotransporte" => [
      "cartaporte31:IdentificacionVehicular",
      "cartaporte31:Seguros",
      "cartaporte31:Remolques"
    ],
    "cartaporte31:CartaPorte" => [
      "cartaporte31:RegimenesAduaneros",
      "cartaporte31:Ubicaciones",
      "cartaporte31:Mercancias",
      "cartaporte31:FiguraTransporte"
    ],
    "cartaporte31:Mercancia" => [
      "cartaporte31:DocumentacionAduanera",
      "cartaporte31:GuiasIdentificacion",
      "cartaporte31:CantidadTransporta",
      "cartaporte31:DetalleMercancia"
    ],
    "cartaporte31:Mercancias" => [
      "cartaporte31:Mercancia",
      "cartaporte31:Autotransporte",
      "cartaporte31:TransporteMaritimo",
      "cartaporte31:TransporteAereo",
      "cartaporte31:TransporteFerroviario"
    ],
    "cartaporte31:TransporteFerroviario" => ["cartaporte31:DerechosDePaso", "cartaporte31:Carro"],
    "cce11:ComercioExterior" => [
      "cce11:Emisor",
      "cce11:Propietario",
      "cce11:Receptor",
      "cce11:Destinatario",
      "cce11:Mercancias"
    ],
    "cce20:ComercioExterior" => [
      "cce20:Emisor",
      "cce20:Propietario",
      "cce20:Receptor",
      "cce20:Destinatario",
      "cce20:Mercancias"
    ],
    "decreto:DecretoRenovVehicular" => [
      "decreto:VehiculosUsadosEnajenadoPermAlFab",
      "decreto:VehiculoNuvoSemEnajenadoFabAlPerm"
    ],
    "decreto:DecretoSustitVehicular" => [
      "decreto:VehiculoUsadoEnajenadoPermAlFab",
      "decreto:VehiculoNuvoSemEnajenadoFabAlPerm"
    ],
    "decreto:renovacionysustitucionvehiculos" => [
      "decreto:DecretoRenovVehicular",
      "decreto:DecretoSustitVehicular"
    ],
    "destruccion:certificadodedestruccion" => [
      "destruccion:VehiculoDestruido",
      "destruccion:InformacionAduanera"
    ],
    "gceh:Erogacion" => ["gceh:DocumentoRelacionado", "gceh:Actividades", "gceh:CentroCostos"],
    "nomina12:Nomina" => [
      "nomina12:Emisor",
      "nomina12:Receptor",
      "nomina12:Percepciones",
      "nomina12:Deducciones",
      "nomina12:OtrosPagos",
      "nomina12:Incapacidades"
    ],
    "nomina12:OtroPago" => ["nomina12:SubsidioAlEmpleo", "nomina12:CompensacionSaldosAFavor"],
    "nomina12:Percepcion" => ["nomina12:AccionesOTitulos", "nomina12:HorasExtra"],
    "nomina12:Percepciones" => [
      "nomina12:Percepcion",
      "nomina12:JubilacionPensionRetiro",
      "nomina12:SeparacionIndemnizacion"
    ],
    "notariospublicos:DatosAdquiriente" => [
      "notariospublicos:DatosUnAdquiriente",
      "notariospublicos:DatosAdquirientesCopSC"
    ],
    "notariospublicos:DatosEnajenante" => [
      "notariospublicos:DatosUnEnajenante",
      "notariospublicos:DatosEnajenantesCopSC"
    ],
    "notariospublicos:NotariosPublicos" => [
      "notariospublicos:DescInmuebles",
      "notariospublicos:DatosOperacion",
      "notariospublicos:DatosNotario",
      "notariospublicos:DatosEnajenante",
      "notariospublicos:DatosAdquiriente"
    ],
    "pago20:ImpuestosP" => ["pago20:RetencionesP", "pago20:TrasladosP"],
    "pago20:Pago" => ["pago20:DoctoRelacionado", "pago20:ImpuestosP"],
    "pago20:Pagos" => ["pago20:Totales", "pago20:Pago"]
  }

  @doc """
  Orden canónico de los hijos de `tag`, o `nil` si no aplica (elemento
  plano, o desconocido).

      iex> Cfdi.Complementos.ChildOrder.for_tag("pago20:Pagos")
      ["pago20:Totales", "pago20:Pago"]
  """
  @spec for_tag(String.t()) :: [String.t()] | nil
  def for_tag(tag) when is_binary(tag), do: Map.get(@order, tag)

  @doc "El catálogo completo: tag → orden de sus hijos."
  @spec all() :: %{String.t() => [String.t()]}
  def all(), do: @order
end
