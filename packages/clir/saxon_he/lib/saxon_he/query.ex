defmodule SaxonHe.Query do
  @moduledoc """
  Wrapper de `saxon-he query` (XQuery). Espejo de
  [`query.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/clir/saxon-he/src/query.ts).

  Hereda los flags comunes de `SaxonHe.CliShare` y agrega los específicos
  de query (`-q`, `-qs`, `-projection`, etc).

      {:ok, output} =
        SaxonHe.Query.new()
        |> SaxonHe.Query.q("query.xq")
        |> SaxonHe.Query.s("data.xml")
        |> SaxonHe.Query.run()
  """

  defstruct args: [], binary: "query"

  @type t :: %__MODULE__{args: [String.t()], binary: String.t()}

  use SaxonHe.CliShare

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{binary: Keyword.get(opts, :binary, "query")}
  end

  @doc "Append `-a:on|off` (backup mode for XQuery Update)."
  def backup(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-a:#{opt}")

  @doc "Append `-config:filenames`."
  def config(%__MODULE__{} = t, filenames),
    do: SaxonHe.CliShare.append(t, "-config:#{filenames}")

  @doc "Append `-mr:classname` (Module URI Resolver)."
  def mr(%__MODULE__{} = t, classname), do: SaxonHe.CliShare.append(t, "-mr:#{classname}")

  @doc "Append `-projection:on|off`."
  def projection(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-projection:#{opt}")

  @doc "Append `-q:queryfile`."
  def q(%__MODULE__{} = t, queryfile), do: SaxonHe.CliShare.append(t, "-q:#{queryfile}")

  @doc "Alias para `q/2` con nombre más descriptivo."
  def query_file(%__MODULE__{} = t, queryfile), do: q(t, queryfile)

  @doc "Append `-qs:querystring` (XQuery inline)."
  def qs(%__MODULE__{} = t, querystring),
    do: SaxonHe.CliShare.append(t, "-qs:#{querystring}")

  @doc "Append `-stream:on|off`."
  def stream(%__MODULE__{} = t, opt) when opt in ["on", "off"],
    do: SaxonHe.CliShare.append(t, "-stream:#{opt}")

  @doc "Append `-update:on|off|discard`."
  def update(%__MODULE__{} = t, opt) when opt in ["on", "off", "discard"],
    do: SaxonHe.CliShare.append(t, "-update:#{opt}")

  @doc "Append `-wrap`."
  def wrap(%__MODULE__{} = t), do: SaxonHe.CliShare.append(t, "-wrap")

  @doc """
  Ejecuta `<binary> <args>` (default binary: `query`). Mismas opciones que
  `SaxonHe.Transform.run/2`.
  """
  @spec run(t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def run(%__MODULE__{binary: binary, args: args}, opts \\ []) do
    SaxonHe.run(binary, args, opts)
  end

  @spec build_args(t()) :: [String.t()]
  def build_args(%__MODULE__{args: args}), do: args
end
