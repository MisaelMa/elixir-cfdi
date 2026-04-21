defmodule SaxonHe.Query do
  @moduledoc """
  Encapsula invocaciones a Saxon-HE para consultas XQuery vía CLI.
  """

  defstruct [:query_file, :source, options: []]

  @type t :: %__MODULE__{
          query_file: String.t() | nil,
          source: String.t() | nil,
          options: keyword()
        }

  def new, do: %__MODULE__{}

  def query_file(%__MODULE__{} = t, path), do: %{t | query_file: path}
  def source(%__MODULE__{} = t, path), do: %{t | source: path}

  @spec build_args(t()) :: [String.t()]
  def build_args(%__MODULE__{} = t) do
    []
    |> maybe_add("-q:", t.query_file)
    |> maybe_add("-s:", t.source)
    |> Kernel.++(List.wrap(Keyword.get(t.options, :extra_args, [])))
  end

  defp maybe_add(acc, _prefix, nil), do: acc
  defp maybe_add(acc, prefix, path), do: acc ++ [prefix <> path]

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

  defp validate_paths(%{query_file: q, source: s}) do
    cond do
      is_nil(q) -> {:error, :missing_query_file}
      is_nil(s) -> {:error, :missing_source}
      true -> :ok
    end
  end
end
