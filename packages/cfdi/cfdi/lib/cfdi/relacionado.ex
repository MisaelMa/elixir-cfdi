defmodule Cfdi.Relacionado do
  @moduledoc """
  `cfdi:CfdiRelacionados` — grupo de CFDI relacionados bajo un
  `TipoRelacion` común.

  Equivalente a la clase `Relacionado` del paquete `@cfdi/xml` en Node.
  Cada grupo agrupa uno o más UUIDs (`Cfdi.Relacionado.CfdiRelacionado`).
  """

  use Cfdi.Xml.Element, tag: "cfdi:CfdiRelacionados", accepts_children: true

  alias Cfdi.Relacionado.CfdiRelacionado

  attribute :TipoRelacion, :string

  child :"cfdi:CfdiRelacionado", :list

  @doc """
  Añade un UUID al grupo.
  """
  def add_relation(r, %CfdiRelacionado{} = cr) when is_struct(r, __MODULE__) do
    list = (Map.get(r, :"cfdi:CfdiRelacionado") || []) ++ [cr]
    Map.put(r, :"cfdi:CfdiRelacionado", list)
  end

  def add_relation(r, uuid) when is_struct(r, __MODULE__) and is_binary(uuid) do
    add_relation(r, %CfdiRelacionado{UUID: uuid})
  end

  def to_element(nil), do: nil

  def to_element(r) when is_struct(r, __MODULE__) do
    kids =
      (Map.get(r, :"cfdi:CfdiRelacionado") || [])
      |> Enum.map(&CfdiRelacionado.to_element/1)
      |> Enum.reject(&is_nil/1)

    XmlBuilder.element(
      {"cfdi:CfdiRelacionados", Cfdi.Xml.Element.__build_attrs__(r, __MODULE__), kids}
    )
  end

  # Legacy bridge: versiones previas aceptaban un mapa plano `%{UUID, TipoRelacion}`.
  # Mantener este path evita romper callers que aún pasen mapas simples.
  def to_element(%{UUID: uuid, TipoRelacion: tipo}) when is_binary(uuid) do
    struct(__MODULE__, %{TipoRelacion: tipo})
    |> add_relation(uuid)
    |> to_element()
  end

  def to_element(data) when is_map(data) and not is_struct(data) do
    struct(__MODULE__, data) |> to_element()
  end

  @spec relacionados_block([t() | map()]) :: tuple() | nil
  def relacionados_block([]), do: nil

  def relacionados_block(items) when is_list(items) do
    kids = Enum.map(items, &to_element/1) |> Enum.reject(&is_nil/1)

    case kids do
      [single] -> single
      many -> many
    end
  end
end
