defmodule Mix.Tasks.Releaser.Status do
  @shortdoc "Compare local versions against Hex to see what needs publishing"
  @moduledoc """
  Shows which apps have version differences compared to what's published on Hex.

  ## Usage

      mix releaser.status

  ## Output

      Package              Local       Hex         Status
      cfdi_xml             4.0.19      4.0.18      ahead
      cfdi_csd             4.0.16      4.0.16      published
      cfdi_complementos    4.0.18-dev.1  4.0.17    pre-release
      my_new_app           0.1.0       —           unpublished
  """

  use Mix.Task

  alias Releaser.{HexStatus, UI}

  @impl Mix.Task
  def run(_args) do
    UI.info("\n#{UI.bright("=== Release Status ===")}\n")
    UI.info("Checking Hex registry...\n")

    results = HexStatus.check()

    # Table header
    UI.info(
      UI.table_row(
        [UI.bright("Package"), UI.bright("Local"), UI.bright("Hex"), UI.bright("Status")],
        [25, 18, 18, 15]
      )
    )

    UI.info(String.duplicate("─", 78))

    Enum.each(results, fn %{app: app, local: local, hex: hex, status: status} ->
      hex_display = hex || "—"

      status_display =
        case status do
          :ahead -> UI.yellow("ahead")
          :published -> UI.green("published")
          :unpublished -> UI.cyan("unpublished")
          :prerelease -> UI.dim("pre-release")
        end

      UI.info(UI.table_row([app, local, hex_display, status_display], [25, 18, 18, 15]))
    end)

    ahead = Enum.count(results, &(&1.status == :ahead))
    unpublished = Enum.count(results, &(&1.status == :unpublished))

    UI.info("")

    if ahead + unpublished > 0 do
      UI.info("#{UI.yellow("#{ahead + unpublished} package(s) need publishing.")}")
      UI.info("Run #{UI.bright("mix releaser.publish --dry-run")} to see the plan.\n")
    else
      UI.info("#{UI.green("All packages are up to date.")}\n")
    end
  end
end
