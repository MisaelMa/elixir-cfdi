defmodule Sat.Csf.Parser do
  @moduledoc """
  Parser de Constancia de Situación Fiscal (CSF) que toma el resultado
  estructurado de `Pdf.Reader.read/2` y produce un `%Sat.Csf.Document{}`.

  El parser asume que el PDF se leyó con `dictionary: :es` (necesario para
  separar palabras pegadas como `iniciode → inicio de`). `Sat.Csf.from_file/2`
  y `from_binary/2` lo configuran por defecto.

  ## Estrategia

  - Identificación y Domicilio: se extraen pares `Label: valor` con un regex
    que conoce todos los labels esperados, manejando líneas con dos columnas
    (ej. `Código Postal: 77728 Tipo de Vialidad: AVENIDA (AV.)`).

  - Actividades y Regímenes: regex sobre el texto de cada fila, anclado por el
    formato de fecha `dd/mm/yyyy` al final.

  - Obligaciones: usa las posiciones X de los tokens para separar las cuatro
    columnas (descripción, vencimiento, fecha inicio, fecha fin). Una fila se
    extiende a múltiples líneas cuando la descripción se desborda; la presencia
    de `dd/mm/yyyy` en la columna de fecha inicio marca el comienzo de cada
    obligación.
  """

  alias Pdf.Reader.Result, as: PdfResult
  alias Sat.Csf.{
    ActividadEconomica,
    Document,
    Domicilio,
    Identificacion,
    Obligacion,
    Regimen
  }

  @section_markers [
    {:identificacion, "Datos de Identificación del Contribuyente"},
    {:domicilio, "Datos del domicilio registrado"},
    {:actividades, "Actividades Económicas"},
    {:regimenes_singular, "Régimen Fecha"},
    {:regimenes, "Regímenes"},
    {:obligaciones, "Obligaciones"},
    {:fin, "Sus datos personales son incorporados"}
  ]

  @identificacion_labels [
    {:nombre_comercial, "Nombre Comercial"},
    {:nombre, "Nombre (s)"},
    {:rfc, "RFC"},
    {:curp, "CURP"},
    {:primer_apellido, "Primer Apellido"},
    {:segundo_apellido, "Segundo Apellido"},
    {:fecha_inicio_operaciones, "Fecha inicio de operaciones"},
    {:estatus_padron, "Estatus en el padrón"},
    {:fecha_ultimo_cambio_estado, "Fecha de último cambio de estado"}
  ]

  @domicilio_labels [
    {:municipio_demarcacion_territorial, "Nombre del Municipio o Demarcación Territorial"},
    {:entidad_federativa, "Nombre de la Entidad Federativa"},
    {:nombre_vialidad, "Nombre de Vialidad"},
    {:nombre_vialidad, "Nombre de la Vialidad"},
    {:colonia, "Nombre de la Colonia"},
    {:localidad, "Nombre de la Localidad"},
    {:numero_exterior, "Número Exterior"},
    {:numero_interior, "Número Interior"},
    {:tipo_vialidad, "Tipo de Vialidad"},
    {:codigo_postal, "Código Postal"},
    {:entre_calle, "Entre Calle"},
    {:y_calle, "Y Calle"},
    {:y_calle, "YCalle"}
  ]

  @date_re ~r/^\d{2}\/\d{2}\/\d{4}$/

  @doc """
  Parsea un `%Pdf.Reader.Result{}` y devuelve `{:ok, %Sat.Csf.Document{}}`.

  Retorna `{:error, :not_a_csf}` si no detecta los marcadores de sección
  esperados (sirve como guard para PDFs que no son CSF).
  """
  @spec parse(PdfResult.t()) :: {:ok, Document.t()} | {:error, :not_a_csf}
  def parse(%PdfResult{pages: pages}) do
    lines =
      pages
      |> Enum.flat_map(& &1.lines)
      |> Enum.map(&normalize_line/1)

    section_indexes = find_section_indexes(lines)

    if Map.has_key?(section_indexes, :identificacion) do
      {:ok,
       %Document{
         identificacion: parse_identificacion(slice(lines, section_indexes, :identificacion, :domicilio)),
         domicilio: parse_domicilio(slice(lines, section_indexes, :domicilio, :actividades)),
         actividades_economicas:
           parse_actividades(slice(lines, section_indexes, :actividades, :regimenes)),
         regimenes:
           parse_regimenes(slice(lines, section_indexes, :regimenes, :obligaciones)),
         obligaciones:
           parse_obligaciones(slice(lines, section_indexes, :obligaciones, :fin))
       }}
    else
      {:error, :not_a_csf}
    end
  end

  # ── Section splitting ────────────────────────────────────────

  defp normalize_line(line) do
    %{line | text: collapse_spaces(line.text)}
  end

  defp collapse_spaces(text), do: text |> String.replace(~r/\s+/u, " ") |> String.trim()

  defp find_section_indexes(lines) do
    lines
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {line, idx}, acc ->
      Enum.reduce(@section_markers, acc, fn {key, marker}, inner ->
        if not Map.has_key?(inner, key) and String.contains?(line.text, marker) do
          Map.put(inner, key, idx)
        else
          inner
        end
      end)
    end)
    |> normalize_regimenes_index()
  end

  # The section header is "Regímenes:" on its own line — but the table header
  # the next line is "Régimen Fecha Inicio Fecha Fin". If we picked up the
  # singular form first (because "Régimen" appears earlier in regimen rows),
  # discard it.
  defp normalize_regimenes_index(%{regimenes: _} = idx), do: Map.delete(idx, :regimenes_singular)
  defp normalize_regimenes_index(idx), do: Map.delete(idx, :regimenes_singular)

  defp slice(lines, indexes, from_key, to_key) do
    case {Map.get(indexes, from_key), Map.get(indexes, to_key)} do
      {nil, _} -> []
      {from, nil} -> Enum.drop(lines, from + 1)
      {from, to} when to > from -> Enum.slice(lines, (from + 1)..(to - 1))
      _ -> []
    end
  end

  # ── Identificación ───────────────────────────────────────────

  defp parse_identificacion(lines) do
    pairs = extract_label_pairs(lines, @identificacion_labels)
    struct(Identificacion, atomize_pairs(pairs, @identificacion_labels))
  end

  # ── Domicilio ────────────────────────────────────────────────

  defp parse_domicilio(lines) do
    pairs = extract_label_pairs(lines, @domicilio_labels)
    struct(Domicilio, atomize_pairs(pairs, @domicilio_labels))
  end

  # ── Actividades Económicas ───────────────────────────────────

  @actividad_re ~r/^(?<orden>\d+)\s+(?<actividad>.+?)\s+(?<porcentaje>\d{1,3})\s+(?<fecha_inicio>\d{2}\/\d{2}\/\d{4})(?:\s+(?<fecha_fin>\d{2}\/\d{2}\/\d{4}))?\s*$/u

  defp parse_actividades(lines) do
    lines
    |> drop_until_data_row()
    |> Enum.flat_map(fn line ->
      case Regex.named_captures(@actividad_re, line.text) do
        nil ->
          []

        caps ->
          [
            %ActividadEconomica{
              orden: String.to_integer(caps["orden"]),
              actividad_economica: String.trim(caps["actividad"]),
              porcentaje: String.to_integer(caps["porcentaje"]),
              fecha_inicio: presence(caps["fecha_inicio"]),
              fecha_fin: presence(caps["fecha_fin"])
            }
          ]
      end
    end)
  end

  defp drop_until_data_row(lines) do
    Enum.drop_while(lines, fn line -> not String.match?(line.text, ~r/^\d+\s+/) end)
  end

  # ── Régimenes ────────────────────────────────────────────────

  @regimen_re ~r/^(?<regimen>.+?)\s+(?<fecha_inicio>\d{2}\/\d{2}\/\d{4})(?:\s+(?<fecha_fin>\d{2}\/\d{2}\/\d{4}))?\s*$/u

  defp parse_regimenes(lines) do
    lines
    |> Enum.flat_map(fn line ->
      case Regex.named_captures(@regimen_re, line.text) do
        nil ->
          []

        caps ->
          regimen_str = String.trim(caps["regimen"])

          [
            %Regimen{
              regimen: regimen_str,
              codigo: lookup_regimen_codigo(regimen_str),
              fecha_inicio: presence(caps["fecha_inicio"]),
              fecha_fin: presence(caps["fecha_fin"])
            }
          ]
      end
    end)
  end

  defp lookup_regimen_codigo(label) do
    target = simplify_regimen(label)

    Sat.Catalogos.RegimenFiscal.list()
    |> Enum.find(&(simplify_regimen(&1.label) == target))
    |> case do
      %{value: code} -> code
      _ -> nil
    end
  end

  defp simplify_regimen(label) do
    label
    |> strip_accents()
    |> String.downcase()
    |> String.replace(~r/^regimen\s+(?:de\s+|del\s+)?/u, "")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  defp strip_accents(s) do
    s
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
  end

  # ── Obligaciones ─────────────────────────────────────────────
  #
  # The obligation table has 4 columns. Rows wrap across multiple physical
  # lines: the first line carries the start date in the fecha_inicio column,
  # subsequent lines extend the descripción/vencimiento text.
  #
  # We anchor columns from the table header line, then bin each row's tokens
  # into the column whose anchor X is the largest one ≤ the token's X.

  defp parse_obligaciones(lines) do
    case find_obligaciones_header(lines) do
      nil ->
        []

      {header_idx, header} ->
        data_lines = Enum.drop(lines, header_idx + 1)

        data_lines
        |> column_boundaries(header)
        |> case do
          [] -> []
          boundaries -> bin_rows_by_columns(data_lines, boundaries)
        end
        |> group_into_obligaciones()
    end
  end

  defp find_obligaciones_header(lines) do
    Enum.find_index(lines, fn line ->
      text = line.text

      String.contains?(text, "Descripción") and String.contains?(text, "Vencimiento") and
        String.contains?(text, "Fecha")
    end)
    |> case do
      nil -> nil
      idx -> {idx, Enum.at(lines, idx)}
    end
  end

  # The SAT obligation header centres each column label inside its column, while
  # row text is left-aligned. Naive midpoints between header anchors place the
  # col2→col3 boundary too far left (text in col2 extends almost up to col3 in
  # rows, while the header anchors are only ~150pt apart). To compensate, we
  # refine the col2→col3 boundary using the actual X of dd/mm/yyyy tokens —
  # those are the leftmost tokens of column 3 in real data. col1→col2 and
  # col3→col4 use header midpoints (no symmetric data anchor available).
  defp column_boundaries(data_lines, header_line) do
    anchors = cluster_header_xs(header_line.tokens)

    midpoints =
      anchors
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> (a + b) / 2.0 end)

    date_xs =
      data_lines
      |> Enum.flat_map(& &1.tokens)
      |> Enum.filter(&Regex.match?(@date_re, &1.text))
      |> Enum.map(& &1.x)

    case {midpoints, date_xs} do
      {[m12, _m23, m34], [_ | _]} ->
        [m12, Enum.min(date_xs) - 5.0, m34]

      {[m12, _m23], [_ | _]} ->
        [m12, Enum.min(date_xs) - 5.0]

      {ms, _} ->
        ms
    end
  end

  # Tokens in the header that share the same column have very close X (often
  # identical, since the producer emits one label per token at a single Tm
  # position). Walk the unique sorted Xs and start a new cluster whenever a
  # gap exceeds `cluster_gap_threshold/0`.
  defp cluster_header_xs(tokens) do
    tokens
    |> Enum.map(& &1.x)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.reduce([], fn x, acc ->
      case acc do
        [] ->
          [x]

        [last | _] when x - last < 30 ->
          acc

        _ ->
          [x | acc]
      end
    end)
    |> Enum.reverse()
  end

  # For each line, place each token into its column bin and return the per-row
  # column texts (always 4 strings, missing columns are "").
  defp bin_rows_by_columns(lines, midpoints) do
    n_columns = length(midpoints) + 1
    empty = List.duplicate([], n_columns)

    Enum.map(lines, fn line ->
      buckets =
        Enum.reduce(line.tokens, empty, fn token, acc ->
          col = column_for_x_midpoints(token.x, midpoints)
          List.update_at(acc, col, &[token | &1])
        end)

      Enum.map(buckets, fn tokens ->
        tokens
        |> Enum.reverse()
        |> Enum.map(& &1.text)
        |> Enum.join(" ")
        |> collapse_spaces()
      end)
    end)
  end

  defp column_for_x_midpoints(x, midpoints) do
    Enum.reduce_while(Enum.with_index(midpoints), length(midpoints), fn {m, idx}, _acc ->
      if x < m, do: {:halt, idx}, else: {:cont, idx + 1}
    end)
  end

  # Walk the binned rows; a row whose third column matches dd/mm/yyyy starts a
  # new obligation. Other rows extend the previous obligation's text.
  defp group_into_obligaciones(rows) do
    {acc, current} = Enum.reduce(rows, {[], nil}, &reduce_obligacion_row/2)

    [current | acc]
    |> Enum.reject(&is_nil/1)
    |> Enum.reverse()
    |> Enum.map(&collapse_obligacion/1)
  end

  defp reduce_obligacion_row([obl, venc, fi, ff], {acc, current}) do
    cond do
      Regex.match?(@date_re, fi) ->
        acc = if current, do: [current | acc], else: acc

        {acc,
         %Obligacion{
           descripcion_obligacion: obl,
           descripcion_vencimiento: venc,
           fecha_inicio: fi,
           fecha_fin: presence(ff)
         }}

      not is_nil(current) ->
        {acc, append_to_current(current, [obl, venc, fi, ff])}

      true ->
        {acc, current}
    end
  end

  defp reduce_obligacion_row(_, state), do: state

  defp append_to_current(%Obligacion{} = ob, [obl, venc, _fi, _ff]) do
    %Obligacion{
      ob
      | descripcion_obligacion: join_nonempty(ob.descripcion_obligacion, obl),
        descripcion_vencimiento: join_nonempty(ob.descripcion_vencimiento, venc)
    }
  end

  defp join_nonempty(a, b) do
    [a, b]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
    |> collapse_spaces()
  end

  defp collapse_obligacion(%Obligacion{} = ob) do
    %Obligacion{
      ob
      | descripcion_obligacion: collapse_spaces(ob.descripcion_obligacion || ""),
        descripcion_vencimiento: collapse_spaces(ob.descripcion_vencimiento || "")
    }
  end

  # ── Helpers shared by Identificación + Domicilio ─────────────

  # Build a label → value map by scanning the joined section text.
  # Labels are sorted longest-first so that "Nombre Comercial" wins over
  # "Nombre (s)" and "Nombre del Municipio…" wins over "Nombre de la…".
  defp extract_label_pairs(lines, label_specs) do
    text = lines |> Enum.map(& &1.text) |> Enum.join(" ")

    labels =
      label_specs
      |> Enum.map(fn {_field, label} -> label end)
      |> Enum.uniq()
      |> Enum.sort_by(&(-String.length(&1)))

    alt = labels |> Enum.map(&Regex.escape/1) |> Enum.join("|")
    re = Regex.compile!("(#{alt})\\s*:\\s*(.+?)(?=\\s+(?:#{alt})\\s*:|$)", "u")

    Regex.scan(re, text)
    |> Enum.map(fn [_, label, value] -> {label, String.trim(value)} end)
    |> Enum.into(%{})
  end

  defp atomize_pairs(label_to_value, label_specs) do
    Enum.reduce(label_specs, %{}, fn {field, label}, acc ->
      case Map.get(label_to_value, label) do
        nil -> acc
        value -> Map.put_new(acc, field, value)
      end
    end)
  end

  defp presence(nil), do: nil
  defp presence(""), do: nil
  defp presence(other), do: other
end
