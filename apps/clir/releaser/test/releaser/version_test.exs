defmodule Releaser.VersionTest do
  use ExUnit.Case, async: true

  alias Releaser.Version

  describe "parse/1" do
    test "parses clean version" do
      v = Version.parse("4.0.17")
      assert v.major == 4
      assert v.minor == 0
      assert v.patch == 17
      assert v.pre_tag == nil
      assert v.pre_num == 0
      assert v.build == nil
    end

    test "parses version with pre-release tag" do
      v = Version.parse("4.0.18-dev.3")
      assert v.major == 4
      assert v.minor == 0
      assert v.patch == 18
      assert v.pre_tag == "dev"
      assert v.pre_num == 3
    end

    test "parses version with build metadata" do
      v = Version.parse("1.2.3+20260420")
      assert v.major == 1
      assert v.minor == 2
      assert v.patch == 3
      assert v.build == "20260420"
    end

    test "parses version with tag and build" do
      v = Version.parse("4.0.18-dev.3+build.1")
      assert v.pre_tag == "dev"
      assert v.pre_num == 3
      assert v.build == "build.1"
    end

    test "parses various tags" do
      assert Version.parse("1.0.0-alpha.1").pre_tag == "alpha"
      assert Version.parse("1.0.0-beta.5").pre_tag == "beta"
      assert Version.parse("1.0.0-rc.2").pre_tag == "rc"
    end

    test "raises on invalid version" do
      assert_raise ArgumentError, fn -> Version.parse("not.a.version") end
    end
  end

  describe "to_string/1" do
    test "clean version" do
      assert to_string(Version.parse("4.0.17")) == "4.0.17"
    end

    test "version with tag" do
      assert to_string(Version.parse("4.0.18-dev.3")) == "4.0.18-dev.3"
    end

    test "version with build" do
      assert to_string(Version.parse("1.2.3+build")) == "1.2.3+build"
    end

    test "version with tag and build" do
      assert to_string(Version.parse("1.0.0-rc.1+20260420")) == "1.0.0-rc.1+20260420"
    end
  end

  describe "bump/3 — clean version + tag" do
    test "patch + dev from clean" do
      assert Version.bump("4.0.17", :patch, tag: "dev") == "4.0.18-dev.1"
    end

    test "minor + dev from clean" do
      assert Version.bump("4.0.17", :minor, tag: "dev") == "4.1.0-dev.1"
    end

    test "major + beta from clean" do
      assert Version.bump("1.2.3", :major, tag: "beta") == "2.0.0-beta.1"
    end
  end

  describe "bump/3 — same tag increments" do
    test "dev.1 + dev = dev.2" do
      assert Version.bump("4.0.18-dev.1", :patch, tag: "dev") == "4.0.18-dev.2"
    end

    test "dev.5 + dev = dev.6" do
      assert Version.bump("4.0.18-dev.5", :patch, tag: "dev") == "4.0.18-dev.6"
    end

    test "beta.1 + beta = beta.2" do
      assert Version.bump("4.0.18-beta.1", :patch, tag: "beta") == "4.0.18-beta.2"
    end
  end

  describe "bump/3 — tag change keeps base" do
    test "dev → beta" do
      assert Version.bump("4.0.18-dev.3", :patch, tag: "beta") == "4.0.18-beta.1"
    end

    test "dev → rc" do
      assert Version.bump("4.0.18-dev.1", :patch, tag: "rc") == "4.0.18-rc.1"
    end

    test "beta → rc" do
      assert Version.bump("4.0.18-beta.5", :patch, tag: "rc") == "4.0.18-rc.1"
    end

    test "rc → beta (downgrade)" do
      assert Version.bump("2.0.0-rc.1", :patch, tag: "beta") == "2.0.0-beta.1"
    end
  end

  describe "bump/3 — without tag" do
    test "patch" do
      assert Version.bump("4.0.17", :patch, []) == "4.0.18"
    end

    test "minor" do
      assert Version.bump("4.0.17", :minor, []) == "4.1.0"
    end

    test "major" do
      assert Version.bump("4.0.17", :major, []) == "5.0.0"
    end
  end

  describe "bump/3 — build metadata" do
    test "adds build metadata" do
      assert Version.bump("4.0.17", :patch, build: "20260420") == "4.0.18+20260420"
    end

    test "tag + build" do
      assert Version.bump("4.0.17", :patch, tag: "dev", build: "abc") == "4.0.18-dev.1+abc"
    end
  end

  describe "release/1" do
    test "strips pre-release tag" do
      v = Version.parse("4.0.18-beta.2") |> Version.release()
      assert to_string(v) == "4.0.18"
    end

    test "noop on clean version" do
      v = Version.parse("4.0.18") |> Version.release()
      assert to_string(v) == "4.0.18"
    end

    test "strips build metadata too" do
      v = Version.parse("4.0.18-dev.1+build") |> Version.release()
      assert to_string(v) == "4.0.18"
    end
  end

  describe "set/1" do
    test "sets explicit version" do
      v = Version.set("2.0.0")
      assert to_string(v) == "2.0.0"
    end

    test "sets explicit version with tag" do
      v = Version.set("3.0.0-rc.1")
      assert to_string(v) == "3.0.0-rc.1"
    end
  end

  describe "helper functions" do
    test "base_string" do
      assert Version.base_string(Version.parse("4.0.18-dev.3+build")) == "4.0.18"
    end

    test "major_minor" do
      assert Version.major_minor(Version.parse("4.0.18")) == "4.0"
    end

    test "prerelease?" do
      assert Version.prerelease?(Version.parse("4.0.18-dev.1")) == true
      assert Version.prerelease?(Version.parse("4.0.18")) == false
    end
  end

  describe "full lifecycle" do
    test "complete dev → beta → rc → release cycle" do
      v0 = "4.0.17"
      v1 = Version.bump(v0, :patch, tag: "dev")
      assert v1 == "4.0.18-dev.1"

      v2 = Version.bump(v1, :patch, tag: "dev")
      assert v2 == "4.0.18-dev.2"

      v3 = Version.bump(v2, :patch, tag: "dev")
      assert v3 == "4.0.18-dev.3"

      v4 = Version.bump(v3, :patch, tag: "beta")
      assert v4 == "4.0.18-beta.1"

      v5 = Version.bump(v4, :patch, tag: "beta")
      assert v5 == "4.0.18-beta.2"

      v6 = Version.bump(v5, :patch, tag: "rc")
      assert v6 == "4.0.18-rc.1"

      v7 = v6 |> Version.parse() |> Version.release() |> to_string()
      assert v7 == "4.0.18"
    end

    test "semver ordering" do
      assert Elixir.Version.compare("4.0.18-alpha.1", "4.0.18-beta.1") == :lt
      assert Elixir.Version.compare("4.0.18-beta.1", "4.0.18-dev.1") == :lt
      assert Elixir.Version.compare("4.0.18-dev.1", "4.0.18-rc.1") == :lt
      assert Elixir.Version.compare("4.0.18-rc.1", "4.0.18") == :lt
    end
  end
end
