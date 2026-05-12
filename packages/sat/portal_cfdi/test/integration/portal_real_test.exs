defmodule Sat.PortalCfdi.Integration.PortalRealTest do
  @moduledoc """
  Test de integracion REAL contra el portal del SAT.

  Hace login con tu FIEL, consulta CFDIs de un rango de fechas, recorre la
  paginacion y reporta cuantos hay. Diseñado para que veas paso a paso que
  esta haciendo la libreria contra el portal real.

  > **NO se ejecuta por default**. Esta excluido con `@moduletag :real_sat`.
  > Lo activas via `mix test --include real_sat`.

  ## Variables de entorno requeridas

      SAT_FIEL_CER          ruta absoluta al .cer (FIEL, NO CSD)
      SAT_FIEL_KEY          ruta absoluta al .key (FIEL, NO CSD)
      SAT_FIEL_PASSWORD     contrasena de la llave privada

  ## Variables opcionales

      SAT_TIPO              "recibidos" (default) | "emitidos"
      SAT_FECHA_INICIO      "YYYY-MM-DD" (default: primer dia del mes pasado)
      SAT_FECHA_FIN         "YYYY-MM-DD" (default: ultimo dia del mes pasado)
      SAT_MAX_PAGINAS       maximo de paginas a recorrer (default: 5)
      SAT_DELAY_MS          espera entre paginas en ms (default: 2000)
      SAT_DOWNLOAD_FIRST    "true" para descargar el XML del primer CFDI

  ## Como correrlo

      SAT_FIEL_CER=/path/fiel.cer \\
      SAT_FIEL_KEY=/path/fiel.key \\
      SAT_FIEL_PASSWORD="tu_contrasena" \\
      SAT_TIPO=recibidos \\
      SAT_FECHA_INICIO=2025-04-01 \\
      SAT_FECHA_FIN=2025-04-30 \\
      mix test --include real_sat \\
        test/integration/portal_real_test.exs --trace

  > Si la libreria todavia no aguanta el flujo SAML completo del IDP NetIQ,
  > vas a ver el error exacto que devuelve el SAT y el HTML que recibimos
  > en `:respuesta_inesperada` o `:login_failed`. Eso es lo que necesitamos
  > para iterar y arreglar.
  """

  use ExUnit.Case, async: false

  alias Sat.Certificados.Credential
  alias Sat.PortalCfdi.Portal

  alias Sat.PortalCfdi.Types.{
    ConsultaCfdiParams,
    CredencialFIEL,
    CredencialPortal
  }

  @moduletag :real_sat
  @moduletag timeout: 600_000

  setup do
    cer_path = "/Users/amir/Documents/FIEL_MACA961017759_20231026123655/00001000000703123762.cer"
    key_path = "/Users/amir/Documents/FIEL_MACA961017759_20231026123655/Claveprivada_FIEL_MACA961017759_20231026_123655.key"
    password = "MisaelMa1710"

    cond do
      is_nil(cer_path) or is_nil(key_path) or is_nil(password) ->
        {:ok, skip: "set SAT_FIEL_CER / SAT_FIEL_KEY / SAT_FIEL_PASSWORD"}

      not File.exists?(cer_path) ->
        {:ok, skip: "no existe #{cer_path}"}

      not File.exists?(key_path) ->
        {:ok, skip: "no existe #{key_path}"}

      true ->
        {:ok,
         %{
           cer_path: cer_path,
           key_path: key_path,
           password: password,
           tipo: parse_tipo(System.get_env("SAT_TIPO", "recibidos")),
           fecha_inicio: System.get_env("SAT_FECHA_INICIO") || default_fecha_inicio(),
           fecha_fin: System.get_env("SAT_FECHA_FIN") || default_fecha_fin(),
           max_paginas: System.get_env("SAT_MAX_PAGINAS", "5") |> String.to_integer(),
           delay_ms: System.get_env("SAT_DELAY_MS", "2000") |> String.to_integer(),
           download_first: System.get_env("SAT_DOWNLOAD_FIRST") == "true"
         }}
    end
  end

  test "login FIEL + listar CFDIs con paginacion completa", ctx do
    if ctx[:skip] do
      IO.puts("[real_sat] SKIP: #{ctx.skip}")
      flunk("test skipped: #{ctx.skip}")
    end

    log("============================================================")
    log("Test de integracion contra el portal SAT")
    log("------------------------------------------------------------")
    log("FIEL .cer:  #{ctx.cer_path}")
    log("FIEL .key:  #{ctx.key_path}")
    log("Tipo:       #{ctx.tipo}")
    log("Rango:      #{ctx.fecha_inicio} → #{ctx.fecha_fin}")
    log("Max paginas: #{ctx.max_paginas} | delay: #{ctx.delay_ms}ms")
    log("============================================================")

    log("[1/4] Cargando FIEL desde disco...")
    {time_load, {:ok, cred}} = :timer.tc(fn ->
      Credential.create(ctx.cer_path, ctx.key_path, ctx.password)
    end)
    log("      OK en #{div(time_load, 1000)}ms")
    log("      RFC: #{Credential.rfc(cred)}")
    log("      Es FIEL? #{Credential.is_fiel?(cred)}")
    assert Credential.is_fiel?(cred), "el certificado NO es FIEL (es CSD?). Necesitas la e.firma."

    log("")
    log("[2/4] Login al portal...")
    fiel = %CredencialFIEL{
      certificate_path: ctx.cer_path,
      private_key_path: ctx.key_path,
      password: ctx.password
    }

    cred_portal = %CredencialPortal{tipo: :fiel, fiel: fiel}

    {time_login, login_result} = :timer.tc(fn ->
      Portal.login(cred_portal, credential: cred)
    end)

    case login_result do
      {:ok, sesion} ->
        log("      OK en #{div(time_login, 1000)}ms")
        log("      Cookies: #{map_size(sesion.cookies || %{})} entradas")
        log("      Authenticated: #{sesion.authenticated}")

        log("")
        log("[3/4] Consulta paginada (#{ctx.fecha_inicio} → #{ctx.fecha_fin})...")
        params = %ConsultaCfdiParams{
          tipo: ctx.tipo,
          fecha_inicio: ctx.fecha_inicio,
          fecha_fin: ctx.fecha_fin
        }

        # Primera consulta para ver paginacion
        case Portal.consultar_paginado(sesion, params) do
          {:ok, primera, sesion} ->
            log("      Pagina 1: #{length(primera.results)} resultados")
            log("      Total CFDIs: #{primera.total_cfdis}")
            log("      Total paginas: #{primera.total_paginas}")
            log("      Has next: #{primera.has_next}")

            log("")
            log("[4/4] Iterando todas las paginas...")
            on_page = fn pag, acc ->
              log(
                "      Pag #{pag.pagina_actual}/#{pag.total_paginas} → " <>
                  "#{length(pag.results)} en esta pag, #{length(acc)} acumulados"
              )

              :ok
            end

            {time_iter, iter_result} = :timer.tc(fn ->
              Portal.consultar_todas_paginas(sesion, params,
                max_paginas: ctx.max_paginas,
                delay_ms: ctx.delay_ms,
                on_page: on_page
              )
            end)

            case iter_result do
              {:ok, lista, ultima_pagina, sesion} ->
                log("")
                log("============================================================")
                log("RESUMEN")
                log("------------------------------------------------------------")
                log("Total CFDIs encontrados: #{length(lista)}")
                log("Paginas recorridas: #{ultima_pagina.pagina_actual}")
                log("Tiempo iteracion: #{div(time_iter, 1000)}ms")

                if length(lista) > 0 do
                  primero = hd(lista)
                  log("")
                  log("Primer CFDI:")
                  log("  UUID:           #{primero.uuid}")
                  log("  Emisor:         #{primero.rfc_emisor} (#{primero.nombre_emisor})")
                  log("  Receptor:       #{primero.rfc_receptor}")
                  log("  Fecha emision:  #{primero.fecha_emision}")
                  log("  Total:          $#{:erlang.float_to_binary(primero.total / 1, decimals: 2)}")
                  log("  Estado:         #{primero.estado}")

                  if ctx.download_first do
                    log("")
                    log("Descargando XML del primer CFDI...")
                    case Portal.descargar_xml(sesion, primero.uuid) do
                      {:ok, xml, _} ->
                        log("      OK, #{byte_size(xml)} bytes")
                        log("      Empieza con: #{String.slice(xml, 0, 100)}...")
                      {:error, reason} ->
                        log("      ERROR: #{inspect(reason)}")
                    end
                  end
                end

                log("============================================================")
                assert length(lista) >= 0

              {:error, reason} ->
                log("ERROR en iteracion: #{inspect(reason, limit: :infinity, printable_limit: 500)}")
                flunk("iteracion fallo: #{inspect(reason)}")
            end

          {:error, reason} ->
            log("ERROR en consulta: #{inspect(reason, limit: :infinity, printable_limit: 1000)}")
            flunk("consulta fallo: #{inspect(reason)}")
        end

      {:error, reason} ->
        log("ERROR en login: #{inspect(reason, limit: :infinity, printable_limit: 1000)}")
        flunk(
          "login fallo. Esto suele significar que el flujo SAML del IDP " <>
            "cambio. Compara el HTML del paso GET contra phpcfdi/cfdi-sat-scraper. " <>
            "Detalle: #{inspect(reason)}"
        )
    end
  end

  defp parse_tipo("emitidos"), do: :emitidos
  defp parse_tipo(_), do: :recibidos

  defp default_fecha_inicio do
    today = Date.utc_today()
    primer_dia_mes_pasado = Date.beginning_of_month(Date.add(Date.beginning_of_month(today), -1))
    Date.to_iso8601(primer_dia_mes_pasado)
  end

  defp default_fecha_fin do
    today = Date.utc_today()
    primer_dia_este_mes = Date.beginning_of_month(today)
    ultimo_dia_mes_pasado = Date.add(primer_dia_este_mes, -1)
    Date.to_iso8601(ultimo_dia_mes_pasado)
  end

  defp log(msg) do
    IO.puts("[real_sat] " <> msg)
  end
end
