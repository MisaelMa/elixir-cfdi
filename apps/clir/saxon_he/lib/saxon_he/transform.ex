defmodule SaxonHe.Transform do
  @moduledoc """
  Encapsula invocaciones a Saxon-HE para transformaciones XSLT (`java -jar …`).
  """

  defstruct [:source, :xsl, :output, options: []]

  @type t :: %__MODULE__{
          source: String.t() | nil,
          xsl: String.t() | nil,
          output: String.t() | nil,
          options: keyword()
        }

  def new, do: %__MODULE__{}

  def source(%__MODULE__{} = t, path), do: %{t | source: path}
  def xsl(%__MODULE__{} = t, path), do: %{t | xsl: path}
  def output(%__MODULE__{} = t, path), do: %{t | output: path}

  @doc """
  Builds arguments passed to Saxon after `-jar` (i.e. everything except `java` and `-jar <path>`).
  """
  @spec build_args(t()) :: [String.t()]
  def build_args(%__MODULE__{} = t) do
    required =
      []
      |> maybe_add("-s:", t.source)
      |> maybe_add("-xsl:", t.xsl)
      |> maybe_add("-o:", t.output)

    required ++ List.wrap(Keyword.get(t.options, :extra_args, []))
  end

  defp maybe_add(acc, _prefix, nil), do: acc
  defp maybe_add(acc, prefix, path), do: acc ++ [prefix <> path]

  @doc """
  Runs Saxon-HE via `java -jar <saxon.jar> ...`.

  Returns `{:ok, output}` on success (stdout) or `{:error, {status, stderr}}` on failure.
  """
  @spec run(t()) :: {:ok, String.t()} | {:error, term()}
  def run(%__MODULE__{} = t) do
    with :ok <- validate_paths(t) do
      jar = SaxonHe.saxon_jar_path()
      args = ["-jar", jar] ++ build_args(t)
      opts = Keyword.merge([stderr_to_stdout: false], Keyword.get(t.options, :cmd_opts, []))

      case System.cmd("java", args, opts) do
        {out, 0} -> {:ok, out}
        {err, status} -> {:error, {status, err}}
      end
    end
  end

  defp validate_paths(%{source: s, xsl: x, output: o}) do
    cond do
      is_nil(s) -> {:error, :missing_source}
      is_nil(x) -> {:error, :missing_xsl}
      is_nil(o) -> {:error, :missing_output}
      true -> :ok
    end
  end
end
