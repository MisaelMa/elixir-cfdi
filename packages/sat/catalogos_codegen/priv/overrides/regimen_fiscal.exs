# RegimenFiscal override — no atom names (this catalog uses string codes only).
# The `descriptions` map is used to supply labels for XSD codes that appear in the
# XSD enumeration but are absent from (or removed in) the XLSX.
# Phase 9 (running against the real catCFDI.xlsx) will surface actual deprecated
# codes and their labels; they can be added here at that point.
%{
  enum_names: %{},
  descriptions: %{
    # Codes present in the XSD but absent from the XLSX (deprecated by SAT).
    # Canonical descriptions sourced from node-cfdi.
    "609" => "Consolidación",
    "628" => "Hidrocarburos",
    "629" => "De los Regímenes Fiscales Preferentes y de las Empresas Multinacionales",
    "630" => "Enajenación de acciones en bolsa de valores"
  }
}
