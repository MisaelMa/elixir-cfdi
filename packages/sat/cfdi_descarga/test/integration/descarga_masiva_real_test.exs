defmodule Sat.Cfdi.Descarga.Masiva.Integration.DescargaMasivaRealTest do
  @moduledoc """
  Tests de integracion REALES contra el WS de Descarga Masiva del SAT.

  Firman con tu FIEL (e.firma) y golpean los endpoints oficiales
  `cfdidescargamasivasolicitud.clouda.sat.gob.mx` y
  `cfdidescargamasiva.clouda.sat.gob.mx`.

  Hay dos pruebas independientes:

    1. **solicitud + verificacion** — autentica, registra una solicitud por
       rango de fechas y consulta su estado UNA vez (sin esperar a que termine).
    2. **descarga de paquetes** — autentica, solicita, hace polling hasta
       `:terminada` y descarga cada paquete ZIP, extrayendo los XMLs.

  > **NO se ejecutan por default**. Estan excluidas con `@moduletag :real_sat`.
  > Se activan con `mix test --include real_sat`.

  ## Variables de entorno

      SAT_FIEL_CER          ruta al .cer de la FIEL (default: FIEL de amir en disco)
      SAT_FIEL_KEY          ruta al .key de la FIEL
      SAT_FIEL_PASSWORD     contrasena de la llave privada
      SAT_TIPO              "recibidos" (default) | "emitidos"
      SAT_FECHA_INICIO      "YYYY-MM-DD" (default: primer dia del mes pasado)
      SAT_FECHA_FIN         "YYYY-MM-DD" (default: ultimo dia del mes pasado)
      SAT_POLL_INTERVAL_MS  intervalo de polling en la descarga (default: 30000)
      SAT_MAX_ATTEMPTS      intentos maximos de polling (default: 20)

  ## Como correrlas

      # solo la de solicitud + verificacion
      mix test --include real_sat \\
        test/integration/descarga_masiva_real_test.exs --trace \\
        --only "test:solicitud + verificacion"

      # la descarga completa (puede tardar varios minutos)
      SAT_FECHA_INICIO=2025-05-01 SAT_FECHA_FIN=2025-05-31 \\
        mix test --include real_sat \\
        test/integration/descarga_masiva_real_test.exs --trace

  > IMPORTANTE: el SAT permite maximo **2 solicitudes con los mismos parametros**
  > (mismo RFC + mismo rango). La 3a solicitud identica devuelve `cod_estatus`
  > `"5002"` de forma permanente. Como ambas pruebas registran una solicitud,
  > cada corrida consume 2 slots: si vuelves a correr con el mismo rango el mismo
  > dia, cambia `SAT_FECHA_INICIO`/`SAT_FECHA_FIN`.
  """

  use ExUnit.Case, async: false

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.{Autenticacion, Paquete, Solicitud, Verificacion}
  alias Sat.Cfdi.Descarga.Masiva.Internal.Http
  alias Sat.Cfdi.Descarga.Masiva.Paquete.Reader
  alias Sat.Cfdi.Descarga.Masiva.Types

  @moduletag :real_sat
  @moduletag timeout: 900_000

  setup do
    cer_path =
      System.get_env("SAT_FIEL_CER") ||
        "/Users/amir/Documents/FIEL_MACA961017759_20231026123655/00001000000703123762.cer"

    key_path =
      System.get_env("SAT_FIEL_KEY") ||
        "/Users/amir/Documents/FIEL_MACA961017759_20231026123655/Claveprivada_FIEL_MACA961017759_20231026_123655.key"

    password = System.get_env("SAT_FIEL_PASSWORD")

    cond do
      not File.exists?(cer_path) ->
        {:ok, skip: "no existe el .cer: #{cer_path}"}

      not File.exists?(key_path) ->
        {:ok, skip: "no existe el .key: #{key_path}"}

      true ->
        {:ok, cred} = Credential.create(cer_path, key_path, password)

        {:ok,
         %{
           cred: cred,
           cer_path: cer_path,
           key_path: key_path,
           tipo: parse_tipo(System.get_env("SAT_TIPO", "recibidos")),
           fecha_inicio: System.get_env("SAT_FECHA_INICIO") || default_fecha_inicio(),
           fecha_fin: System.get_env("SAT_FECHA_FIN") || default_fecha_fin(),
           poll_interval_ms:
             System.get_env("SAT_POLL_INTERVAL_MS", "30000") |> String.to_integer(),
           max_attempts: System.get_env("SAT_MAX_ATTEMPTS", "20") |> String.to_integer()
         }}
    end
  end

  test "autenticacion con FIEL", ctx do
    skip_if_needed(ctx)

    log("============================================================")
    log("Descarga Masiva SAT — autenticacion con FIEL")
    log("------------------------------------------------------------")
    log("RFC:     #{Credential.rfc(ctx.cred)}")
    log("============================================================")

    assert {:ok, %Types.Token{} = token} = Autenticacion.autenticar(credential: ctx.cred)
    IO.inspect(token, label: "token obtenido")
    assert is_binary(token.value) and token.value != ""
    log("OK — token obtenido: #{inspect(token)} (expira: #{inspect(token.expires_at)})")
  end

  test "autenticacion falla con contrasena incorrecta de la FIEL", ctx do
    skip_if_needed(ctx)

    log("============================================================")
    log("Descarga Masiva SAT — auth DEBE fallar (contrasena incorrecta)")
    log("------------------------------------------------------------")
    log(".cer: #{ctx.cer_path}")
    log(".key: #{ctx.key_path}")
    log("============================================================")

    # Falla ANTES de tocar al SAT: la llave privada no se puede descifrar,
    # asi que ni siquiera se puede construir la credencial para firmar.
    resultado = Credential.create(ctx.cer_path, ctx.key_path, "contrasena-incorrecta-xxx")
    IO.inspect(resultado, label: "Credential.create con password malo")

    assert {:error, _reason} = resultado,
           "se esperaba error al descifrar la llave con contrasena incorrecta, " <>
             "pero create/3 regreso: #{inspect(resultado)}"

    log("OK — la credencial NO se construye con contrasena incorrecta (auth imposible).")
  end

  test "autenticacion con FIEL falsa: el SAT rechaza", _ctx do
    case build_fake_fiel() do
      {:error, :no_openssl} ->
        IO.puts("[real_sat] SKIP: openssl no esta disponible para generar la FIEL falsa")

      {:error, reason} ->
        flunk("no se pudo generar la FIEL falsa: #{inspect(reason)}")

      {:ok, fake_cred, dir} ->
        try do
          log("============================================================")
          log("Descarga Masiva SAT — auth con FIEL FALSA (self-signed)")
          log("------------------------------------------------------------")
          log("Certificado self-signed, NO emitido por la AC del SAT.")
          log("Emisor esperado por el SAT: AC del SAT. Este cert: emisor propio.")
          log("============================================================")

          # Golpea el endpoint REAL de autenticacion con un cert que el SAT
          # nunca emitio. Debe rechazarlo (fault SOAP / http error).
          resultado = Autenticacion.autenticar(credential: fake_cred)
          IO.inspect(resultado, label: "respuesta del SAT a la FIEL falsa")

          assert {:error, _reason} = resultado,
                 "el SAT NO deberia emitir token para una FIEL falsa, pero regreso: " <>
                   inspect(resultado)

          log("OK — el SAT rechazo la FIEL falsa (ver la respuesta arriba).")
        after
          File.rm_rf(dir)
        end
    end
  end

  test "el SAT responde a un body basura (mandamos cualquier cosa)", _ctx do
    endpoint = Autenticacion.endpoint()
    soap_action = Autenticacion.soap_action()

    # Ni XML ni SOAP: literalmente cualquier cosa. Ni siquiera firmamos.
    body = "cualquier cosa que no es XML — 12345 ñ áé <no cierra> {\"json\": true}"

    log("============================================================")
    log("Descarga Masiva SAT — mandamos CUALQUIER COSA al endpoint")
    log("------------------------------------------------------------")
    log("endpoint:    #{endpoint}")
    log("soap_action: #{soap_action}")
    log("body:        #{body}")
    log("============================================================")

    resultado = Http.post_soap(endpoint, soap_action, body, timeout: 30_000)

    IO.inspect(resultado,
      label: "respuesta del SAT a un body basura",
      limit: :infinity,
      printable_limit: 4000
    )

    # No debe explotar: el cliente siempre regresa una tupla bien formada.
    assert match?({:ok, %{status: _}}, resultado) or match?({:error, _}, resultado)

    case resultado do
      {:ok, %{status: status, body: resp}} ->
        log("      HTTP status: #{status}")
        log("      body (primeros 800): #{String.slice(to_string(resp), 0, 800)}")

        # Basura jamas debe autenticar: nunca 200.
        refute status == 200,
               "un body basura no deberia devolver 200, pero devolvio #{status}"

      {:error, reason} ->
        log("      error de red / excepcion: #{inspect(reason)}")
    end

    log("OK — el SAT respondio sin tumbar al cliente (ver la respuesta arriba).")
  end

  test "solicitud + verificacion", ctx do
    skip_if_needed(ctx)

    params = build_params(ctx)

    log("============================================================")
    log("Descarga Masiva SAT — solicitud + verificacion")
    log("------------------------------------------------------------")
    log("RFC:     #{Credential.rfc(ctx.cred)}")
    log("Tipo:    #{ctx.tipo}")
    log("Rango:   #{ctx.fecha_inicio} → #{ctx.fecha_fin}")
    log("============================================================")

    log("[1/3] Autenticando con FIEL...")
    assert {:ok, token} = Autenticacion.autenticar(credential: ctx.cred)
    assert is_binary(token.value) and token.value != ""
    log("      OK — token expira: #{inspect(token.expires_at)}")

    log("[2/3] Registrando solicitud (#{ctx.tipo})...")
    assert {:ok, sol} = Solicitud.solicitar(token, params, credential: ctx.cred)
    log("      cod_estatus: #{sol.cod_estatus} | mensaje: #{sol.mensaje}")
    log("      IdSolicitud: #{sol.id_solicitud}")

    # 5000 = aceptada. 5002 = ya hiciste 2 solicitudes identicas (limite SAT).
    assert sol.cod_estatus in ["5000", "0"],
           "solicitud rechazada (cod #{sol.cod_estatus}): #{sol.mensaje}"

    assert is_binary(sol.id_solicitud) and sol.id_solicitud != ""

    log("[3/3] Verificando estado de la solicitud...")

    assert {:ok, ver} =
             Verificacion.verificar(token, sol.id_solicitud, credential: ctx.cred)

    log("      estado: #{inspect(ver.estado_solicitud)}")
    log("      codigo: #{ver.codigo_estado_solicitud} | cfdis: #{ver.numero_cfdis}")
    log("      paquetes: #{inspect(ver.ids_paquetes)}")

    assert ver.id_solicitud == sol.id_solicitud

    assert ver.estado_solicitud in [
             :aceptada,
             :en_proceso,
             :terminada,
             :error,
             :rechazada,
             :vencida
           ],
           "estado inesperado: #{inspect(ver.estado_solicitud)}"

    log("OK — solicitud registrada y verificada correctamente.")
  end

  test "descarga de paquetes con datos reales", ctx do
    skip_if_needed(ctx)

    params = build_params(ctx)

    log("============================================================")
    log("Descarga Masiva SAT — descarga de paquetes (REAL)")
    log("------------------------------------------------------------")
    log("RFC:     #{Credential.rfc(ctx.cred)}")
    log("Tipo:    #{ctx.tipo}")
    log("Rango:   #{ctx.fecha_inicio} → #{ctx.fecha_fin}")
    log("Polling: cada #{ctx.poll_interval_ms}ms, max #{ctx.max_attempts} intentos")
    log("============================================================")

    log("[1/4] Autenticando con FIEL...")
    assert {:ok, token} = Autenticacion.autenticar(credential: ctx.cred)
    log("      OK — token expira: #{inspect(token.expires_at)}")

    log("[2/4] Registrando solicitud (#{ctx.tipo})...")
    assert {:ok, sol} = Solicitud.solicitar(token, params, credential: ctx.cred)
    log("      cod_estatus: #{sol.cod_estatus} | IdSolicitud: #{sol.id_solicitud}")

    assert sol.cod_estatus in ["5000", "0"],
           "solicitud rechazada (cod #{sol.cod_estatus}): #{sol.mensaje}"

    assert is_binary(sol.id_solicitud) and sol.id_solicitud != ""

    log("[3/4] Esperando a que la solicitud termine (polling real)...")

    assert {:ok, ver} =
             Verificacion.esperar_terminada(token, sol.id_solicitud,
               credential: ctx.cred,
               poll_interval_ms: ctx.poll_interval_ms,
               max_attempts: ctx.max_attempts
             )

    log("      estado final: #{inspect(ver.estado_solicitud)}")
    log("      cfdis: #{ver.numero_cfdis} | paquetes: #{length(ver.ids_paquetes)}")

    assert ver.estado_solicitud == :terminada,
           "la solicitud no llego a :terminada — estado #{inspect(ver.estado_solicitud)} " <>
             "(codigo #{ver.codigo_estado_solicitud}). " <>
             "Si es :en_proceso, sube SAT_MAX_ATTEMPTS o reintenta mas tarde."

    if ver.ids_paquetes == [] do
      log("      El SAT reporto 0 paquetes (rango sin CFDIs). No hay nada que descargar.")
      assert ver.numero_cfdis == 0
    else
      log("[4/4] Descargando #{length(ver.ids_paquetes)} paquete(s)...")

      total_xmls =
        for id_paquete <- ver.ids_paquetes, reduce: 0 do
          acc ->
            log("      → descargando paquete #{id_paquete}...")

            assert {:ok, %Types.Paquete{} = paquete} =
                     Paquete.descargar(token, id_paquete, credential: ctx.cred)

            assert paquete.id == id_paquete
            assert is_binary(paquete.content) and byte_size(paquete.content) > 0
            assert paquete.size == byte_size(paquete.content)
            log("        ZIP de #{paquete.size} bytes")

            assert {:ok, stream} = Reader.stream_cfdis(paquete)
            xmls = Enum.to_list(stream)

            Enum.each(xmls, fn {name, xml} ->
              assert String.ends_with?(String.downcase(name), ".xml")
              assert xml =~ "<cfdi:Comprobante" or xml =~ "<Comprobante"
            end)

            log("        #{length(xmls)} CFDI(s) extraidos del ZIP")
            acc + length(xmls)
        end

      log("OK — se descargaron y extrajeron #{total_xmls} CFDI(s) en total.")
      assert total_xmls > 0
    end
  end

  test "descargar RECIBIDOS vigentes (flujo v1.5 correcto)", ctx do
    skip_if_needed(ctx)

    rfc = Credential.rfc(ctx.cred)

    # v1.5 RECIBIDOS: el solicitante es el RECEPTOR de los CFDIs.
    #   * NO se manda RfcEmisor con tu propio RFC (eso es "emitidos").
    #     Solo se declara RfcEmisor si quieres filtrar por UN emisor específico.
    #   * EstadoComprobante=:vigente porque el SAT NO entrega XML cancelados
    #     (docs/sat/01-solicitud.pdf, "EstadoComprobante": "En el caso para la
    #     descarga de XML, solo incluirán los CFDI vigentes"). Si necesitas los
    #     cancelados, usa tipo_solicitud: :metadata.
    params = %Types.SolicitudParams{
      rfc_solicitante: rfc,
      fecha_inicial:
        "2024-05-27" |> Date.from_iso8601!() |> DateTime.new!(~T[00:00:00], "Etc/UTC"),
      fecha_final: "2024-05-31" |> Date.from_iso8601!() |> DateTime.new!(~T[23:59:59], "Etc/UTC"),
      tipo_solicitud: :recibidos,
      estado_comprobante: :vigente
    }

    log("============================================================")
    log("Descarga Masiva SAT — descargar RECIBIDOS VIGENTES (v1.5)")
    log("------------------------------------------------------------")
    log("RFC receptor: #{rfc}")
    log("Rango:        #{ctx.fecha_inicio} → #{ctx.fecha_fin}")
    log("EstadoComprobante: vigente (el SAT no entrega XML cancelados)")
    log("============================================================")

    log("[1/4] Autenticando con FIEL...")
    assert {:ok, token} = Autenticacion.autenticar(credential: ctx.cred)
    log("      OK — token expira: #{inspect(token.expires_at)}")

    log("[2/4] Registrando solicitud RECIBIDOS...")
    assert {:ok, sol} = Solicitud.solicitar(token, params, credential: ctx.cred)
    log("      cod_estatus: #{sol.cod_estatus} | mensaje: #{sol.mensaje}")
    log("      IdSolicitud: #{sol.id_solicitud}")

    assert sol.cod_estatus in ["5000", "0"],
           "solicitud rechazada (cod #{sol.cod_estatus}): #{sol.mensaje}"

    assert is_binary(sol.id_solicitud) and sol.id_solicitud != ""

    log("[3/4] Esperando a que termine (polling real)...")

    assert {:ok, ver} =
             Verificacion.esperar_terminada(token, sol.id_solicitud,
               credential: ctx.cred,
               poll_interval_ms: ctx.poll_interval_ms,
               max_attempts: ctx.max_attempts
             )

    log(
      "      estado final: #{inspect(ver.estado_solicitud)} | codigo: #{ver.codigo_estado_solicitud}"
    )

    log("      cfdis: #{ver.numero_cfdis} | paquetes: #{length(ver.ids_paquetes)}")

    # :rechazada + 5004 = no hay CFDIs recibidos vigentes en el rango. Es un
    # resultado VÁLIDO del SAT (no un fallo): la solicitud se armó y firmó bien,
    # simplemente no hay datos. Cambia el rango si esperabas encontrar CFDIs.
    if ver.estado_solicitud == :rechazada and ver.codigo_estado_solicitud == "5004" do
      log("      RECHAZADA 5004: no hay CFDIs recibidos vigentes en ese rango (OK, sin datos).")
      assert ver.numero_cfdis == 0
    else
      assert ver.estado_solicitud == :terminada,
             "no llegó a :terminada — estado #{inspect(ver.estado_solicitud)} " <>
               "(codigo #{ver.codigo_estado_solicitud}). Sube SAT_MAX_ATTEMPTS, cambia el " <>
               "rango de fechas, o reintenta."

      if ver.ids_paquetes == [] do
        log("      0 paquetes (no recibiste CFDIs vigentes en ese rango).")
        assert ver.numero_cfdis == 0
      else
        log("[4/4] Descargando #{length(ver.ids_paquetes)} paquete(s) de RECIBIDOS...")

        total =
          for id <- ver.ids_paquetes, reduce: 0 do
            acc ->
              assert {:ok, %Types.Paquete{} = paq} =
                       Paquete.descargar(token, id, credential: ctx.cred)

              assert is_binary(paq.content) and byte_size(paq.content) > 0
              assert {:ok, stream} = Reader.stream_cfdis(paq)
              xmls = Enum.to_list(stream)
              log("      paquete #{id}: #{length(xmls)} CFDI(s), ZIP #{paq.size} bytes")
              acc + length(xmls)
          end

        log("OK — #{total} CFDI(s) recibidos descargados.")
        assert total > 0
      end
    end
  end

  test "verificar una solicitud existente por IdSolicitud (sin nueva solicitud)", ctx do
    skip_if_needed(ctx)

    # NO registra una solicitud nueva (no gasta cuota). Solo autentica y consulta
    # el estado de un IdSolicitud que ya existe. Configúralo con SAT_ID_SOLICITUD.
    # last = 790040c0-1135-4a30-bf03-9cb25f863396
    id_solicitud =
      System.get_env("SAT_ID_SOLICITUD") || "528ae9e2-ca53-4abb-aff3-72f0e70d54b2"

    log("============================================================")
    log("Descarga Masiva SAT — VERIFICAR solicitud existente")
    log("------------------------------------------------------------")
    log("RFC:         #{Credential.rfc(ctx.cred)}")
    log("IdSolicitud: #{id_solicitud}")
    log("============================================================")

    log("[1/2] Autenticando con FIEL...")
    assert {:ok, token} = Autenticacion.autenticar(credential: ctx.cred)
    log("      OK — token expira: #{inspect(token.expires_at)}")

    log("[2/2] Verificando estado (una sola consulta)...")

    # El SAT a veces tarda >30s en responder VerificaSolicitudDescarga (sobre
    # todo en solicitudes viejas/expiradas), y el timeout HTTP default es 30s.
    # Súbelo con SAT_TIMEOUT_MS si te da %Req.TransportError{reason: :timeout}.
    timeout = String.to_integer(System.get_env("SAT_TIMEOUT_MS", "90000"))

    assert {:ok, ver} =
             Verificacion.verificar(token, id_solicitud, credential: ctx.cred, timeout: timeout)

    log("      estado_solicitud:        #{inspect(ver.estado_solicitud)}")
    log("      codigo_estado_solicitud: #{ver.codigo_estado_solicitud}")
    log("      numero_cfdis:            #{ver.numero_cfdis}")
    log("      ids_paquetes:            #{inspect(ver.ids_paquetes)}")
    log("      mensaje:                 #{inspect(ver.mensaje)}")

    assert ver.id_solicitud == id_solicitud

    assert ver.estado_solicitud in [
             :aceptada,
             :en_proceso,
             :terminada,
             :error,
             :rechazada,
             :vencida
           ],
           "estado inesperado: #{inspect(ver.estado_solicitud)}"

    # Reporta si hay algo que descargar (no descarga; este test SOLO verifica).
    case ver.estado_solicitud do
      :terminada ->
        log("      → LISTA: #{length(ver.ids_paquetes)} paquete(s) disponibles para descargar.")
        assert ver.ids_paquetes != [] or ver.numero_cfdis == 0

      :rechazada when ver.codigo_estado_solicitud == "5004" ->
        log("      → RECHAZADA 5004: no se encontró información (sin CFDIs en el rango).")
        assert ver.numero_cfdis == 0

      estado when estado in [:aceptada, :en_proceso] ->
        log("      → AÚN EN PROCESO: vuelve a verificar más tarde (o usa esperar_terminada/3).")

      estado ->
        log(
          "      → estado terminal sin paquetes: #{inspect(estado)} (codigo #{ver.codigo_estado_solicitud})."
        )
    end

    log("OK — verificación completada.")
  end

  # --- helpers ---

  defp skip_if_needed(ctx) do
    if ctx[:skip] do
      IO.puts("[real_sat] SKIP: #{ctx.skip}")
      flunk("test skipped: #{ctx.skip}")
    end
  end

  defp build_params(ctx) do
    %Types.SolicitudParams{
      rfc_solicitante: Credential.rfc(ctx.cred),
      fecha_inicial: to_datetime(ctx.fecha_inicio, ~T[00:00:00]),
      fecha_final: to_datetime(ctx.fecha_fin, ~T[23:59:59]),
      tipo_solicitud: ctx.tipo
    }
  end

  defp to_datetime(date_str, time) do
    date_str
    |> Date.from_iso8601!()
    |> DateTime.new!(time, "Etc/UTC")
  end

  defp parse_tipo("emitidos"), do: :emitidos
  defp parse_tipo(_), do: :recibidos

  defp default_fecha_inicio do
    today = Date.utc_today()
    %{today | day: 1} |> Date.add(-1) |> Date.beginning_of_month() |> Date.to_iso8601()
  end

  defp default_fecha_fin do
    today = Date.utc_today()
    %{today | day: 1} |> Date.add(-1) |> Date.to_iso8601()
  end

  defp log(msg), do: IO.puts("[real_sat] " <> msg)

  # Genera un par certificado+llave self-signed (NO emitido por el SAT) y lo
  # carga como Credential. Devuelve tambien el dir temporal para limpiarlo.
  defp build_fake_fiel do
    if System.find_executable("openssl") do
      dir = Path.join(System.tmp_dir!(), "fake_fiel_#{:erlang.unique_integer([:positive])}")
      File.mkdir_p!(dir)
      cer = Path.join(dir, "fake.cer")
      key = Path.join(dir, "fake.key")

      {_out, code} =
        System.cmd(
          "openssl",
          [
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-nodes",
            "-keyout",
            key,
            "-out",
            cer,
            "-days",
            "1",
            "-subj",
            "/CN=FIEL FALSA DE PRUEBA/O=NO ES EL SAT/serialNumber=XAXX0s10101000"
          ],
          stderr_to_stdout: true
        )

      cond do
        code != 0 ->
          File.rm_rf(dir)
          {:error, {:openssl_failed, code}}

        true ->
          case Credential.create(cer, key, nil) do
            {:ok, cred} -> {:ok, cred, dir}
            {:error, _} = e -> File.rm_rf(dir) && e
          end
      end
    else
      {:error, :no_openssl}
    end
  end
end
