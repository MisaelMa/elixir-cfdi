defmodule SaxonHe.Transform do
  @moduledoc """
  Wrapper de `saxon-he transform` (XSLT). Espejo de
  [`transform.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/clir/saxon-he/src/transform.ts).

  Hereda los flags comunes de `SaxonHe.CliShare` y agrega los específicos
  de transform (`-xsl`, `-warnings`, `-target`, etc).

      {:ok, output} =
        SaxonHe.Transform.new()
        |> SaxonHe.Transform.s("comprobante.xml")
        |> SaxonHe.Transform.xsl("cadenaoriginal.xslt")
        |> SaxonHe.Transform.o("cadena.txt")
        |> SaxonHe.Transform.run()
  """

  defstruct args: [], binary: "transform"

  @type t :: %__MODULE__{args: [String.t()], binary: String.t()}

  use SaxonHe.CliShare

  @doc """
  Crea una nueva instancia. Acepta `:binary` para sobreescribir el subcomando
  por defecto (no se usa cuando se invoca el JAR directamente con `-jar`).
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{binary: Keyword.get(opts, :binary, "transform")}
  end

  @doc "Append `-a:on|off` (use xml-stylesheet PI)."
  def a(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-a:#{opt}")

  @doc "Append `-ea:on|off` (early-evaluation assertions)."
  def ea(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-ea:#{opt}")

  @doc "Append `-explain:filename`."
  def explain(%__MODULE__{} = t, filename),
    do: SaxonHe.CliShare.append(t, "-explain:#{filename}")

  @doc "Append `-export:filename`."
  def export(%__MODULE__{} = t, filename),
    do: SaxonHe.CliShare.append(t, "-export:#{filename}")

  @doc "Append `-im:modename` (initial mode)."
  def im(%__MODULE__{} = t, modename), do: SaxonHe.CliShare.append(t, "-im:#{modename}")

  @doc "Append `-it:template` (initial template)."
  def it(%__MODULE__{} = t, template), do: SaxonHe.CliShare.append(t, "-it:#{template}")

  @doc "Append `-jit:on|off` (just-in-time compilation)."
  def jit(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-jit:#{opt}")

  @doc "Append `-lib:filenames`."
  def lib(%__MODULE__{} = t, filenames),
    do: SaxonHe.CliShare.append(t, "-lib:#{filenames}")

  @doc "Append `-license:on|off`."
  def license(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-license:#{opt}")

  @doc "Append `-m:classname` (Message receiver)."
  def m(%__MODULE__{} = t, classname), do: SaxonHe.CliShare.append(t, "-m:#{classname}")

  @doc "Append `-nogo`."
  def nogo(%__MODULE__{} = t), do: SaxonHe.CliShare.append(t, "-nogo")

  @doc "Append `-ns:uri|##any|##html5`."
  def ns(%__MODULE__{} = t, opt) when opt in ["uri", "##any", "##html5"],
    do: SaxonHe.CliShare.append(t, "-ns:#{opt}")

  @doc "Append `-or:classname` (Output Resolver)."
  def or_resolver(%__MODULE__{} = t, classname),
    do: SaxonHe.CliShare.append(t, "-or:#{classname}")

  @doc "Append `-relocate:on|off`."
  def relocate(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-relocate:#{opt}")

  @doc "Append `-target:EE|PE|HE|JS`."
  def target(%__MODULE__{} = t, target) when target in ["EE", "PE", "HE", "JS"],
    do: SaxonHe.CliShare.append(t, "-target:#{target}")

  @doc "Append `-threads:N`."
  def threads(%__MODULE__{} = t, n) when is_integer(n),
    do: SaxonHe.CliShare.append(t, "-threads:#{n}")

  @doc "Append `-warnings:silent|recover|fatal`."
  def warnings(%__MODULE__{} = t, opt) when opt in ["silent", "recover", "fatal"],
    do: SaxonHe.CliShare.append(t, "-warnings:#{opt}")

  @doc """
  Append `-xsl:filename`. Lanza si el archivo no existe (paridad con Node).
  """
  def xsl(%__MODULE__{} = t, filename) do
    unless File.exists?(filename) do
      raise ArgumentError, "No se puede encontrar el archivo XSLT => #{filename}"
    end

    SaxonHe.CliShare.append(t, "-xsl:#{filename}")
  end

  @doc "Append `-y:filename` (style parser)."
  def y(%__MODULE__{} = t, filename), do: SaxonHe.CliShare.append(t, "-y:#{filename}")

  @doc """
  Ejecuta `<binary> <args>` (default binary: `transform`). Devuelve
  `{:ok, stdout}` o `{:error, reason}`.

  ## Opciones

    * `:silent_stderr` (default `false`) — combina stderr con stdout y lo
      descarta. Útil cuando el XSLT genera warnings (`Ambiguous rule match`)
      que no quieres en la salida del test.
    * `:cmd_opts` (default `[]`) — opciones extra para `System.cmd/3`.
  """
  @spec run(t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def run(%__MODULE__{binary: binary, args: args}, opts \\ []) do
    SaxonHe.run(binary, args, opts)
  end

  @doc """
  Devuelve la lista de argumentos acumulada (sin `-jar <jar>` por delante).
  """
  @spec build_args(t()) :: [String.t()]
  def build_args(%__MODULE__{args: args}), do: args

  # ---------------------------------------------------------------------------
  # Aliases por nombre largo. Mantengo la API previa de Elixir (`xsl/source/output`)
  # para no romper a quienes ya la consumen.
  # ---------------------------------------------------------------------------
end
