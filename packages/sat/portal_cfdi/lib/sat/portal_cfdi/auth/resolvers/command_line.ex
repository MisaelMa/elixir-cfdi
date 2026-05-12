defmodule Sat.PortalCfdi.Auth.Resolvers.CommandLine do
  @moduledoc """
  Ejecuta un comando externo (Tesseract OCR, etc.) pasandole la imagen del
  captcha y leyendo el ultimo renglon de la salida estandar como respuesta.

  Equivalente a `phpcfdi/image-captcha-resolver`'s `CommandLineResolver`.

  ## Opciones

    * `:command` (requerido) — string del comando o lista [cmd | args].
      Si la lista contiene `"%IMAGE%"` se reemplaza por el path temporal.
    * `:tmp_dir` — directorio para guardar la imagen (default System.tmp_dir!())

  ## Ejemplos

      # Tesseract
      captcha_resolver: {CommandLine, command: ["tesseract", "%IMAGE%", "-", "--psm", "8"]}

      # script propio
      captcha_resolver: {CommandLine, command: ["/usr/local/bin/sat-ocr", "%IMAGE%"]}
  """

  @behaviour Sat.PortalCfdi.Auth.CaptchaResolver

  @impl true
  def resolve(image) when is_binary(image), do: {:error, :command_required}

  @impl true
  def resolve(image, opts) when is_binary(image) and is_list(opts) do
    with {:ok, command} <- fetch_command(opts) do
      tmp_dir = Keyword.get(opts, :tmp_dir, System.tmp_dir!())
      path = Path.join(tmp_dir, "sat_captcha_#{:erlang.unique_integer([:positive])}.bin")
      File.write!(path, image)

      try do
        run_command(command, path)
      after
        File.rm(path)
      end
    end
  end

  defp fetch_command(opts) do
    case Keyword.get(opts, :command) do
      nil -> {:error, :command_required}
      cmd -> {:ok, cmd}
    end
  end

  defp run_command([cmd | args], image_path) do
    final_args = Enum.map(args, fn a -> if a == "%IMAGE%", do: image_path, else: a end)

    case System.cmd(cmd, final_args, stderr_to_stdout: true) do
      {output, 0} -> {:ok, last_nonempty_line(output)}
      {output, code} -> {:error, {:command_failed, code, output}}
    end
  rescue
    e -> {:error, {:command_exception, e}}
  end

  defp run_command(cmd, image_path) when is_binary(cmd) do
    full = String.replace(cmd, "%IMAGE%", image_path)

    case System.shell(full, stderr_to_stdout: true) do
      {output, 0} -> {:ok, last_nonempty_line(output)}
      {output, code} -> {:error, {:command_failed, code, output}}
    end
  end

  defp last_nonempty_line(output) do
    output
    |> String.split(["\r\n", "\n"], trim: true)
    |> Enum.reverse()
    |> Enum.find("", fn line -> String.trim(line) != "" end)
    |> String.trim()
  end
end
