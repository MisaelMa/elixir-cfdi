defmodule Cfdi.Xsd.Schema do
  @moduledoc false

  alias Cfdi.Xsd.SchemaKey

  defstruct opts: []

  @type t :: %__MODULE__{opts: keyword()}

  @doc """
  Crea un cargador de esquemas con opciones por defecto (`schema_root` apunta a `priv/schemas`).
  """
  def of(opts \\ []) when is_list(opts) do
    root =
      Keyword.get(opts, :schema_root) ||
        Application.get_env(:cfdi_xsd, :schema_root) ||
        Path.join(:code.priv_dir(:cfdi_xsd), "schemas")

    %__MODULE__{opts: Keyword.put(opts, :schema_root, root)}
  end

  @doc """
  Equivale a `set_config(of(), opts)`.
  """
  def set_config(opts) when is_list(opts), do: set_config(of(), opts)

  def set_config(%__MODULE__{} = s, opts) when is_list(opts) do
    %{s | opts: Keyword.merge(s.opts, opts)}
  end

  @doc """
  Carga y resuelve el esquema JSON del comprobante CFDI.
  """
  def cfdi, do: cfdi(of())

  def cfdi(%__MODULE__{} = s) do
    load_named(s, SchemaKey.schema_filename(:cfdi))
  end

  @doc """
  Carga y resuelve el esquema JSON de un concepto.
  """
  def concepto, do: concepto(of())

  def concepto(%__MODULE__{} = s) do
    load_named(s, SchemaKey.schema_filename(:concepto))
  end

  defp load_named(%__MODULE__{opts: opts}, name) do
    root = Keyword.fetch!(opts, :schema_root)
    path = Path.join(root, name)

    with {:ok, bin} <- File.read(path),
         {:ok, map} <- Jason.decode(bin) do
      {:ok, ExJsonSchema.Schema.resolve(map)}
    else
      {:error, :enoent} -> {:error, {:missing_schema, path}}
      {:error, %Jason.DecodeError{} = e} -> {:error, {:invalid_json, e}}
      {:error, reason} -> {:error, reason}
    end
  end
end
