defmodule Cfdi.Retenciones.Builders.Retencion20 do
  @moduledoc """
  Builds Retenciones 2.0 XML document.
  """

  alias Cfdi.Retenciones.Types
  alias Cfdi.Retenciones.Types.{Retencion20, EmisorRetencion, ReceptorRetencion, ComplementoRetencion}

  @p "retenciones"

  @spec build(Retencion20.t()) :: String.t()
  def build(%Retencion20{} = doc) do
    t = doc.totales
    p = doc.periodo

    root_attrs =
      ~s( xmlns:#{@p}="#{Types.namespace_v2()}") <>
        ~s( Version="#{esc(doc.version)}") <>
        ~s( CveRetenc="#{esc(doc.cve_retenc)}") <>
        opt_attr("DescRetenc", doc.desc_retenc) <>
        ~s( FechaExp="#{esc(doc.fecha_exp)}") <>
        ~s( LugarExpRet="#{esc(doc.lugar_exp_ret)}") <>
        opt_attr("NumCert", doc.num_cert) <>
        opt_attr("FolioInt", doc.folio_int)

    body =
      build_emisor(doc.emisor) <>
        build_receptor(doc.receptor) <>
        ~s(<#{@p}:Periodo MesIni="#{esc(p.mes_ini)}" MesFin="#{esc(p.mes_fin)}" Ejerc="#{esc(p.ejerc)}"/>) <>
        ~s(<#{@p}:Totales) <>
        ~s( montoTotOperacion="#{esc(t.monto_tot_operacion)}") <>
        ~s( montoTotGrav="#{esc(t.monto_tot_grav)}") <>
        ~s( montoTotExent="#{esc(t.monto_tot_exent)}") <>
        ~s( montoTotRet="#{esc(t.monto_tot_ret)}") <>
        ~s(/>) <>
        build_complemento(doc.complemento)

    ~s(<?xml version="1.0" encoding="UTF-8"?><#{@p}:Retenciones#{root_attrs}>#{body}</#{@p}:Retenciones>)
  end

  defp build_emisor(%EmisorRetencion{} = e) do
    ~s(<#{@p}:Emisor) <>
      ~s( Rfc="#{esc(e.rfc)}") <>
      opt_attr("NomDenRazSocE", e.nom_den_raz_soc_e) <>
      ~s( RegimenFiscalE="#{esc(e.regimen_fiscal_e)}") <>
      opt_attr("CURPE", e.curp_e) <>
      ~s(/>)
  end

  defp build_receptor(%ReceptorRetencion{} = r) do
    inner =
      cond do
        r.nacionalidad_r == "Nacional" && r.nacional ->
          n = r.nacional
          ~s(<#{@p}:Nacional) <>
            ~s( RFCRecep="#{esc(n.rfc_recep)}") <>
            opt_attr("NomDenRazSocR", n.nom_den_raz_soc_r) <>
            opt_attr("CURPR", n.curp_r) <>
            ~s(/>)

        r.nacionalidad_r == "Extranjero" && r.extranjero ->
          e = r.extranjero
          ~s(<#{@p}:Extranjero) <>
            opt_attr("NumRegIdTrib", e.num_reg_id_trib) <>
            ~s( NomDenRazSocR="#{esc(e.nom_den_raz_soc_r)}") <>
            ~s(/>)

        true ->
          ""
      end

    ~s(<#{@p}:Receptor Nacionalidad="#{esc(r.nacionalidad_r)}">#{inner}</#{@p}:Receptor>)
  end

  defp build_complemento(nil), do: ""
  defp build_complemento([]), do: ""

  defp build_complemento(complementos) do
    body = Enum.map_join(complementos, "", fn %ComplementoRetencion{inner_xml: xml} -> xml end)
    ~s(<#{@p}:Complemento>#{body}</#{@p}:Complemento>)
  end

  defp esc(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace(~s("), "&quot;")
  end

  defp opt_attr(_name, nil), do: ""
  defp opt_attr(_name, ""), do: ""
  defp opt_attr(name, value), do: ~s( #{name}="#{esc(value)}")
end
