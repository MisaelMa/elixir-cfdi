defmodule Sat.Scraper do
  @moduledoc """
  HTTP scraping helpers for the SAT web portal (`Sat.Scraper.SatPortal`).
  """

  @doc false
  def version, do: Application.spec(:sat_scraper, :vsn)
end
