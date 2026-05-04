defmodule Cfdi.Transform.XsltParser do
  @moduledoc """
  Parser de hojas XSLT del SAT (`cadenaoriginal.xslt` 4.0 / 3.3) basado en
  [`xslt-parser.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/cfdi/transform/src/xslt-parser.ts)
  del paquete `@cfdi/transform`.

  No implementa XSLT general — sólo el subconjunto que el SAT usa para
  generar la cadena original:

    * `xsl:include` con `href` relativo (sigue el grafo desde el archivo raíz).
    * `xsl:template match="..."` (descarta `name="Requerido|Opcional|ManejaEspacios"`).
    * `xsl:call-template name="Requerido|Opcional"` con `xsl:with-param select="@Attr"` o ruta.
    * `xsl:apply-templates select="..."`
    * `xsl:for-each select="..."` (incluye wildcard `./*` y descendant `.//foo`).
    * `xsl:if test="..."` envolviendo reglas hijas.

  Lectura recursiva de `xsl:include` con detección de ciclos via `MapSet`.
  """

  alias Cfdi.Transform.Types

  @named_templates ["Requerido", "Opcional", "ManejaEspacios"]

  @doc """
  Parsea un archivo XSLT desde disco, siguiendo `xsl:include`s relativos.

  Devuelve `{:ok, registry}` con `templates` y `namespaces`.
  """
  @spec parse_file(String.t()) :: {:ok, Types.template_registry()} | {:error, term()}
  def parse_file(main_xslt_path) when is_binary(main_xslt_path) do
    {template_elements, stylesheet_attrs} =
      collect_all_template_elements(main_xslt_path, MapSet.new(), [], nil)

    namespaces =
      case stylesheet_attrs do
        nil ->
          %{}

        attrs ->
          for {"xmlns:" <> prefix, uri} <- attrs,
              prefix not in ["xsl", "xs", "fn"] and
                not String.starts_with?(prefix, "xsl") and
                not String.starts_with?(prefix, "xs") and
                not String.starts_with?(prefix, "fn"),
              into: %{},
              do: {prefix, uri}
      end

    templates =
      Enum.reduce(template_elements, %{}, fn el, acc ->
        case template_match_attr(el) do
          nil -> acc
          "/" -> acc
          match -> Map.put(acc, match, parse_template(el, match))
        end
      end)

    {:ok, %{templates: templates, namespaces: namespaces}}
  rescue
    e -> {:error, e}
  end

  @doc """
  Variante que recibe el contenido del XSLT como string. No sigue
  `xsl:include` (no hay path base contra el cual resolverlo).
  """
  @spec parse(String.t()) :: {:ok, Types.template_registry()} | {:error, term()}
  def parse(xslt_content) when is_binary(xslt_content) do
    case Saxy.SimpleForm.parse_string(xslt_content) do
      {:ok, {_root_name, root_attrs, children}} ->
        namespaces =
          for {"xmlns:" <> prefix, uri} <- root_attrs,
              prefix not in ["xsl", "xs", "fn"],
              into: %{},
              do: {prefix, uri}

        templates =
          children
          |> Enum.filter(&match?({_, _, _}, &1))
          |> Enum.reduce(%{}, fn el, acc ->
            {tag, _, _} = el

            cond do
              local_name(tag) != "template" ->
                acc

              true ->
                case template_match_attr(el) do
                  nil -> acc
                  "/" -> acc
                  match -> Map.put(acc, match, parse_template(el, match))
                end
            end
          end)

        {:ok, %{templates: templates, namespaces: namespaces}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp template_match_attr({_tag, attrs, _children}) do
    name = attr(attrs, "name")
    match = attr(attrs, "match")

    cond do
      name in @named_templates -> nil
      is_nil(match) -> nil
      true -> match
    end
  end

  defp collect_all_template_elements(path, visited, acc, stylesheet_attrs) do
    resolved = Path.expand(path)

    if MapSet.member?(visited, resolved) do
      {acc, stylesheet_attrs}
    else
      visited = MapSet.put(visited, resolved)
      content = strip_bom(File.read!(resolved))
      {:ok, root} = Saxy.SimpleForm.parse_string(content)
      {tag, root_attrs, children} = root

      case local_name(tag) do
        n when n in ["stylesheet", "transform"] ->
          # Use the first stylesheet seen (the main file's) for namespace
          # collection — matches Node's `isMain` flag behavior.
          stylesheet_attrs = stylesheet_attrs || root_attrs

          Enum.reduce(children, {acc, visited, stylesheet_attrs}, fn child, {a, v, s} ->
            case child do
              {child_tag, child_attrs, _} = el ->
                case local_name(child_tag) do
                  "include" ->
                    href = attr(child_attrs, "href")

                    cond do
                      is_nil(href) ->
                        {a, v, s}

                      String.starts_with?(href, "http://") or
                          String.starts_with?(href, "https://") ->
                        # Remote includes ignored (matches Node behavior:
                        # `fs.readFileSync` would fail; the localized
                        # `cadenaoriginal.xslt` uses relative paths).
                        {a, v, s}

                      true ->
                        include_path = Path.expand(href, Path.dirname(resolved))
                        {a2, s2} = collect_all_template_elements(include_path, v, a, s)
                        # Already updated `v` inside via Path.expand; we don't
                        # have the new MapSet back, so we re-add and rely on
                        # the inner call's visited check.
                        {a2, MapSet.put(v, Path.expand(include_path)), s2}
                    end

                  "template" ->
                    name = attr(child_attrs, "name") || ""
                    match = attr(child_attrs, "match")

                    if match && name not in @named_templates do
                      {a ++ [el], v, s}
                    else
                      {a, v, s}
                    end

                  _ ->
                    {a, v, s}
                end

              _ ->
                {a, v, s}
            end
          end)
          |> then(fn {a, _v, s} -> {a, s} end)

        _ ->
          {acc, stylesheet_attrs}
      end
    end
  end

  @doc false
  def parse_template({_tag, _attrs, children}, match) do
    rules = extract_rules_from_elements(children, [])
    %{match: match, rules: rules}
  end

  defp extract_rules_from_elements(elements, acc) do
    Enum.reduce(elements, acc, fn
      {tag, attrs, children}, acc ->
        case local_name(tag) do
          "call-template" ->
            case parse_call_template(attrs, children) do
              nil -> acc
              rule -> acc ++ [rule]
            end

          "apply-templates" ->
            select = attr(attrs, "select")

            if select && select != "." do
              acc ++
                [
                  %{
                    type: :child,
                    select: normalize_select(select),
                    for_each: false,
                    inline: [],
                    apply_templates: true
                  }
                ]
            else
              acc
            end

          "for-each" ->
            case parse_for_each(attrs, children) do
              nil -> acc
              rule -> acc ++ [rule]
            end

          "if" ->
            test = attr(attrs, "test")

            if test do
              inner = extract_rules_from_elements(children, [])

              Enum.reduce(inner, acc, fn r, a ->
                r =
                  case r do
                    %{type: :child} = c -> Map.put(c, :condition, normalize_select(test))
                    other -> other
                  end

                a ++ [r]
              end)
            else
              acc
            end

          _ ->
            acc
        end

      _, acc ->
        acc
    end)
  end

  defp parse_call_template(attrs, children) do
    name = attr(attrs, "name")

    if name not in ["Requerido", "Opcional"] do
      nil
    else
      with_param =
        Enum.find(children, fn
          {tag, _, _} -> local_name(tag) == "with-param"
          _ -> false
        end)

      case with_param do
        nil ->
          nil

        {_, wattrs, _} ->
          select = attr(wattrs, "select")

          cond do
            is_nil(select) ->
              nil

            attr_name = extract_attr_name(select) ->
              %{type: :attr, name: attr_name, required: name == "Requerido"}

            true ->
              %{
                type: :text,
                select: normalize_select(select),
                required: name == "Requerido"
              }
          end
      end
    end
  end

  defp parse_for_each(attrs, children) do
    select = attr(attrs, "select")

    if is_nil(select) do
      nil
    else
      is_wildcard = select == "./*" or select == "*"
      is_descendant = String.starts_with?(select, ".//")
      normalized_select = normalize_select(select)

      inner = extract_rules_from_elements(children, [])

      has_apply_templates =
        Enum.any?(children, fn
          {tag, _, _} -> local_name(tag) == "apply-templates"
          _ -> false
        end)

      inline_attrs = Enum.filter(inner, &(&1.type in [:attr, :text]))
      inner_children = Enum.filter(inner, &(&1.type == :child))

      cond do
        is_wildcard ->
          %{
            type: :child,
            select: normalized_select,
            for_each: true,
            inline: [],
            apply_templates: true,
            wildcard: true
          }

        has_apply_templates and inline_attrs == [] and inner_children == [] ->
          %{
            type: :child,
            select: normalized_select,
            for_each: true,
            inline: [],
            apply_templates: true,
            descendant: is_descendant
          }

        inline_attrs != [] ->
          %{
            type: :child,
            select: normalized_select,
            for_each: true,
            inline: inline_attrs,
            apply_templates: inner_children != [],
            descendant: is_descendant
          }

        inner_children != [] ->
          %{
            type: :child,
            select: normalized_select,
            for_each: true,
            inline: [],
            apply_templates: true,
            descendant: is_descendant
          }

        true ->
          %{
            type: :child,
            select: normalized_select,
            for_each: true,
            inline: [],
            apply_templates: has_apply_templates,
            descendant: is_descendant
          }
      end
    end
  end

  defp extract_attr_name(select) do
    case Regex.run(~r/\.?\/?@(.+)$/, select) do
      [_, name] -> name
      _ -> nil
    end
  end

  defp normalize_select(select), do: String.replace(select, ~r/^\.\//, "")

  # Saxy rechaza el BOM UTF-8 (`﻿`) al inicio del documento; xml-js lo
  # tolera. Algunos XSLT del SAT (p. ej. `3.3/complementos/ecc11.xslt`) traen
  # BOM, así que lo descartamos antes de parsear.
  defp strip_bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp strip_bom(content), do: content

  defp attr(attrs, name) do
    case List.keyfind(attrs, name, 0) do
      {_, v} -> v
      nil -> nil
    end
  end

  defp local_name(tag) do
    tag = to_string(tag)

    case String.split(tag, ":", parts: 2) do
      [_p, l] -> l
      [l] -> l
    end
  end
end
