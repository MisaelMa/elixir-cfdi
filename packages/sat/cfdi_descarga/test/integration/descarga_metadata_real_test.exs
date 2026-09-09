defmodule Sat.Cfdi.Descarga.Masiva.Integration.SoapDumpHandler do
  @moduledoc """
  Handler de `:logger` que imprime COMPLETOS los logs `[SAT SOAP …]` que emite
  `Internal.Http` (request y response crudos).

  Existe porque el handler default de Elixir trunca cada mensaje a 8096 bytes
  (`" (truncated)"`), y `Logger.configure(truncate: :infinity)` quedó deprecado
  y sin efecto desde Elixir 1.19. Una respuesta del SAT con token o con el ZIP
  en base64 pasa de sobra ese límite, así que se imprime aparte con `IO.puts`.
  """

  @doc false
  def log(%{msg: {:string, msg}}, _config) do
    texto = IO.iodata_to_binary(msg)
    if String.starts_with?(texto, "[SAT SOAP"), do: IO.puts("\n" <> texto)
    :ok
  end

  def log(_event, _config), do: :ok
end

defmodule Sat.Cfdi.Descarga.Masiva.Integration.DescargaMetadataRealTest do
  @moduledoc """
  Descarga de **METADATA** (no XML) del WS de Descarga Masiva del SAT.

  La metadata es un ZIP con UN archivo `.txt` en TSV separado por `~` con una
  fila por CFDI: UUID, RFC emisor/receptor, fecha, monto, estatus, etc. A
  diferencia de la descarga de CFDI (XML), **la metadata SÍ incluye cancelados**
  (`EstadoComprobante` no está limitado a vigentes) y es MUCHO más barata: un
  mes completo cabe en un solo paquete.

  Este archivo tiene tres bloques:

    1. **Offline (corre siempre)** — arma el envelope SOAP de una solicitud de
       metadata por rango de mes y lo imprime, y parsea un ZIP de metadata
       simulado con el layout real del SAT. Firma con el CSD de PRUEBAS
       commiteado `LAN7008173R5` (`packages/files/certificados`), así que no
       necesita tu e.firma ni toca la red.
    2. **Real, flujo completo (`@tag :real_sat`)** — autentica, solicita
       metadata de un mes, hace polling hasta `:terminada`, descarga los
       paquetes y te imprime las columnas y las primeras filas.
       **Consume 1 de las 2 solicitudes** que el SAT permite por parámetros.
    3. **Real, sobre una solicitud YA registrada (`@tag :real_sat`)** — dos
       pruebas que trabajan con un `IdSolicitud` existente (`SAT_ID_SOLICITUD`),
       para el caso típico: solicitaste hoy y vuelves mañana a ver qué salió.
         * *verificar*: una sola consulta de estado. **No gasta cuota**, la
           puedes correr las veces que quieras.
         * *descargar*: exige `:terminada` y baja los paquetes. Cada paquete
           solo se puede descargar **2 veces** (la 3.ª da `5008`).

  ## Certificados

  Variable de entorno con fallback, igual que `descarga_masiva_real_test.exs`:

      cer = SAT_FIEL_CER      || packages/files/certificados/LAN7008173R5.cer
      key = SAT_FIEL_KEY      || packages/files/certificados/LAN7008173R5.key
      pwd = SAT_FIEL_PASSWORD || "12345678a" (solo si caes al CSD de pruebas)

  El default es el **CSD de PRUEBAS commiteado**, no una ruta personal: asi el
  bloque offline corre en cualquier maquina y en CI. Para las corridas reales
  exporta las tres variables apuntando a TU e.firma; nunca se commitea (si la
  quieres tener a la mano en el repo, `packages/files/certificados/fiel/` esta
  en el `.gitignore`).

  > ⚠️ El CSD de pruebas NO sirve contra el SAT: el WS de Descarga Masiva sólo
  > acepta **e.firma (FIEL)**; un CSD devuelve `CodEstatus` 300/305. Por eso el
  > test real se salta solo cuando no exportaste las variables — el bloque
  > offline sí lo usa, porque para ver la ESTRUCTURA del XML da igual.

  ## Variables de entorno

      SAT_FIEL_CER          ruta al .cer de la e.firma
      SAT_FIEL_KEY          ruta al .key de la e.firma
      SAT_FIEL_PASSWORD     contrasena de la llave privada
      SAT_MES               "YYYY-MM" — mes a consultar (default: mes pasado)
      SAT_FECHA_INICIO      "YYYY-MM-DD" (gana sobre SAT_MES)
      SAT_FECHA_FIN         "YYYY-MM-DD" (gana sobre SAT_MES)
      SAT_TIPO              "recibidos" (default) | "emitidos"
      SAT_ESTADO            "todos" (default) | "vigente" | "cancelado"
      SAT_ID_SOLICITUD      IdSolicitud existente, para el bloque 3
      SAT_POLL_INTERVAL_MS  intervalo de polling (default: 30000)
      SAT_MAX_ATTEMPTS      intentos maximos de polling (default: 20)
      SAT_TIMEOUT_MS        timeout HTTP de la verificacion (default: 90000)
      SAT_DUMP_PAQUETE      "1" para volcar tambien el SOAP del paquete
                            (incluye el ZIP en base64: son MBs de basura)
      SAT_DUMP_FILAS        cuantas filas del TSV imprimir (default: 10; "all")

  ## Que se imprime

  El cliente HTTP (`Internal.Http`) ya loguea request y response CRUDOS en
  `:debug`. El test sube el nivel y engancha `SoapDumpHandler` (handler propio
  de `:logger`) para que NO se trunquen a 8096 bytes, asi que veras el XML tal
  cual viaja:

      [SAT SOAP →] action=... <envelope firmado que mandamos>
      [SAT SOAP ←] action=... status=200 <respuesta CRUDA del SAT>

  Ademas, en cada paso:

    * el struct parseado (`IO.inspect` sin limites),
    * del paquete: nombre de archivos, el `.txt` de metadata **crudo** (header
      + primeras filas del TSV tal cual lo escribe el SAT) y el primer registro
      ya convertido a map.

  El SOAP del paquete NO se vuelca por default (trae el ZIP en base64, son MBs);
  activalo con `SAT_DUMP_PAQUETE=1`.

  ## Como correrlo

  ### 1. Offline — no necesita e.firma ni red

      mix test test/integration/descarga_metadata_real_test.exs --trace

  ### 2. Real — exportando las variables

  Hay una plantilla lista en `packages/sat/cfdi_descarga/env.example`:

      cd packages/sat/cfdi_descarga
      cp env.example .env      # tu copia privada; el .gitignore ignora .env
      $EDITOR .env             # pon tus rutas y contrasena
      source .env              # exporta todo a la shell actual

      mix test --include real_sat --trace \\
        test/integration/descarga_metadata_real_test.exs

  O a mano, si prefieres no usar el archivo:

      export SAT_FIEL_CER="$HOME/fiel/efirma.cer"
      export SAT_FIEL_KEY="$HOME/fiel/efirma.key"
      export SAT_FIEL_PASSWORD="tu-contrasena"
      export SAT_MES="2025-05"
      export SAT_TIPO="recibidos"

      mix test --include real_sat --trace \\
        test/integration/descarga_metadata_real_test.exs

  ### 3. Real — inline, sin exportar nada

  Las variables viven solo en ese proceso; no quedan en tu shell:

      SAT_FIEL_CER=$HOME/fiel/efirma.cer \\
        SAT_FIEL_KEY=$HOME/fiel/efirma.key \\
        SAT_FIEL_PASSWORD=tu-contrasena \\
        SAT_MES=2025-05 \\
        mix test --include real_sat --trace \\
        test/integration/descarga_metadata_real_test.exs

  Para dejar de usarlas despues de un `export` o un `source`:

      unset SAT_FIEL_CER SAT_FIEL_KEY SAT_FIEL_PASSWORD

  ### 4. Real — revisar MAÑANA una solicitud de HOY

  > ⚠️ **Corre UNO SOLO, por numero de linea.** `--only "test:<nombre>"` NO
  > filtra si tambien pasas `--include real_sat`: el include gana y corre TODOS
  > los tests reales, incluido el que registra una solicitud nueva. Eso te quema
  > cuota del SAT. Filtrar por `archivo:linea` si funciona.

      # que linea es cada test (se mueven al editar el archivo):
      grep -n 'test "' test/integration/descarga_metadata_real_test.exs

  Primero mira como quedo. No gasta cuota, repitelo cuantas veces quieras:

      source .env
      SAT_ID_SOLICITUD=1e0b9d7a-138b-4426-8d53-b8165601da13 \\
        mix test --include real_sat --trace \\
        test/integration/descarga_metadata_real_test.exs:453

  Y cuando diga `:terminada`, bajate la metadata:

      SAT_ID_SOLICITUD=1e0b9d7a-138b-4426-8d53-b8165601da13 \\
        mix test --include real_sat --trace \\
        test/integration/descarga_metadata_real_test.exs:531

  > Los paquetes viven **72 h** desde que la solicitud queda lista. Pasado eso
  > el estado es `:vencida` y hay que registrar la solicitud otra vez. Y cada
  > paquete solo se descarga **2 veces**: la 3.ª devuelve `5008`.

  > IMPORTANTE: el SAT permite máximo **2 solicitudes con los mismos parámetros**
  > (mismo RFC + mismo rango + mismo tipo). La 3.ª idéntica devuelve `5002` de
  > forma permanente. Si repites, cambia `SAT_MES`.
  """

  use ExUnit.Case, async: false

  require Logger

  alias Sat.Certificados.Credential
  alias Sat.Cfdi.Descarga.Masiva.{Autenticacion, Paquete, Solicitud, Verificacion}
  alias Sat.Cfdi.Descarga.Masiva.Integration.SoapDumpHandler
  alias Sat.Cfdi.Descarga.Masiva.Internal.SoapEnvelope
  alias Sat.Cfdi.Descarga.Masiva.Paquete.Reader
  alias Sat.Cfdi.Descarga.Masiva.Types
  alias Sat.Cfdi.Descarga.Masiva.Types.Paquete, as: PaqueteStruct

  @moduletag timeout: 900_000

  # packages/sat/cfdi_descarga/test/integration -> packages/files/certificados
  @certs_dir Path.expand("../../../../files/certificados", __DIR__)

  # CSD de PRUEBAS commiteado. Es el DEFAULT: se usa cuando no exportas
  # SAT_FIEL_CER / SAT_FIEL_KEY. Solo sirve para el bloque offline.
  @test_cer Path.join(@certs_dir, "LAN7008173R5.cer")
  @test_key Path.join(@certs_dir, "LAN7008173R5.key")
  @test_password "12345678a"

  # Layout real del TXT de metadata del SAT (12 columnas, separador `~`).
  @metadata_headers "Uuid~RfcEmisor~NombreEmisor~RfcReceptor~NombreReceptor~RfcPac~" <>
                      "FechaEmision~FechaCertificacionSat~Monto~EfectoComprobante~" <>
                      "Estatus~FechaCancelacion"

  setup do
    # Mismo patron que descarga_masiva_real_test.exs: variable de entorno con
    # fallback. La diferencia es que aqui el fallback NO es una ruta personal,
    # es el CSD de PRUEBAS commiteado: asi el bloque offline corre en cualquier
    # maquina (y en CI) sin que nadie tenga que tener tu e.firma.
    cer_path = System.get_env("SAT_FIEL_CER") || @test_cer
    key_path = System.get_env("SAT_FIEL_KEY") || @test_key

    # El password de pruebas SOLO aplica al CSD commiteado.
    password =
      System.get_env("SAT_FIEL_PASSWORD") || if cer_path == @test_cer, do: @test_password

    csd_pruebas? = cer_path == @test_cer

    cond do
      not File.exists?(cer_path) ->
        {:ok, %{skip: "no existe el .cer: #{cer_path}"}}

      not File.exists?(key_path) ->
        {:ok, %{skip: "no existe el .key: #{key_path}"}}

      true ->
        cargar_credencial(cer_path, key_path, password, csd_pruebas?)
    end
  end

  defp cargar_credencial(cer_path, key_path, password, csd_pruebas?) do
    case Credential.create(cer_path, key_path, password) do
      {:ok, cred} ->
        {inicio, fin} = rango_de_fechas()

        {:ok,
         %{
           cred: cred,
           csd_pruebas?: csd_pruebas?,
           cer: cer_path,
           key: key_path,
           fecha_inicio: inicio,
           fecha_fin: fin,
           tipo: parse_tipo(System.get_env("SAT_TIPO", "recibidos")),
           estado: parse_estado(System.get_env("SAT_ESTADO", "todos")),
           poll_interval_ms: env_int("SAT_POLL_INTERVAL_MS", 30_000),
           max_attempts: env_int("SAT_MAX_ATTEMPTS", 20)
         }}

      {:error, reason} ->
        {:ok, %{skip: "no se pudo cargar la credencial (#{cer_path}): #{inspect(reason)}"}}
    end
  end

  # ==========================================================================
  # OFFLINE — corre siempre, sin FIEL y sin red.
  # ==========================================================================

  describe "solicitud de metadata por rango de mes (offline)" do
    test "el envelope declara TipoSolicitud=Metadata y el rango del mes", ctx do
      skip_if_needed(ctx)

      rfc = Credential.rfc(ctx.cred)
      params = build_params(ctx, rfc)

      # normalizar_params/1 es lo que corre Solicitud.solicitar/3 por dentro:
      # infiere tipo_descarga y NO fuerza :vigente cuando es metadata.
      normalizados = Solicitud.normalizar_params(params)
      assert normalizados.tipo_descarga == :metadata

      operacion = Solicitud.soap_operation(normalizados.tipo_solicitud)

      envelope =
        SoapEnvelope.build_solicitud(ctx.cred, normalizados, "fake-token", operacion)

      log("============================================================")
      log("Metadata — envelope de la solicitud (#{operacion})")
      log("RFC: #{rfc} | Rango: #{ctx.fecha_inicio} → #{ctx.fecha_fin}")
      log("============================================================")
      IO.puts(String.replace(envelope, "><", ">\n<"))

      # El TIPO de contenido: metadata, no XML.
      assert envelope =~ ~s|TipoSolicitud="Metadata"|

      # El rango del mes completo, con la semántica del SAT (fecha de EMISIÓN).
      assert envelope =~ ~s|FechaInicial="#{ctx.fecha_inicio}T00:00:00"|
      assert envelope =~ ~s|FechaFinal="#{ctx.fecha_fin}T23:59:59"|

      # En metadata el SAT SÍ entrega cancelados: EstadoComprobante viaja tal
      # cual lo pediste, sin la red de seguridad de :vigente que aplica a CFDI.
      assert envelope =~ ~s|EstadoComprobante="Todos"|

      # La DIRECCIÓN la da la operación SOAP, no el TipoSolicitud.
      assert operacion == "SolicitaDescargaRecibidos" or
               operacion == "SolicitaDescargaEmitidos"
    end

    test "parse_metadata/1 lee el TXT del paquete con el layout real del SAT" do
      tsv =
        @metadata_headers <>
          "\r\n" <>
          "9e4d9e6c-6f2e-4f1f-9a1b-0c9f1e2d3a4b~AAA010101AAA~PROVEEDOR SA DE CV~" <>
          "BBB010101BBB~MI EMPRESA SA DE CV~SAT970701NN3~2025-05-03T10:15:00~" <>
          "2025-05-03T10:20:11~1160.00~Ingreso~Vigente~\r\n" <>
          "1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d~CCC010101CCC~OTRO PROVEEDOR~" <>
          "BBB010101BBB~MI EMPRESA SA DE CV~SAT970701NN3~2025-05-19T08:00:00~" <>
          "2025-05-19T08:03:45~464.00~Ingreso~Cancelado~2025-06-02T11:00:00\r\n"

      zip = build_zip([{"6d8a1f30_01.txt", tsv}])
      paquete = %PaqueteStruct{id: "PKG-META", content: zip, size: byte_size(zip)}

      assert {:ok, files} = Reader.list_files(paquete)
      assert files == ["6d8a1f30_01.txt"]

      # Mismo volcado que usa el test real: asi ves el formato de salida sin
      # gastar una solicitud contra el SAT.
      imprimir_txt_crudo(paquete)

      assert {:ok, [primera, segunda]} = Reader.parse_metadata(paquete)

      inspeccionar(primera, "FILA PARSEADA (simulada)")
      imprimir_filas([primera, segunda])

      assert primera[:uuid] == "9e4d9e6c-6f2e-4f1f-9a1b-0c9f1e2d3a4b"
      assert primera[:rfcemisor] == "AAA010101AAA"
      assert primera[:rfcreceptor] == "BBB010101BBB"
      assert primera[:monto] == "1160.00"
      assert primera[:estatus] == "Vigente"
      assert primera[:fechacancelacion] == ""

      # Esta es la razón de pedir metadata en vez de CFDI: los cancelados vienen.
      assert segunda[:estatus] == "Cancelado"
      assert segunda[:fechacancelacion] == "2025-06-02T11:00:00"
    end
  end

  # ==========================================================================
  # REAL — golpea al SAT. Excluido por default (mix test --include real_sat).
  # ==========================================================================

  describe "descarga de metadata contra el SAT (real)" do
    @tag :real_sat
    test "metadata de un mes completo: solicitud → polling → paquete → filas", ctx do
      skip_if_needed(ctx)
      skip_si_no_es_fiel(ctx)

      rfc = Credential.rfc(ctx.cred)
      params = build_params(ctx, rfc)

      log("============================================================")
      log("Descarga Masiva SAT — METADATA de un mes")
      log("------------------------------------------------------------")
      log("RFC:     #{rfc}")
      log("Cert:    #{ctx.cer}")
      log("Tipo:    #{ctx.tipo} (dirección) / metadata (contenido)")
      log("Estado:  #{ctx.estado}")
      log("Rango:   #{ctx.fecha_inicio} → #{ctx.fecha_fin}")
      log("Polling: cada #{ctx.poll_interval_ms}ms, max #{ctx.max_attempts} intentos")
      log("============================================================")

      # A partir de aqui el Logger imprime el XML CRUDO que mandamos y el que
      # el SAT responde, en cada llamada ([SAT SOAP →] / [SAT SOAP ←]).
      activar_dump_soap()

      log("[1/4] Autenticando con e.firma...")
      resultado_auth = Autenticacion.autenticar(credential: ctx.cred)
      inspeccionar(resultado_auth, "1. AUTENTICACION — respuesta parseada")

      assert {:ok, %Types.Token{} = token} = resultado_auth
      assert is_binary(token.value) and token.value != ""
      log("      OK — token expira: #{inspect(token.expires_at)}")

      log("[2/4] Registrando solicitud de METADATA...")
      resultado_sol = Solicitud.solicitar(token, params, credential: ctx.cred)
      inspeccionar(resultado_sol, "2. SOLICITUD — respuesta parseada")

      assert {:ok, sol} = resultado_sol
      log("      cod_estatus: #{sol.cod_estatus} | mensaje: #{sol.mensaje}")
      log("      IdSolicitud: #{sol.id_solicitud}")

      # {:ok, _} sólo significa HTTP 200. El veredicto real está en cod_estatus.
      assert sol.cod_estatus in ["5000", "0"],
             "solicitud rechazada (cod #{sol.cod_estatus}): #{sol.mensaje}. " <>
               "5002 = ya hiciste 2 solicitudes idénticas: cambia SAT_MES."

      assert is_binary(sol.id_solicitud) and sol.id_solicitud != ""

      log("[3/4] Esperando a que el SAT genere el paquete...")

      resultado_ver =
        Verificacion.esperar_terminada(token, sol.id_solicitud,
          credential: ctx.cred,
          poll_interval_ms: ctx.poll_interval_ms,
          max_attempts: ctx.max_attempts
        )

      inspeccionar(resultado_ver, "3. VERIFICACION — respuesta parseada (ultimo intento)")

      assert {:ok, ver} = resultado_ver

      log(
        "      estado: #{inspect(ver.estado_solicitud)} | codigo: #{ver.codigo_estado_solicitud}"
      )

      log("      cfdis: #{ver.numero_cfdis} | paquetes: #{inspect(ver.ids_paquetes)}")

      cond do
        # 5004 no es un bug: no hay CFDIs en ese rango. Cambia SAT_MES.
        ver.estado_solicitud == :rechazada and ver.codigo_estado_solicitud == "5004" ->
          log("      RECHAZADA 5004: no hay CFDIs en ese rango (resultado válido, sin datos).")
          assert ver.numero_cfdis == 0

        ver.ids_paquetes == [] ->
          assert ver.estado_solicitud == :terminada,
                 "no llegó a :terminada — #{inspect(ver.estado_solicitud)} " <>
                   "(codigo #{ver.codigo_estado_solicitud}). Sube SAT_MAX_ATTEMPTS o reintenta."

          log("      0 paquetes: el mes no tiene CFDIs de tipo #{ctx.tipo}.")
          assert ver.numero_cfdis == 0

        true ->
          log("[4/4] Descargando #{length(ver.ids_paquetes)} paquete(s) de metadata...")

          # La respuesta del paquete trae el ZIP en base64: son MBs de ruido en
          # consola. Solo se vuelca si lo pides con SAT_DUMP_PAQUETE=1.
          unless System.get_env("SAT_DUMP_PAQUETE") == "1" do
            desactivar_dump_soap()
            log("      (SOAP del paquete NO se vuelca; usa SAT_DUMP_PAQUETE=1 para verlo)")
          end

          total = descargar_paquetes(token, ver.ids_paquetes, ctx.cred)

          log("OK — #{total} fila(s) de metadata descargadas del mes.")
          assert total > 0
          assert total == ver.numero_cfdis or ver.numero_cfdis == 0
      end
    end
  end

  # ==========================================================================
  # REAL — sobre una solicitud QUE YA EXISTE (no registra ninguna nueva).
  # ==========================================================================

  describe "solicitud de metadata ya registrada (real)" do
    @tag :real_sat
    test "verificar el estado de un IdSolicitud (no gasta cuota)", ctx do
      skip_if_needed(ctx)
      skip_si_no_es_fiel(ctx)

      id_solicitud = id_solicitud()

      log("============================================================")
      log("Descarga Masiva SAT — VERIFICAR solicitud de metadata existente")
      log("------------------------------------------------------------")
      log("RFC:         #{Credential.rfc(ctx.cred)}")
      log("IdSolicitud: #{id_solicitud}")
      log("Este test NO registra solicitudes ni descarga paquetes.")
      log("============================================================")

      activar_dump_soap()

      log("[1/2] Autenticando con e.firma...")
      assert {:ok, %Types.Token{} = token} = Autenticacion.autenticar(credential: ctx.cred)
      log("      OK — token expira: #{inspect(token.expires_at)}")

      log("[2/2] Verificando (una sola consulta)...")

      # El SAT a veces tarda >30s en VerificaSolicitudDescarga y el timeout HTTP
      # default es 30s. Súbelo con SAT_TIMEOUT_MS si te da %Req.TransportError{}.
      resultado =
        Verificacion.verificar(token, id_solicitud,
          credential: ctx.cred,
          timeout: env_int("SAT_TIMEOUT_MS", 90_000)
        )

      inspeccionar(resultado, "VERIFICACION — respuesta parseada")

      assert {:ok, ver} = resultado
      assert ver.id_solicitud == id_solicitud

      log("      cod_estatus:             #{ver.cod_estatus}")
      log("      estado_solicitud:        #{inspect(ver.estado_solicitud)}")
      log("      codigo_estado_solicitud: #{ver.codigo_estado_solicitud}")
      log("      numero_cfdis:            #{ver.numero_cfdis}")
      log("      ids_paquetes:            #{inspect(ver.ids_paquetes)}")
      log("      mensaje:                 #{inspect(ver.mensaje)}")

      # cod_estatus manda: si la LLAMADA fallo, estado_solicitud no significa
      # nada (el SAT manda "0", que no es un estado valido).
      assert ver.cod_estatus in ["5000", "0", ""],
             "el SAT rechazo la consulta — CodEstatus #{ver.cod_estatus}: " <>
               "#{ver.mensaje}. Con 404 revisa que el IdSolicitud exista y sea " <>
               "de este RFC (#{Credential.rfc(ctx.cred)}); si persiste, es un " <>
               "fallo del SAT y hay que reintentar mas tarde."

      assert ver.estado_solicitud in [
               :aceptada,
               :en_proceso,
               :terminada,
               :error,
               :rechazada,
               :vencida
             ],
             "estado inesperado: #{inspect(ver.estado_solicitud)}"

      case ver.estado_solicitud do
        :terminada ->
          log("      → LISTA: #{length(ver.ids_paquetes)} paquete(s) para descargar.")
          log("        Corre el test de descarga con SAT_ID_SOLICITUD=#{id_solicitud}")
          assert ver.ids_paquetes != [] or ver.numero_cfdis == 0

        :rechazada when ver.codigo_estado_solicitud == "5004" ->
          log("      → RECHAZADA 5004: sin CFDIs en el rango que pediste.")
          assert ver.numero_cfdis == 0

        :vencida ->
          log("      → VENCIDA: los paquetes viven 72h. Hay que volver a solicitar.")

        estado when estado in [:aceptada, :en_proceso] ->
          log("      → AÚN EN PROCESO: vuelve a verificar más tarde.")

        estado ->
          log(
            "      → terminal sin paquetes: #{inspect(estado)} " <>
              "(codigo #{ver.codigo_estado_solicitud})."
          )
      end

      log("OK — verificación completada (no se registró ninguna solicitud nueva).")
    end

    @tag :real_sat
    test "descargar la metadata de un IdSolicitud ya terminado", ctx do
      skip_if_needed(ctx)
      skip_si_no_es_fiel(ctx)

      id_solicitud = id_solicitud()

      log("============================================================")
      log("Descarga Masiva SAT — DESCARGAR metadata de solicitud existente")
      log("------------------------------------------------------------")
      log("RFC:         #{Credential.rfc(ctx.cred)}")
      log("IdSolicitud: #{id_solicitud}")
      log("OJO: cada paquete solo se puede descargar 2 VECES (luego da 5008).")
      log("============================================================")

      activar_dump_soap()

      log("[1/3] Autenticando con e.firma...")
      assert {:ok, token} = Autenticacion.autenticar(credential: ctx.cred)

      log("[2/3] Verificando que este terminada...")

      assert {:ok, ver} =
               Verificacion.verificar(token, id_solicitud,
                 credential: ctx.cred,
                 timeout: env_int("SAT_TIMEOUT_MS", 90_000)
               )

      inspeccionar(ver, "VERIFICACION — respuesta parseada")

      log("      estado: #{inspect(ver.estado_solicitud)} | cfdis: #{ver.numero_cfdis}")
      log("      paquetes: #{inspect(ver.ids_paquetes)}")

      assert ver.estado_solicitud == :terminada,
             "la solicitud #{id_solicitud} no esta :terminada — " <>
               "#{inspect(ver.estado_solicitud)} (codigo #{ver.codigo_estado_solicitud}). " <>
               "Si es :aceptada/:en_proceso espera; si es :vencida (>72h) hay que " <>
               "volver a solicitarla."

      assert ver.ids_paquetes != [],
             "terminada pero sin paquetes (numero_cfdis: #{ver.numero_cfdis})"

      log("[3/3] Descargando #{length(ver.ids_paquetes)} paquete(s)...")

      unless System.get_env("SAT_DUMP_PAQUETE") == "1" do
        desactivar_dump_soap()
        log("      (SOAP del paquete NO se vuelca; usa SAT_DUMP_PAQUETE=1 para verlo)")
      end

      total = descargar_paquetes(token, ver.ids_paquetes, ctx.cred)

      log("OK — #{total} fila(s) de metadata descargadas.")
      assert total > 0
    end
  end

  # --- helpers ---

  # IdSolicitud a inspeccionar en los tests de "solicitud ya registrada".
  # Sobreescribelo SIEMPRE con SAT_ID_SOLICITUD: el default es solo el ultimo
  # que se registro a mano, y las solicitudes vencen a las 72h.
  defp id_solicitud do
    System.get_env("SAT_ID_SOLICITUD") || "c7a37590-b1f4-4952-b18d-04b4418c99ee"
  end

  # Descarga cada paquete, imprime el TSV crudo y las filas parseadas.
  # Devuelve el total de filas. Compartido por el flujo completo y por el
  # test que trabaja sobre una solicitud ya registrada.
  defp descargar_paquetes(token, ids_paquetes, cred) do
    for id <- ids_paquetes, reduce: 0 do
      acc ->
        assert {:ok, %Types.Paquete{} = paq} = Paquete.descargar(token, id, credential: cred)

        # El struct completo trae el ZIP binario: se imprime sin el content
        # para que se lea, y el content va aparte ya decodificado.
        inspeccionar(
          %{paq | content: "<#{byte_size(paq.content)} bytes de ZIP>"},
          "PAQUETE #{id} — struct parseado"
        )

        assert paq.id == id
        assert is_binary(paq.content) and byte_size(paq.content) > 0
        log("      paquete #{id}: ZIP de #{paq.size} bytes")

        # El paquete de metadata trae UN .txt, no XMLs.
        assert {:ok, files} = Reader.list_files(paq)
        log("        archivos: #{inspect(files)}")

        assert Enum.any?(files, &String.ends_with?(String.downcase(&1), ".txt")),
               "un paquete de metadata debe traer un .txt, trajo: #{inspect(files)}"

        # El TSV CRUDO, tal cual lo escribe el SAT dentro del ZIP.
        imprimir_txt_crudo(paq)

        assert {:ok, filas} = Reader.parse_metadata(paq)
        log("        #{length(filas)} fila(s) de metadata")

        if filas != [] do
          log("        columnas: #{inspect(filas |> hd() |> Map.keys())}")
          inspeccionar(hd(filas), "PRIMERA FILA — map ya parseado")
          imprimir_filas(tomar_filas(filas))

          Enum.each(filas, fn fila ->
            assert is_binary(fila[:uuid]) and fila[:uuid] != "",
                   "fila sin UUID: #{inspect(fila)}"
          end)
        end

        acc + length(filas)
    end
  end

  defp skip_if_needed(ctx) do
    if ctx[:skip] do
      IO.puts("[metadata] SKIP: #{ctx.skip}")
      flunk("test skipped: #{ctx.skip}")
    end
  end

  # El WS de Descarga Masiva sólo acepta e.firma. Con el CSD commiteado el SAT
  # responde 300/305, así que no tiene caso gastar la llamada.
  defp skip_si_no_es_fiel(%{csd_pruebas?: true}) do
    IO.puts(
      "[metadata] SKIP: estas usando el CSD de PRUEBAS commiteado (#{@test_cer}) " <>
        "y el WS de Descarga Masiva sólo acepta e.firma. Exporta SAT_FIEL_CER / " <>
        "SAT_FIEL_KEY / SAT_FIEL_PASSWORD apuntando a tu e.firma."
    )

    flunk("test skipped: se requiere e.firma real")
  end

  defp skip_si_no_es_fiel(_ctx), do: :ok

  defp build_params(ctx, rfc) do
    %Types.SolicitudParams{
      rfc_solicitante: rfc,
      fecha_inicial: to_datetime(ctx.fecha_inicio, ~T[00:00:00]),
      fecha_final: to_datetime(ctx.fecha_fin, ~T[23:59:59]),
      # DIRECCIÓN: emitidos | recibidos → elige la operación SOAP.
      tipo_solicitud: ctx.tipo,
      # CONTENIDO: metadata → atributo TipoSolicitud="Metadata".
      tipo_descarga: :metadata,
      # En metadata sí puedes pedir cancelados (en CFDI el SAT devuelve 301).
      estado_comprobante: ctx.estado
    }
  end

  # SAT_FECHA_INICIO/FIN ganan; si no, SAT_MES=YYYY-MM; si no, el mes pasado.
  defp rango_de_fechas do
    mes =
      case System.get_env("SAT_MES") do
        nil -> mes_pasado()
        valor -> parse_mes(valor)
      end

    inicio = System.get_env("SAT_FECHA_INICIO") || Date.to_iso8601(Date.beginning_of_month(mes))
    fin = System.get_env("SAT_FECHA_FIN") || Date.to_iso8601(Date.end_of_month(mes))

    {inicio, fin}
  end

  defp parse_mes(valor) do
    case Date.from_iso8601(valor <> "-01") do
      {:ok, date} ->
        date

      {:error, _} ->
        raise ArgumentError, "SAT_MES debe ser \"YYYY-MM\", recibí: #{inspect(valor)}"
    end
  end

  defp mes_pasado do
    Date.utc_today() |> Date.beginning_of_month() |> Date.add(-1) |> Date.beginning_of_month()
  end

  defp to_datetime(date_str, time) do
    date_str |> Date.from_iso8601!() |> DateTime.new!(time, "Etc/UTC")
  end

  defp parse_tipo("emitidos"), do: :emitidos
  defp parse_tipo(_), do: :recibidos

  defp parse_estado("vigente"), do: :vigente
  defp parse_estado("cancelado"), do: :cancelado
  defp parse_estado(_), do: :todos

  defp env_int(name, default) do
    name |> System.get_env(to_string(default)) |> String.to_integer()
  end

  # `Internal.Http` ya loguea request y response CRUDOS en :debug. Subimos el
  # nivel y enchufamos SoapDumpHandler, que los imprime sin el truncado de
  # 8096 bytes del handler default (el default se silencia para no duplicar).
  defp activar_dump_soap do
    nivel_anterior = Logger.level()
    {:ok, %{level: nivel_default}} = :logger.get_handler_config(:default)

    Logger.configure(level: :debug)
    :logger.update_handler_config(:default, :level, :info)
    :logger.add_handler(:sat_soap_dump, SoapDumpHandler, %{level: :debug})

    on_exit(fn ->
      :logger.remove_handler(:sat_soap_dump)
      :logger.update_handler_config(:default, :level, nivel_default)
      Logger.configure(level: nivel_anterior)
    end)

    :ok
  end

  defp desactivar_dump_soap, do: :logger.remove_handler(:sat_soap_dump)

  defp inspeccionar(valor, etiqueta) do
    log("===== #{etiqueta} =====")
    IO.inspect(valor, limit: :infinity, printable_limit: :infinity, pretty: true)
  end

  # El .txt tal cual viene dentro del ZIP del SAT (sin parsear).
  defp imprimir_txt_crudo(%Types.Paquete{content: zip}) do
    with {:ok, archivos} <- :zip.unzip(zip, [:memory]),
         {nombre, contenido} <-
           Enum.find(archivos, fn {n, _} ->
             String.ends_with?(String.downcase(to_string(n)), ".txt")
           end) do
      {header, filas} =
        case contenido |> to_string() |> String.split(["\r\n", "\n"], trim: true) do
          [] -> {"(archivo vacio)", []}
          [h | resto] -> {h, resto}
        end

      log("        ---- #{nombre} (TSV CRUDO del SAT) ----")
      log("        HEADER: #{header}")

      filas
      |> tomar_filas()
      |> Enum.each(fn linea -> log("        #{linea}") end)

      if length(filas) > length(tomar_filas(filas)) do
        log("        ... (#{length(filas)} filas en total; SAT_DUMP_FILAS=all para verlas todas)")
      end

      log("        ---- fin del TSV crudo ----")
    else
      otro -> log("        no se pudo leer el .txt crudo: #{inspect(otro)}")
    end
  end

  # Cuantas filas imprimir: SAT_DUMP_FILAS = numero | "all" (default 10).
  defp tomar_filas(filas) do
    case System.get_env("SAT_DUMP_FILAS", "10") do
      "all" -> filas
      n -> Enum.take(filas, String.to_integer(n))
    end
  end

  defp imprimir_filas(filas) do
    Enum.each(filas, fn fila ->
      log(
        "        #{fila[:uuid]} | #{fila[:rfcemisor]} → #{fila[:rfcreceptor]} | " <>
          "#{fila[:fechaemision]} | $#{fila[:monto]} | #{fila[:estatus]}"
      )
    end)
  end

  defp build_zip(entries) do
    erl_entries = Enum.map(entries, fn {name, data} -> {String.to_charlist(name), data} end)
    {:ok, {_filename, zip_bin}} = :zip.create(~c"in_memory.zip", erl_entries, [:memory])
    zip_bin
  end

  defp log(msg), do: IO.puts("[metadata] " <> msg)
end
