defmodule Mix.Tasks.Cfdi.Complementos.GenChildOrder do
  @shortdoc "Genera Cfdi.Complementos.ChildOrder desde los XSLT del SAT"

  @moduledoc """
  Genera `Cfdi.Complementos.ChildOrder` a partir de los XSLT oficiales de
  cadena original que publica el SAT.

      mix cfdi.complementos.gen_child_order

  ## Por qué se genera y no se escribe a mano

  El XSD del SAT declara los hijos de cada complemento con `<xs:sequence>`:
  el orden es parte del contrato y un documento desordenado se rechaza en
  validación de esquema.

  Los payloads de complemento son mapas opacos, y un mapa no puede expresar
  orden (los mapas chicos de Elixir iteran por término, o sea alfabético).
  De los 33 complementos del SAT, 11 tienen hijos ordenados — y con orden
  alfabético los 11 salen inválidos. Ninguno se salva por casualidad.

  El XSLT de cadena original recorre los hijos **en la secuencia del XSD**,
  así que el orden de sus `select="./ns:Hijo"` ES el orden que exige el SAT.
  Esta tarea lo extrae de ahí: la fuente ya vive en el repo
  (`packages/files/4.0/complementos/`), no hay nada que bajar ni que
  mantener a mano. Cuando el SAT publique una versión nueva, se actualiza
  el XSLT y se vuelve a correr.

  Sólo se emiten los elementos con 2+ nombres de hijo distintos: con 0 o 1
  no hay orden que imponer.
  """

  use Mix.Task

  @xslt_dir Path.expand("../../../../../files/4.0/complementos", __DIR__)
  @output Path.expand("../../cfdi/complementos/child_order.ex", __DIR__)

  # `<xsl:template match="pago20:Pagos"> … </xsl:template>`
  @template_re ~r/<xsl:template\s+match="([^"]+)"(.*?)<\/xsl:template>/s

  # Captura tanto `<xsl:for-each select="./ns:X">` como
  # `<xsl:apply-templates select="./ns:X"/>`; ambos aparecen en los XSLT del
  # SAT y ambos marcan posición en la secuencia.
  @select_re ~r/<xsl:(?:for-each|apply-templates)\s+select="\.\/([\w.]+:[\w.]+)"/

  # Un `match` compuesto (`cfdi:Comprobante|cfdi:Concepto`, rutas, etc.) no
  # identifica un elemento único: lo ignoramos.
  @simple_tag_re ~r/^[\w.]+:[\w.]+$/

  @impl Mix.Task
  def run(_args) do
    unless File.dir?(@xslt_dir) do
      Mix.raise("no encontré los XSLT del SAT en #{@xslt_dir}")
    end

    orden =
      @xslt_dir
      |> Path.join("*.xslt")
      |> Path.wildcard()
      |> Enum.flat_map(&extraer/1)
      |> resolver_colisiones()

    if orden == %{} do
      Mix.raise("no extraje ningún orden de #{@xslt_dir} — ¿cambió el formato de los XSLT?")
    end

    File.write!(@output, render(orden))
    Mix.shell().info("Generado #{@output} con #{map_size(orden)} elementos ordenados")
  end

  defp extraer(path) do
    src = File.read!(path)

    @template_re
    |> Regex.scan(src)
    |> Enum.flat_map(fn [_full, match, body] ->
      hijos = hijos(body)

      # Con 0 o 1 hijo distinto el orden es irrelevante; no ensuciamos el mapa.
      if Regex.match?(@simple_tag_re, match) and length(hijos) > 1 do
        [{match, hijos, Path.basename(path)}]
      else
        []
      end
    end)
  end

  defp hijos(body) do
    @select_re
    |> Regex.scan(body)
    |> Enum.map(fn [_full, hijo] -> hijo end)
    |> Enum.uniq()
  end

  # Dos XSLT que declaran orden distinto para el mismo tag es una ambigüedad
  # real: reventamos en vez de dejar que uno pise al otro en silencio.
  defp resolver_colisiones(entradas) do
    entradas
    |> Enum.group_by(fn {tag, _, _} -> tag end)
    |> Map.new(fn {tag, grupo} ->
      case grupo |> Enum.map(fn {_, hijos, _} -> hijos end) |> Enum.uniq() do
        [hijos] ->
          {tag, hijos}

        _ ->
          archivos = Enum.map_join(grupo, ", ", fn {_, _, file} -> file end)
          Mix.raise("orden contradictorio para #{tag} entre: #{archivos}")
      end
    end)
  end

  defp render(orden) do
    entradas =
      orden
      |> Enum.sort_by(fn {tag, _} -> tag end)
      |> Enum.map_join(",\n", fn {tag, hijos} ->
        lista = Enum.map_join(hijos, ", ", &inspect/1)
        "    #{inspect(tag)} => [#{lista}]"
      end)

    """
    defmodule Cfdi.Complementos.ChildOrder do
      @moduledoc \"\"\"
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
      \"\"\"

      @order %{
    #{entradas}
      }

      @doc \"\"\"
      Orden canónico de los hijos de `tag`, o `nil` si no aplica (elemento
      plano, o desconocido).

          iex> Cfdi.Complementos.ChildOrder.for_tag("pago20:Pagos")
          ["pago20:Totales", "pago20:Pago"]
      \"\"\"
      @spec for_tag(String.t()) :: [String.t()] | nil
      def for_tag(tag) when is_binary(tag), do: Map.get(@order, tag)

      @doc "El catálogo completo: tag → orden de sus hijos."
      @spec all() :: %{String.t() => [String.t()]}
      def all(), do: @order
    end
    """
  end
end
