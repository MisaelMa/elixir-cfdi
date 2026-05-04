defmodule Cfdi.Transform.CadenaEngine do
  @moduledoc """
  Motor de generación de cadena original. Espejo de
  [`cadena-engine.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/transform/src/cadena-engine.ts).

  Recibe el XML del CFDI y un `template_registry` parseado por
  `Cfdi.Transform.XsltParser`, y produce la cadena `|...|...||`.
  """

  alias Cfdi.Transform.Types

  @doc """
  Colapsa whitespace (`\\s+` → ` `) y hace `trim`. Equivale a `normalize-space()`
  de XSLT, que es lo que usan las plantillas `Requerido` y `Opcional`.
  """
  @spec normalize_space(String.t() | nil) :: String.t()
  def normalize_space(nil), do: ""

  def normalize_space(s) when is_binary(s) do
    s
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
  end

  @doc "Equivalente a `Requerido(valor)`: prefija `|` + `normalize-space`."
  @spec requerido(String.t() | nil) :: String.t()
  def requerido(value), do: "|" <> normalize_space(value || "")

  @doc "Equivalente a `Opcional(valor)`: vacío si nil, sino `|` + `normalize-space`."
  @spec opcional(String.t() | nil) :: String.t()
  def opcional(nil), do: ""
  def opcional(value), do: "|" <> normalize_space(value)

  @doc """
  Genera la cadena original a partir del contenido XML y un registro de
  plantillas. Devuelve `{:ok, cadena}` o un `{:error, _}`.
  """
  @spec generate_cadena_original(String.t(), Types.template_registry()) ::
          {:ok, String.t()} | {:error, term()}
  def generate_cadena_original(xml_content, registry) when is_binary(xml_content) do
    case Saxy.SimpleForm.parse_string(strip_bom(xml_content)) do
      {:ok, root} ->
        cadena =
          case find_root_element([root], registry) do
            nil ->
              "||||"

            root_match ->
              if namespaces_match?(root_match, registry) do
                "|" <> IO.iodata_to_binary(process_node(root_match, registry)) <> "||"
              else
                "|||"
              end
          end

        {:ok, cadena}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_root_element(elements, registry) do
    Enum.find_value(elements, fn
      {tag, _attrs, children} = el ->
        if Map.has_key?(registry.templates, to_string(tag)) do
          el
        else
          find_root_element(child_elements(children), registry)
        end

      _ ->
        nil
    end)
  end

  defp child_elements(children) do
    Enum.filter(children, &match?({_, _, _}, &1))
  end

  defp namespaces_match?({_tag, attrs, _children}, registry) do
    if map_size(registry.namespaces) == 0 do
      true
    else
      Enum.all?(registry.namespaces, fn {prefix, xslt_uri} ->
        case attr(attrs, "xmlns:" <> prefix) do
          nil -> true
          xml_uri -> xml_uri == xslt_uri
        end
      end)
    end
  end

  @doc """
  Procesa un nodo aplicando la plantilla correspondiente a su nombre completo
  (con prefijo). Devuelve iodata.
  """
  @spec process_node(term(), Types.template_registry()) :: iodata()
  def process_node({tag, _attrs, _children} = node, registry) do
    case Map.get(registry.templates, to_string(tag)) do
      nil ->
        []

      %{rules: rules} ->
        Enum.map(rules, fn rule -> apply_rule(node, rule, registry) end)
    end
  end

  def process_node(_, _), do: []

  defp apply_rule(node, %{type: :attr} = rule, _registry) do
    {_t, attrs, _} = node
    value = attr(attrs, rule.name)
    if rule.required, do: requerido(value), else: opcional(value)
  end

  defp apply_rule(node, %{type: :text} = rule, _registry) do
    value =
      cond do
        rule.select == "." ->
          text_content(node)

        true ->
          case resolve_select(node, rule.select) do
            [] -> nil
            [first | _] -> text_content(first)
          end
      end

    if rule.required, do: requerido(value), else: opcional(value)
  end

  defp apply_rule(node, %{type: :child} = rule, registry) do
    if condition_skips?(node, rule) do
      []
    else
      cond do
        Map.get(rule, :wildcard, false) ->
          process_wildcard(node, registry)

        true ->
          elements =
            if Map.get(rule, :descendant, false) do
              resolve_descendant(node, last_segment(rule.select))
            else
              resolve_select(node, rule.select)
            end

          process_child_elements(elements, rule, registry)
      end
    end
  end

  defp condition_skips?(node, %{condition: cond_select}) when is_binary(cond_select) do
    resolve_select(node, cond_select) == []
  end

  defp condition_skips?(_node, _rule), do: false

  defp process_child_elements(elements, rule, registry) do
    cond do
      rule.for_each or elements != [] ->
        Enum.map(elements, fn el ->
          inline_part =
            Enum.map(rule.inline, fn inline_rule ->
              apply_rule(el, inline_rule, registry)
            end)

          tail =
            if rule.apply_templates do
              process_node(el, registry)
            else
              []
            end

          [inline_part, tail]
        end)

      true ->
        []
    end
  end

  defp process_wildcard({_t, _a, children}, registry) do
    children
    |> child_elements()
    |> Enum.map(&process_node(&1, registry))
  end

  @doc """
  Resuelve un `select` con segmentos `prefix:Element` separados por `/`.
  Devuelve la lista de nodos coincidentes (paridad con `resolveSelect` de Node).
  """
  @spec resolve_select(term(), String.t()) :: [term()]
  def resolve_select({_t, _a, children} = _node, select) do
    clean = String.replace(select, ~r/^\.\//, "")
    segments = String.split(clean, "/", trim: true)
    walk_segments([{nil, [], child_elements(children)}], segments)
  end

  defp walk_segments(current, []) do
    current
    |> Enum.flat_map(fn {tag, attrs, children} -> [{tag, attrs, children}] end)
    |> Enum.reject(&is_nil/1)
  end

  defp walk_segments(current, [segment | rest]) do
    next =
      Enum.flat_map(current, fn
        nil ->
          []

        {_tag, _attrs, children} ->
          children
          |> child_elements()
          |> Enum.filter(fn {child_tag, _, _} -> to_string(child_tag) == segment end)
      end)

    walk_segments(next, rest)
  end

  defp resolve_descendant(node, name) do
    results = []
    collect_descendants(node, name, results)
  end

  defp collect_descendants({_t, _a, children}, name, acc) do
    Enum.reduce(child_elements(children), acc, fn {child_tag, _, _} = child, a ->
      a =
        if to_string(child_tag) == name do
          a ++ [child]
        else
          a
        end

      collect_descendants(child, name, a)
    end)
  end

  defp last_segment(path) do
    path
    |> String.split("/")
    |> List.last()
  end

  defp text_content({_t, _a, children}) do
    parts =
      Enum.flat_map(children, fn
        s when is_binary(s) -> [s]
        _ -> []
      end)

    case parts do
      [] -> nil
      _ -> Enum.join(parts, "")
    end
  end

  defp text_content(_), do: nil

  defp attr(attrs, name) do
    case List.keyfind(attrs, name, 0) do
      {_, v} -> v
      nil -> nil
    end
  end

  # Saxy rechaza el BOM UTF-8 al inicio del documento.
  defp strip_bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp strip_bom(content), do: content
end
