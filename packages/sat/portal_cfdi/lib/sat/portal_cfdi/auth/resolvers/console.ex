defmodule Sat.PortalCfdi.Auth.Resolvers.Console do
  @moduledoc """
  Resolver manual: guarda la imagen del captcha en disco y le pide al
  operador que escriba la respuesta por stdin.

  Uso tipico durante desarrollo o pruebas interactivas.

  Equivalente a `phpcfdi/image-captcha-resolver`'s `ConsoleResolver`.
  """

  @behaviour Sat.PortalCfdi.Auth.CaptchaResolver

  @impl true
  def resolve(image) when is_binary(image), do: resolve(image, [])

  @impl true
  def resolve(image, opts) when is_binary(image) and is_list(opts) do
    dir = Keyword.get(opts, :tmp_dir, System.tmp_dir!())
    extension = detect_extension(image)
    filename = "sat_captcha_#{:erlang.unique_integer([:positive])}.#{extension}"
    path = Path.join(dir, filename)

    File.write!(path, image)
    IO.puts("\n[SAT captcha] imagen guardada en: #{path}")
    IO.puts("[SAT captcha] abrila, leela y escribe el texto:")

    case IO.gets("> ") do
      :eof -> {:error, :eof}
      {:error, reason} -> {:error, reason}
      line when is_binary(line) -> {:ok, String.trim(line)}
    end
  end

  defp detect_extension(<<0x89, 0x50, 0x4E, 0x47, _::binary>>), do: "png"
  defp detect_extension(<<0xFF, 0xD8, _::binary>>), do: "jpg"
  defp detect_extension(_), do: "bin"
end
