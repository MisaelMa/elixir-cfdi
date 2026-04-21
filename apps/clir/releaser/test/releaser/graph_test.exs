defmodule Releaser.GraphTest do
  use ExUnit.Case, async: true

  alias Releaser.{Graph, App}

  @apps [
    %App{name: "openssl", path: "apps/clir/openssl", version: "0.0.17", deps: []},
    %App{name: "transform", path: "apps/cfdi/transform", version: "4.0.14", deps: []},
    %App{name: "catalogos", path: "apps/cfdi/catalogos", version: "4.0.16", deps: []},
    %App{name: "csd", path: "apps/cfdi/csd", version: "4.0.16", deps: ["openssl"]},
    %App{name: "xml", path: "apps/cfdi/xml", version: "4.0.18", deps: ["csd", "transform", "catalogos"]},
    %App{name: "auth", path: "apps/sat/auth", version: "1.0.1", deps: ["csd"]},
    %App{name: "cancelacion", path: "apps/cfdi/cancelacion", version: "0.0.1", deps: ["auth"]}
  ]

  describe "build/1" do
    test "builds graph from apps" do
      graph = Graph.build(@apps)
      assert graph["openssl"] == []
      assert graph["csd"] == ["openssl"]
      assert "csd" in graph["xml"]
      assert "transform" in graph["xml"]
    end
  end

  describe "dependents_of/1" do
    test "returns reverse dependency map" do
      dep_map = Graph.dependents_of(@apps)
      assert "csd" in dep_map["openssl"]
      assert "xml" in dep_map["csd"]
      assert "auth" in dep_map["csd"]
      assert "cancelacion" in dep_map["auth"]
    end
  end

  describe "topological_levels/1" do
    test "produces correct levels" do
      levels = Graph.topological_levels(@apps)

      assert [{0, level0}, {1, level1}, {2, level2}, {3, level3}] = levels

      assert "openssl" in level0
      assert "transform" in level0
      assert "catalogos" in level0

      assert level1 == ["csd"]

      assert "xml" in level2
      assert "auth" in level2

      assert level3 == ["cancelacion"]
    end

    test "level 0 has no internal deps" do
      [{0, level0} | _] = Graph.topological_levels(@apps)
      graph = Graph.build(@apps)

      Enum.each(level0, fn name ->
        assert Map.get(graph, name, []) == []
      end)
    end
  end

  describe "transitive_deps/2" do
    test "resolves full transitive closure" do
      graph = Graph.build(@apps)
      deps = Graph.transitive_deps(["xml"], graph)

      assert MapSet.member?(deps, "xml")
      assert MapSet.member?(deps, "csd")
      assert MapSet.member?(deps, "openssl")
      assert MapSet.member?(deps, "transform")
      assert MapSet.member?(deps, "catalogos")
      refute MapSet.member?(deps, "auth")
    end

    test "single app with no deps" do
      graph = Graph.build(@apps)
      deps = Graph.transitive_deps(["openssl"], graph)
      assert deps == MapSet.new(["openssl"])
    end
  end

  describe "transitive_dependents/2" do
    test "resolves all dependents recursively (upstream)" do
      deps = Graph.transitive_dependents(["csd"], @apps)

      # csd itself
      assert MapSet.member?(deps, "csd")
      # xml depends on csd
      assert MapSet.member?(deps, "xml")
      # auth depends on csd
      assert MapSet.member?(deps, "auth")
      # cancelacion depends on auth (transitive)
      assert MapSet.member?(deps, "cancelacion")
      # openssl does NOT depend on csd (csd depends on openssl, not the other way)
      refute MapSet.member?(deps, "openssl")
      # transform does NOT depend on csd
      refute MapSet.member?(deps, "transform")
    end

    test "app with no dependents returns only itself" do
      deps = Graph.transitive_dependents(["cancelacion"], @apps)
      assert deps == MapSet.new(["cancelacion"])
    end

    test "leaf app with no dependents" do
      deps = Graph.transitive_dependents(["xml"], @apps)
      # xml has no dependents in our test data
      assert deps == MapSet.new(["xml"])
    end

    test "multiple starting apps" do
      deps = Graph.transitive_dependents(["openssl", "catalogos"], @apps)

      # openssl dependents: csd, xml, auth, cancelacion
      assert MapSet.member?(deps, "csd")
      assert MapSet.member?(deps, "xml")
      # catalogos dependents: xml
      assert MapSet.member?(deps, "xml")
      # the starting apps themselves
      assert MapSet.member?(deps, "openssl")
      assert MapSet.member?(deps, "catalogos")
    end
  end

  describe "filter_levels/2" do
    test "filters to only required apps" do
      levels = Graph.topological_levels(@apps)
      required = MapSet.new(["openssl", "csd"])
      filtered = Graph.filter_levels(levels, required)

      assert [{0, ["openssl"]}, {1, ["csd"]}] = filtered
    end
  end
end
