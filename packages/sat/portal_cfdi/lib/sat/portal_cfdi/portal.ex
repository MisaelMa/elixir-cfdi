defmodule Sat.PortalCfdi.Portal do
  @moduledoc """
  Fachada del cliente del portal CFDI del SAT.

  ## Flujo

      cred_ciec = %CredencialPortal{tipo: :ciec, ciec: %CredencialCIEC{rfc: "...", password: "..."}}
      {:ok, sesion} = Portal.login(cred_ciec, captcha_resolver: &mi_resolver/1)

      {:ok, lista}  = Portal.consultar_cfdis(sesion, %ConsultaCfdiParams{
        fecha_inicio: "2025-01-01",
        fecha_fin: "2025-01-31",
        tipo: :recibidos
      })

      Enum.each(lista, fn %{uuid: uuid} ->
        {:ok, xml} = Portal.descargar_xml(sesion, uuid)
        File.write!("./xmls/\#{uuid}.xml", xml)
      end)

      :ok = Portal.logout(sesion)
  """

  alias Sat.PortalCfdi.Auth.{Ciec, Fiel}
  alias Sat.PortalCfdi.Internal.{Consulta, Http}

  alias Sat.PortalCfdi.Types.{
    CfdiConsultaResult,
    ConsultaCfdiParams,
    CredencialPortal,
    SesionSAT
  }

  @base_url "https://portalcfdi.facturaelectronica.sat.gob.mx"

  @doc """
  Inicia sesion en el portal del SAT.

  Para CIEC requiere `:captcha_resolver` en `opts`.
  Para FIEL requiere los paths en la `CredencialFIEL` o un
  `:credential` (`Sat.Certificados.Credential`) en `opts`.
  """
  @spec login(CredencialPortal.t(), keyword()) :: {:ok, SesionSAT.t()} | {:error, term()}
  def login(%CredencialPortal{tipo: :ciec, ciec: ciec}, opts) when not is_nil(ciec) do
    Ciec.login(ciec, opts)
  end

  def login(%CredencialPortal{tipo: :fiel, fiel: fiel}, opts) do
    Fiel.login(fiel, opts)
  end

  def login(%CredencialPortal{tipo: tipo}, _opts) do
    {:error, {:invalid_credential, "tipo `#{tipo}` requiere :ciec o :fiel completo"}}
  end

  @doc """
  Consulta CFDIs en el portal (PRIMERA pagina solamente).

  Para iterar todas las paginas usar `consultar_todas_paginas/3`.
  Para obtener metadata de paginacion usar `consultar_paginado/3`.
  """
  @spec consultar_cfdis(SesionSAT.t(), ConsultaCfdiParams.t(), keyword()) ::
          {:ok, [CfdiConsultaResult.t()], SesionSAT.t()} | {:error, term()}
  def consultar_cfdis(sesion, params, opts \\ [])

  def consultar_cfdis(%SesionSAT{authenticated: true} = sesion, %ConsultaCfdiParams{} = params, opts) do
    case Consulta.consultar(sesion, params, opts) do
      {:ok, %{results: results}, sesion} -> {:ok, results, sesion}
      {:error, _} = e -> e
    end
  end

  def consultar_cfdis(%SesionSAT{authenticated: false}, _params, _opts) do
    {:error, {:sesion_no_autenticada, "llamar Portal.login/2 primero"}}
  end

  @doc """
  Consulta paginada: retorna la primera pagina con metadatos
  (`pagina_actual`, `total_paginas`, `total_cfdis`, `has_next`).

  Pasarle el resultado a `consultar_pagina/4` para ir a la siguiente.
  """
  @spec consultar_paginado(SesionSAT.t(), ConsultaCfdiParams.t(), keyword()) ::
          {:ok, Consulta.pagina(), SesionSAT.t()} | {:error, term()}
  def consultar_paginado(sesion, params, opts \\ [])

  def consultar_paginado(%SesionSAT{authenticated: true} = sesion, %ConsultaCfdiParams{} = params, opts) do
    Consulta.consultar(sesion, params, opts)
  end

  def consultar_paginado(%SesionSAT{authenticated: false}, _params, _opts) do
    {:error, {:sesion_no_autenticada, "llamar Portal.login/2 primero"}}
  end

  @doc """
  Va a una pagina especifica usando los hidden fields de la pagina anterior.
  """
  @spec consultar_pagina(SesionSAT.t(), Consulta.pagina(), pos_integer(), keyword()) ::
          {:ok, Consulta.pagina(), SesionSAT.t()} | {:error, term()}
  def consultar_pagina(%SesionSAT{authenticated: true} = sesion, pagina, n, opts \\ []) do
    Consulta.consultar_pagina(sesion, pagina, n, opts)
  end

  @doc """
  Itera todas las paginas y devuelve la lista combinada de CFDIs.

  Opciones:
    * `:max_paginas` (default 50)
    * `:delay_ms` (default 1500) — espera entre paginas
    * `:on_page` — callback `(pagina, acc -> :ok | :stop)` para reportar
      progreso

  ## Ejemplo

      Portal.consultar_todas_paginas(sesion, params,
        on_page: fn pag, acc ->
          IO.puts("pagina #\{pag.pagina_actual\} / #\{pag.total_paginas\} - acumulado: #\{length(acc)\}")
          :ok
        end
      )
  """
  @spec consultar_todas_paginas(SesionSAT.t(), ConsultaCfdiParams.t(), keyword()) ::
          {:ok, [CfdiConsultaResult.t()], Consulta.pagina(), SesionSAT.t()} | {:error, term()}
  def consultar_todas_paginas(sesion, params, opts \\ [])

  def consultar_todas_paginas(%SesionSAT{authenticated: true} = sesion, %ConsultaCfdiParams{} = params, opts) do
    Consulta.consultar_todas(sesion, params, opts)
  end

  def consultar_todas_paginas(%SesionSAT{authenticated: false}, _params, _opts) do
    {:error, {:sesion_no_autenticada, "llamar Portal.login/2 primero"}}
  end

  @doc """
  Descarga el XML de un CFDI por UUID.

  El portal expone `RecuperaCfdi.aspx?Datos=<uuid>` que retorna el XML
  directamente.
  """
  @spec descargar_xml(SesionSAT.t(), String.t(), keyword()) ::
          {:ok, String.t(), SesionSAT.t()} | {:error, term()}
  def descargar_xml(sesion, uuid, opts \\ [])

  def descargar_xml(%SesionSAT{authenticated: true} = sesion, uuid, opts)
      when is_binary(uuid) do
    url = @base_url <> "/RecuperaCfdi.aspx?Datos=" <> URI.encode_www_form(uuid)

    case Http.get(sesion, url, opts) do
      {:ok, %{status: 200, body: body}, sesion} ->
        if String.contains?(body, "<?xml") or String.contains?(body, "<cfdi:") do
          {:ok, body, sesion}
        else
          {:error, {:respuesta_no_es_xml, String.slice(body, 0, 200)}}
        end

      {:ok, %{status: status}, _} ->
        {:error, {:http_error, status}}

      {:error, _} = e ->
        e
    end
  end

  def descargar_xml(%SesionSAT{authenticated: false}, _uuid, _opts) do
    {:error, {:sesion_no_autenticada, "llamar Portal.login/2 primero"}}
  end

  @doc "Cierra la sesion del portal."
  @spec logout(SesionSAT.t(), keyword()) :: :ok
  def logout(%SesionSAT{} = sesion, opts \\ []) do
    case Http.get(sesion, @base_url <> "/logout.aspx", opts) do
      _ -> :ok
    end
  end
end
