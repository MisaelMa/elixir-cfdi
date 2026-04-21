defmodule Cdfi.MixProject do
  use Mix.Project

  def project do
    [
      app: :cdfi,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    cfdi_apps() ++ sat_apps() ++ clir_apps() ++ renapo_apps()
  end

  defp cfdi_apps do
    [
      {:cfdi_cancelacion, path: "apps/cfdi/cancelacion"},
      {:cfdi_catalogos, path: "apps/cfdi/catalogos"},
      {:cfdi_cleaner, path: "apps/cfdi/cleaner"},
      {:cfdi_complementos, path: "apps/cfdi/complementos"},
      {:cfdi_csd, path: "apps/cfdi/csd"},
      {:cfdi_csf, path: "apps/cfdi/csf"},
      {:cfdi_descarga, path: "apps/cfdi/descarga"},
      {:cfdi_designs, path: "apps/cfdi/designs"},
      {:cfdi_elements, path: "apps/cfdi/elements"},
      {:cfdi_estado, path: "apps/cfdi/estado"},
      {:cfdi_expresiones, path: "apps/cfdi/expresiones"},
      {:cfdi_pdf, path: "apps/cfdi/pdf"},
      {:cfdi_retenciones, path: "apps/cfdi/retenciones"},
      {:cfdi_rfc, path: "apps/cfdi/rfc"},
      {:cfdi_schema, path: "apps/cfdi/schema"},
      {:cfdi_transform, path: "apps/cfdi/transform"},
      {:cfdi_types, path: "apps/cfdi/types"},
      {:cfdi_utils, path: "apps/cfdi/utils"},
      {:cfdi_validador, path: "apps/cfdi/validador"},
      {:cfdi_xml, path: "apps/cfdi/xml"},
      {:cfdi_xml2json, path: "apps/cfdi/xml2json"},
      {:cfdi_xsd, path: "apps/cfdi/xsd"}
    ]
  end

  defp sat_apps do
    [
      {:sat_auth, path: "apps/sat/auth"},
      {:sat_banxico, path: "apps/sat/banxico"},
      {:sat_captcha, path: "apps/sat/captcha"},
      {:sat_contabilidad, path: "apps/sat/contabilidad"},
      {:sat_diot, path: "apps/sat/diot"},
      {:sat_opinion, path: "apps/sat/opinion"},
      {:sat_pacs, path: "apps/sat/pacs"},
      {:sat_recursos, path: "apps/sat/recursos"},
      {:sat_scraper, path: "apps/sat/scraper"}
    ]
  end

  defp clir_apps do
    [
      {:clir_openssl, path: "apps/clir/openssl"},
      {:saxon_he, path: "apps/clir/saxon_he"},
      {:releaser, path: "apps/clir/releaser"}
    ]
  end

  defp renapo_apps do
    [
      {:renapo_curp, path: "apps/renapo/curp"}
    ]
  end

  defp aliases do
    [
      "test.all": ["cmd mix test"]
    ]
  end
end
