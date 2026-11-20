defmodule Mix.Tasks.Cfdi.Xslt.Update do
  @shortdoc "Descarga el cadenaoriginal_4_0.xslt del SAT y lo localiza en priv/"

  @moduledoc """
  Descarga el `cadenaoriginal_4_0.xslt` oficial del SAT y todos sus complementos,
  y reescribe los `xsl:include` remotos a rutas relativas para que
  `Cfdi.Transform.XsltParser` pueda seguirlos.

      mix cfdi.xslt.update
      mix cfdi.xslt.update --dest priv/xslt/4.0
      mix cfdi.xslt.update --url http://www.sat.gob.mx/.../cadenaoriginal_4_0.xslt

  Opciones:

    * `--dest` - directorio de salida (por defecto `priv/xslt/4.0`).
    * `--url`  - URL del XSLT principal (por defecto la oficial del SAT).
  """

  use Mix.Task

  alias Cfdi.Transform.XsltLocalizer

  @impl Mix.Task
  def run(args) do
    # inets/ssl no son dependencia de la libreria: se cargan solo para esta tarea.
    Mix.ensure_application!(:inets)
    Mix.ensure_application!(:ssl)

    {opts, _, _} = OptionParser.parse(args, strict: [dest: :string, url: :string])

    dest = Keyword.get(opts, :dest, "priv/xslt/4.0")
    url = Keyword.get(opts, :url, XsltLocalizer.default_url())

    Mix.shell().info("Descargando #{url} ...")

    case XsltLocalizer.update(dest, &XsltLocalizer.http_get/1, url: url) do
      {:ok, files} ->
        Mix.shell().info("OK: #{length(files)} archivos escritos en #{dest}")

      {:error, {:download_failed, failed_url, reason}} ->
        Mix.raise("No se pudo descargar #{failed_url}: #{inspect(reason)}")
    end
  end
end
