defmodule SAT_CFDI.MixProject do
  use Mix.Project

  def project do
    [
      app: :sat_cfdi,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releaser: [apps_root: "packages"]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    cfdi_apps() ++
      sat_apps() ++
      clir_apps() ++
      renapo_apps() ++
      [
        {:releaser, "~> 0.0.4", only: :dev, runtime: false}
      ]
  end

  defp cfdi_apps do
    [
      {:cfdi_catalogos_codegen, path: "packages/cfdi/catalogos_codegen", only: :dev, runtime: false},
      {:cfdi_cancelacion, path: "packages/cfdi/cancelacion"},
      {:cfdi_catalogos, path: "packages/cfdi/catalogos"},
      {:cfdi_cleaner, path: "packages/cfdi/cleaner"},
      {:cfdi_complementos, path: "packages/cfdi/complementos"},
      {:cfdi_certificados, path: "packages/cfdi/certificados"},
      {:cfdi_csf, path: "packages/cfdi/csf"},
      {:cfdi_descarga, path: "packages/cfdi/descarga"},
      {:cfdi_designs, path: "packages/cfdi/designs"},
      {:cfdi_elements, path: "packages/cfdi/elements"},
      {:cfdi_estado, path: "packages/cfdi/estado"},
      {:cfdi_expresiones, path: "packages/cfdi/expresiones"},
      {:cfdi_pdf, path: "packages/cfdi/pdf"},
      {:cfdi_retenciones, path: "packages/cfdi/retenciones"},
      {:cfdi_rfc, path: "packages/cfdi/rfc"},
      {:cfdi_schema, path: "packages/cfdi/schema"},
      {:cfdi_transform, path: "packages/cfdi/transform"},
      {:cfdi_types, path: "packages/cfdi/types"},
      {:cfdi_utils, path: "packages/cfdi/utils"},
      {:cfdi_validador, path: "packages/cfdi/validador"},
      {:cfdi, path: "packages/cfdi/cfdi"},
      {:cfdi_xml2json, path: "packages/cfdi/xml2json"},
      {:cfdi_xsd, path: "packages/cfdi/xsd"}
    ]
  end

  defp sat_apps do
    [
      {:sat_auth, path: "packages/sat/auth"},
      {:sat_banxico, path: "packages/sat/banxico"},
      {:sat_captcha, path: "packages/sat/captcha"},
      {:sat_contabilidad, path: "packages/sat/contabilidad"},
      {:sat_diot, path: "packages/sat/diot"},
      {:sat_opinion, path: "packages/sat/opinion"},
      {:sat_pacs, path: "packages/sat/pacs"},
      {:sat_recursos, path: "packages/sat/recursos"},
      {:sat_scraper, path: "packages/sat/scraper"}
    ]
  end

  defp clir_apps do
    [
      {:clir_openssl, path: "packages/clir/openssl"},
      {:saxon_he, path: "packages/clir/saxon_he"}
    ]
  end

  defp renapo_apps do
    [
      {:renapo_curp, path: "packages/renapo/curp"}
    ]
  end

  defp aliases do
    [
      "test.all": ["cmd mix test"]
    ]
  end
end
