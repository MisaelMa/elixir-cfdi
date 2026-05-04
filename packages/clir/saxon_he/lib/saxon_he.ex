defmodule SaxonHe do
  @moduledoc """
  Wrapper alrededor de Saxon-HE (XSLT 3.0 / XQuery 3.1).

  Mirror del paquete Node [`@saxon-he/cli`](https://github.com/MisaelMa/node-cfdi/tree/main/packages/clir/saxon-he).

  ## Modo de invocación

  Saxon expone dos comandos: `transform` (XSLT) y `query` (XQuery). Esta
  librería **invoca esos binarios directamente** vía `System.cmd/3` — no
  arranca un JVM con `-jar`. Esto significa que necesitas tener `transform`
  y/o `query` accesibles en tu `PATH` (o pasar `binary:` explícito en `new/1`).

  En macOS con Homebrew, el binario `saxon` viene en
  `/opt/homebrew/Cellar/saxon/<version>/bin/saxon`. Para tener un comando
  `transform` global puedes hacer:

      sudo ln -sf /opt/homebrew/Cellar/saxon/12.9/bin/saxon /usr/local/bin/transform

  ## Submódulos

    * `SaxonHe.Transform` — `transform` (XSLT).
    * `SaxonHe.Query` — `query` (XQuery).
    * `SaxonHe.CliShare` — flags compartidos (uso interno).

  ## Ejemplo

      {:ok, cadena} =
        SaxonHe.Transform.new()
        |> SaxonHe.Transform.s("comprobante.xml")
        |> SaxonHe.Transform.xsl("cadenaoriginal.xslt")
        |> SaxonHe.Transform.run()

  ## Configuración legacy del JAR

  `saxon_jar_path/0` sigue disponible para quien necesite construir un
  `java -jar` por su cuenta, pero la librería ya no lo usa internamente.
  """

  @doc """
  Devuelve la ruta configurada al JAR de Saxon-HE.

  Resuelve en orden:
    1. Variable de entorno `SAXON_JAR`.
    2. `config :saxon_he, :jar_path, "/path/to/saxon-he-12.jar"`.

  Lanza si no está configurada. Mantenido para compatibilidad — la librería
  ya no lo usa internamente; ahora invoca el binario `transform`/`query`.
  """
  @spec saxon_jar_path() :: String.t()
  def saxon_jar_path do
    System.get_env("SAXON_JAR") ||
      Application.get_env(:saxon_he, :jar_path) ||
      raise ArgumentError,
            "Set SAXON_JAR or config :saxon_he, :jar_path to your Saxon-HE JAR path"
  end

  @doc """
  `true` si el binario dado se puede invocar (está en `PATH` o es ruta
  absoluta a un ejecutable). Default: `transform`.
  """
  @spec available?(String.t()) :: boolean()
  def available?(binary \\ "transform"), do: resolve_binary(binary) != nil

  @doc """
  Ejecuta `<binary> <args>` con `System.cmd/3`.

  ## Opciones

    * `:silent_stderr` (default `false`) — combina stderr con stdout y lo
      descarta (`stderr_to_stdout: true, into: ""`). Útil para silenciar
      warnings de Saxon (`Ambiguous rule match`, etc).
    * `:cmd_opts` — opciones extra para `System.cmd/3`.

  Devuelve `{:ok, stdout}` si exit code 0, `{:error, {status, output}}` si no,
  o `{:error, {:binary_not_found, binary}}` si el ejecutable no se encuentra.
  """
  @spec run(String.t(), [String.t()], keyword()) ::
          {:ok, String.t()}
          | {:error, {integer(), String.t()}}
          | {:error, {:binary_not_found, String.t()}}
  def run(binary, args, opts \\ []) when is_binary(binary) and is_list(args) do
    case resolve_binary(binary) do
      nil ->
        {:error, {:binary_not_found, binary}}

      path ->
        cmd_opts = Keyword.get(opts, :cmd_opts, [])

        cmd_opts =
          if Keyword.get(opts, :silent_stderr, false) do
            Keyword.merge([stderr_to_stdout: true, into: ""], cmd_opts)
          else
            cmd_opts
          end

        case System.cmd(path, args, cmd_opts) do
          {out, 0} -> {:ok, out}
          {err, status} -> {:error, {status, err}}
        end
    end
  end

  # Resuelve un binario: si es ruta absoluta y existe + es ejecutable, la
  # devuelve; si es nombre simple, busca en PATH con `System.find_executable/1`.
  defp resolve_binary(binary) do
    if Path.type(binary) == :absolute do
      if File.exists?(binary), do: binary, else: nil
    else
      System.find_executable(binary)
    end
  end
end
