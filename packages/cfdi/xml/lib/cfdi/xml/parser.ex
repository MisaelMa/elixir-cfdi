defmodule Cfdi.Xml.Parser do
  @moduledoc """
  Convierte un XML CFDI a un mapa anidado al estilo de `@cfdi/xml2json`.

  Acepta una ruta a un archivo XML o el XML directamente como cadena.

  ## Opciones

    * `:original` - cuando es `true`, mantiene el prefijo de namespace en
      los nombres de elemento (`cfdi:Comprobante`). Por defecto los
      nombres se devuelven sin prefijo.
    * `:keys` - controla el tipo de claves del mapa resultante.
      `:string` (por defecto) usa cadenas (`%{"Comprobante" => ...}`),
      `:atom` usa átomos (`%{Comprobante: ...}`).
    * `:case` - controla la capitalización de los nombres.
      `:as_is` (por defecto) deja los nombres tal cual aparecen en el XML
      (`Emisor`, `ClaveProdServ`). `:lower` los pasa a minúsculas
      (`emisor`, `claveprodserv`) tanto en elementos como en atributos.

  ## Namespaces

  Las declaraciones `xmlns` y `xmlns:<prefijo>` no se mezclan con los
  atributos del elemento; en su lugar se agrupan bajo la llave `meta`,
  usando el prefijo como llave. Esto evita átomos feos del estilo
  `:"xmlns:iedu"` cuando se trabaja con `keys: :atom`:

      %{instEducativas: %{
          meta: %{iedu: "http://www.sat.gob.mx/iedu"},
          rfcPago: "...",
          ...
        }}
  """

  @type opts :: [
          original: boolean(),
          keys: :string | :atom,
          case: :as_is | :lower
        ]

  @spec parse(String.t(), opts()) :: map()
  def parse(path_or_xml, opts \\ []) when is_binary(path_or_xml) do
    ctx = %{
      original: Keyword.get(opts, :original, false),
      keys: Keyword.get(opts, :keys, :string),
      case: Keyword.get(opts, :case, :as_is)
    }

    xml =
      if String.contains?(path_or_xml, "<") do
        path_or_xml
      else
        File.read!(path_or_xml)
      end

    {:ok, root} = Saxy.SimpleForm.parse_string(xml)
    to_compacts([root], apply_case("Comprobante", ctx.case), ctx)
  end

  defp to_compacts(elements, parent, ctx) do
    filtered = Enum.filter(elements, &match?({_, _, _}, &1))
    force_plural? = repeated_same_name?(filtered, ctx)

    filtered
    |> Enum.with_index()
    |> Enum.reduce(nil, fn {element, idx}, acc ->
      compact_element(element, idx, parent, force_plural?, ctx, acc)
    end)
  end

  defp repeated_same_name?(filtered, ctx) when length(filtered) > 1 do
    filtered
    |> Enum.map(fn {raw_name, _, _} -> transform_name(to_string(raw_name), ctx) end)
    |> Enum.uniq()
    |> length() == 1
  end

  defp repeated_same_name?(_filtered, _ctx), do: false

  defp compact_element({raw_name, attrs, children}, idx, parent, force_plural?, ctx, acc) do
    name = transform_name(to_string(raw_name), ctx)
    has_attrs? = attrs != []
    residual = String.replace(parent, name, "", global: false)
    element_plural? = force_plural? or residual in ["s", "es"]

    acc = maybe_put_attrs(acc, attrs, has_attrs?, element_plural?, idx, name, ctx)
    sub_elements = Enum.filter(children, &match?({_, _, _}, &1))

    cond do
      sub_elements == [] ->
        acc

      element_plural? and (is_nil(acc) or is_list(acc)) ->
        list = acc || []
        compact = to_compacts(sub_elements, name, ctx)
        existing = at_index_or_empty(list, idx)
        merged = if is_map(compact), do: Map.merge(existing, compact), else: existing
        put_at_index(list, idx, merged)

      not element_plural? and (is_nil(acc) or is_map(acc)) ->
        map = acc || %{}
        compact = to_compacts(sub_elements, name, ctx)

        if is_list(compact) do
          put_key(map, name, compact, ctx.keys)
        else
          existing = get_key(map, name, ctx.keys) || %{}
          put_key(map, name, Map.merge(existing, compact), ctx.keys)
        end

      true ->
        # acc shape doesn't match the operation we'd attempt; keep as-is
        acc
    end
  end

  defp compact_element(_other, _idx, _parent, _force_plural?, _ctx, acc), do: acc

  defp maybe_put_attrs(acc, _attrs, false, _plural?, _idx, _name, _ctx), do: acc

  defp maybe_put_attrs(acc, attrs, true, true, idx, _name, ctx)
       when is_nil(acc) or is_list(acc) do
    put_at_index(acc || [], idx, attrs_to_map(attrs, ctx))
  end

  defp maybe_put_attrs(acc, attrs, true, false, _idx, name, ctx)
       when is_nil(acc) or is_map(acc) do
    put_key(acc || %{}, name, attrs_to_map(attrs, ctx), ctx.keys)
  end

  defp maybe_put_attrs(acc, _attrs, true, _plural?, _idx, _name, _ctx), do: acc

  defp transform_name(raw_name, %{original: true, case: case_mode}),
    do: apply_case(raw_name, case_mode)

  defp transform_name(raw_name, %{original: false, case: case_mode}) do
    raw_name
    |> String.replace(~r/^.*:/, "")
    |> apply_case(case_mode)
  end

  defp apply_case(name, :as_is), do: name
  defp apply_case(name, :lower), do: String.downcase(name)

  defp attrs_to_map(attrs, %{keys: keys, case: case_mode} = ctx) do
    {ns_attrs, regular_attrs} =
      Enum.split_with(attrs, fn {k, _v} ->
        name = to_string(k)
        name == "xmlns" or String.starts_with?(name, "xmlns:")
      end)

    base =
      Map.new(regular_attrs, fn {k, v} ->
        name = apply_case(to_string(k), case_mode)
        {to_attr_key(name, keys), v}
      end)

    case ns_attrs do
      [] -> base
      _ -> Map.put(base, meta_key(ctx), build_meta(ns_attrs, ctx))
    end
  end

  defp build_meta(ns_attrs, %{keys: keys, case: case_mode}) do
    Map.new(ns_attrs, fn {k, v} ->
      prefix =
        case String.split(to_string(k), ":", parts: 2) do
          ["xmlns"] -> "xmlns"
          ["xmlns", prefix] -> prefix
        end

      {to_attr_key(apply_case(prefix, case_mode), keys), v}
    end)
  end

  defp meta_key(%{keys: keys, case: case_mode}) do
    name = apply_case("meta", case_mode)
    to_attr_key(name, keys)
  end

  defp to_attr_key(name, :atom), do: String.to_atom(name)
  defp to_attr_key(name, :string), do: name

  defp put_key(map, name, value, :atom), do: Map.put(map, String.to_atom(name), value)
  defp put_key(map, name, value, :string), do: Map.put(map, name, value)

  defp get_key(map, name, :atom), do: Map.get(map, String.to_atom(name))
  defp get_key(map, name, :string), do: Map.get(map, name)

  defp put_at_index(list, idx, value) do
    list
    |> pad_to_index(idx)
    |> List.replace_at(idx, value)
  end

  defp pad_to_index(list, idx) do
    needed = idx + 1 - length(list)
    if needed > 0, do: list ++ List.duplicate(%{}, needed), else: list
  end

  defp at_index_or_empty(list, idx) do
    case Enum.at(list, idx) do
      nil -> %{}
      val when is_map(val) -> val
      _ -> %{}
    end
  end
end
