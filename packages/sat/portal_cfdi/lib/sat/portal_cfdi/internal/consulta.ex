defmodule Sat.PortalCfdi.Internal.Consulta do
  @moduledoc false
  # Envio, paginacion y parsing de la consulta de CFDIs en el portal.
  #
  # Endpoints:
  #   * Emitidos:  /ConsultaEmisor.aspx
  #   * Recibidos: /ConsultaReceptor.aspx
  #
  # El portal usa ASP.NET WebForms, asi que cada POST debe llevar
  # `__VIEWSTATE`, `__VIEWSTATEGENERATOR`, `__EVENTVALIDATION`,
  # `__EVENTTARGET` y `__EVENTARGUMENT` extraidos del request anterior.
  #
  # Paginacion: cuando hay mas resultados, el portal renderiza un
  # control de paginacion (`ctl00$MainContent$Pagination` u otro nombre
  # similar). Los clicks de paginacion son __doPostBack con
  # __EVENTTARGET apuntando al control y __EVENTARGUMENT al numero de
  # pagina.

  require Logger

  alias Sat.PortalCfdi.Internal.{Form, Http}
  alias Sat.PortalCfdi.Types.{CfdiConsultaResult, ConsultaCfdiParams, SesionSAT}

  @base_url "https://portalcfdi.facturaelectronica.sat.gob.mx"
  @max_paginas_por_default 50

  @typedoc """
  Resultado de una consulta paginada. Incluye los CFDIs de la pagina
  actual + metadatos para iterar.
  """
  @type pagina :: %{
          results: [CfdiConsultaResult.t()],
          pagina_actual: pos_integer(),
          total_paginas: pos_integer() | :unknown,
          total_cfdis: non_neg_integer() | :unknown,
          has_next: boolean(),
          hidden_fields: map(),
          url: String.t(),
          raw_html: String.t() | nil
        }

  @doc """
  Primera consulta. Retorna la pagina 1 + metadatos.
  """
  @spec consultar(SesionSAT.t(), ConsultaCfdiParams.t(), keyword()) ::
          {:ok, pagina(), SesionSAT.t()} | {:error, term()}
  def consultar(%SesionSAT{} = sesion, %ConsultaCfdiParams{} = params, opts \\ []) do
    page_path = page_path(params.tipo)
    url = @base_url <> page_path

    with {:ok, %{status: 200, body: html}, sesion} <- Http.get(sesion, url, opts),
         hidden = Form.extract_hidden_inputs(html),
         body = build_form_body(hidden, params),
         headers = [
           {"content-type", "application/x-www-form-urlencoded"},
           {"referer", url}
         ],
         {:ok, %{status: 200, body: html_result}, sesion} <-
           Http.post(sesion, url, body, Keyword.put(opts, :extra_headers, headers)) do
      {:ok, build_pagina(html_result, url, 1, opts), sesion}
    else
      {:ok, %{status: status}, _} -> {:error, {:http_error, status}}
      {:error, _} = e -> e
    end
  end

  @doc """
  Va a una pagina especifica. Reusa los hidden fields de la pagina previa
  porque el portal exige el `__VIEWSTATE` actualizado entre POSTs.
  """
  @spec consultar_pagina(SesionSAT.t(), pagina(), pos_integer(), keyword()) ::
          {:ok, pagina(), SesionSAT.t()} | {:error, term()}
  def consultar_pagina(%SesionSAT{} = sesion, %{} = pagina_anterior, n, opts \\ [])
      when is_integer(n) and n > 0 do
    target = pagination_event_target(pagina_anterior.raw_html) || "ctl00$MainContent$PageNavigation"

    body =
      pagina_anterior.hidden_fields
      |> Map.merge(%{
        "__EVENTTARGET" => target,
        "__EVENTARGUMENT" => "Page$#{n}"
      })
      |> Form.encode()

    headers = [
      {"content-type", "application/x-www-form-urlencoded"},
      {"referer", pagina_anterior.url}
    ]

    case Http.post(sesion, pagina_anterior.url, body, Keyword.put(opts, :extra_headers, headers)) do
      {:ok, %{status: 200, body: html}, sesion} ->
        {:ok, build_pagina(html, pagina_anterior.url, n, opts), sesion}

      {:ok, %{status: status}, _} ->
        {:error, {:http_error, status}}

      {:error, _} = e ->
        e
    end
  end

  @doc """
  Itera TODAS las paginas y devuelve la lista completa de resultados.

  Opciones:
    * `:max_paginas` (default 50) — corta despues de N paginas para
      evitar abusar del portal si la deteccion falla.
    * `:delay_ms` (default 1500) — espera entre paginas (cortesia / rate-limit).
    * `:on_page` — callback `(pagina, acc -> :ok | :stop)` para reportar
      progreso o detener temprano.
  """
  @spec consultar_todas(SesionSAT.t(), ConsultaCfdiParams.t(), keyword()) ::
          {:ok, [CfdiConsultaResult.t()], pagina(), SesionSAT.t()} | {:error, term()}
  def consultar_todas(%SesionSAT{} = sesion, %ConsultaCfdiParams{} = params, opts \\ []) do
    max = Keyword.get(opts, :max_paginas, @max_paginas_por_default)
    delay = Keyword.get(opts, :delay_ms, 1500)
    on_page = Keyword.get(opts, :on_page, fn _, _ -> :ok end)

    case consultar(sesion, params, opts) do
      {:ok, pagina1, sesion} ->
        report = on_page.(pagina1, [])
        if report == :stop do
          {:ok, pagina1.results, pagina1, sesion}
        else
          iterate_paginas(sesion, pagina1, pagina1.results, 2, max, delay, on_page, opts)
        end

      {:error, _} = e ->
        e
    end
  end

  defp iterate_paginas(sesion, last_page, acc, n, max, _delay, _on_page, _opts) when n > max do
    Logger.warning("Consulta: alcanzado max_paginas=#{max}, deteniendo iteracion")
    {:ok, acc, last_page, sesion}
  end

  defp iterate_paginas(sesion, last_page, acc, n, max, delay, on_page, opts) do
    if last_page.has_next do
      Process.sleep(delay)

      case consultar_pagina(sesion, last_page, n, opts) do
        {:ok, page, sesion} ->
          new_acc = acc ++ page.results
          report = on_page.(page, new_acc)

          if report == :stop or page.results == [] do
            {:ok, new_acc, page, sesion}
          else
            iterate_paginas(sesion, page, new_acc, n + 1, max, delay, on_page, opts)
          end

        {:error, _} = e ->
          e
      end
    else
      {:ok, acc, last_page, sesion}
    end
  end

  defp page_path(:emitidos), do: "/ConsultaEmisor.aspx"
  defp page_path(:recibidos), do: "/ConsultaReceptor.aspx"
  defp page_path(_), do: "/ConsultaReceptor.aspx"

  defp build_form_body(hidden, %ConsultaCfdiParams{} = p) do
    fecha_inicio = p.fecha_inicio || ""
    fecha_fin = p.fecha_fin || ""

    fields =
      hidden
      |> Map.merge(%{
        "ctl00$MainContent$FechaInicial2" => fecha_inicio,
        "ctl00$MainContent$FechaFinal2" => fecha_fin,
        "ctl00$MainContent$TxtRfcReceptor" => p.rfc_receptor || "",
        "ctl00$MainContent$BtnBusqueda" => "Buscar CFDI"
      })

    Form.encode(fields)
  end

  defp build_pagina(html, url, n, _opts) do
    results = parse_results(html)
    hidden = Form.extract_hidden_inputs(html)
    {total_cfdis, total_paginas} = parse_pagination_meta(html)
    has_next = pagination_has_next?(html, n, total_paginas)

    %{
      results: results,
      pagina_actual: n,
      total_paginas: total_paginas,
      total_cfdis: total_cfdis,
      has_next: has_next,
      hidden_fields: hidden,
      url: url,
      raw_html: html
    }
  end

  @doc """
  Parsea la tabla de resultados HTML usando Floki.
  """
  @spec parse_results(String.t()) :: [CfdiConsultaResult.t()]
  def parse_results(html) when is_binary(html) do
    case Floki.parse_document(html) do
      {:ok, doc} ->
        doc
        |> Floki.find("table#ctl00_MainContent_tblResult tr")
        |> Enum.flat_map(&parse_row/1)

      {:error, _} ->
        []
    end
  end

  defp parse_row(row) do
    cells = row |> Floki.find("td") |> Enum.map(&cell_text/1)

    case cells do
      [uuid, rfc_emisor, nombre_emisor, rfc_receptor, nombre_receptor, fecha_emision, fecha_cert, total | rest]
      when uuid != "" ->
        [efecto, estado] = pad(rest, 2, "")

        [
          %CfdiConsultaResult{
            uuid: uuid,
            rfc_emisor: rfc_emisor,
            nombre_emisor: nombre_emisor,
            rfc_receptor: rfc_receptor,
            nombre_receptor: nombre_receptor,
            fecha_emision: fecha_emision,
            fecha_certificacion: fecha_cert,
            total: parse_total(total),
            efecto: efecto,
            estado: estado
          }
        ]

      _ ->
        []
    end
  end

  defp cell_text(td) do
    td |> Floki.text() |> String.trim()
  end

  defp pad(list, size, default) do
    list ++ List.duplicate(default, max(0, size - length(list)))
    |> Enum.take(size)
  end

  defp parse_total(text) do
    text
    |> String.replace(~r/[^0-9.\-]/, "")
    |> case do
      "" ->
        0.0

      s ->
        case Float.parse(s) do
          {f, _} -> f
          :error -> 0.0
        end
    end
  end

  # --- Paginacion ---------------------------------------------------------

  @doc """
  Extrae `{total_cfdis, total_paginas}` del HTML de la pagina de resultados.
  Si no encuentra los datos retorna `{:unknown, :unknown}`.
  """
  @spec parse_pagination_meta(String.t()) ::
          {non_neg_integer() | :unknown, pos_integer() | :unknown}
  def parse_pagination_meta(html) when is_binary(html) do
    total_cfdis =
      case Regex.run(~r/Total[^0-9]*(\d+)/i, html) do
        [_, n] -> String.to_integer(n)
        _ -> :unknown
      end

    total_paginas =
      cond do
        match = Regex.run(~r/P[aá]gina\s+\d+\s+de\s+(\d+)/iu, html) ->
          [_, n] = match
          String.to_integer(n)

        # ASP.NET pager con clase rgPager / rgWrap
        match = Regex.run(~r/Page\s*\$Last|Page\$(\d+)/i, html) ->
          case match do
            [_, n] when is_binary(n) -> String.to_integer(n)
            _ -> :unknown
          end

        true ->
          :unknown
      end

    {total_cfdis, total_paginas}
  end

  @doc """
  `true` si hay un boton/link "siguiente pagina" o si la pagina actual
  es menor al total conocido.
  """
  @spec pagination_has_next?(String.t(), pos_integer(), pos_integer() | :unknown) :: boolean()
  def pagination_has_next?(html, current, total) do
    cond do
      is_integer(total) and current < total -> true
      String.contains?(html, "Siguiente") and not String.contains?(html, "Siguiente disabled") -> true
      Regex.match?(~r/__doPostBack\(['"][^'"]+(Page|Pagination)[^'"]*['"],\s*['"]Page\$Next/i, html) -> true
      true -> false
    end
  end

  @doc """
  Extrae el `__EVENTTARGET` que dispara la paginacion (control que
  ASP.NET expone como pager).
  """
  @spec pagination_event_target(String.t() | nil) :: String.t() | nil
  def pagination_event_target(nil), do: nil

  def pagination_event_target(html) do
    case Regex.run(~r/__doPostBack\(['"]([^'"]+(?:Pagination|PageNavigation|Pager)[^'"]*)['"]/i, html) do
      [_, target] -> String.replace(target, "$", "$")
      _ -> nil
    end
  end
end
