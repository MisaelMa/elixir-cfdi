defmodule Cfdi.Concepto.Complemento do
  @moduledoc """
  `cfdi:ComplementoConcepto` — contenedor de complementos fiscales
  anidados dentro de un `cfdi:Concepto` (ej. `iedu:instEducativas`).

  Cada hijo es un struct de `Cfdi.Complementos.*` que implementa el
  comportamiento `Cfdi.Complementos.Complemento` (expone `get_complement/1`
  con su tag, xmlns y payload). El contenedor nunca inventa el tag o los
  atributos — delega en el complemento.
  """

  use Cfdi.Xml.Element, tag: "cfdi:ComplementoConcepto", accepts_children: true

  child :complementos, :list

  @doc """
  Añade un complemento (struct que implementa `Cfdi.Complementos.Complemento`).
  """
  def add(c, complemento) when is_struct(c, __MODULE__) and is_struct(complemento) do
    list = (c.complementos || []) ++ [complemento]
    %{c | complementos: list}
  end

  def to_element(nil), do: nil

  def to_element(c) when is_struct(c, __MODULE__) do
    kids =
      (c.complementos || [])
      |> Enum.map(&complemento_to_element/1)
      |> Enum.reject(&is_nil/1)

    XmlBuilder.element({"cfdi:ComplementoConcepto", %{}, kids})
  end

  @doc false
  def to_map(nil, _opts), do: nil

  def to_map(c, opts) when is_struct(c, __MODULE__) and is_list(opts) do
    ns? = Keyword.get(opts, :ns, true)
    wrap? = Keyword.get(opts, :wrap, true)

    body =
      (c.complementos || [])
      |> Enum.map(&complemento_to_pair/1)
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    if wrap? do
      key = if ns?, do: "cfdi:ComplementoConcepto", else: "ComplementoConcepto"
      %{key => body}
    else
      body
    end
  end

  defp complemento_to_element(%mod{} = s) do
    if function_exported?(mod, :get_complement, 1) do
      %{key: key, complement: payload} = mod.get_complement(s)
      XmlBuilder.element({key, stringify_attrs(payload), nil})
    else
      nil
    end
  end

  defp complemento_to_pair(%mod{} = s) do
    if function_exported?(mod, :get_complement, 1) do
      %{key: key, complement: payload} = mod.get_complement(s)
      {key, payload}
    else
      nil
    end
  end

  defp stringify_attrs(attrs) when is_map(attrs) do
    attrs
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  defp stringify_attrs(_), do: %{}
end
