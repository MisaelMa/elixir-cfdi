defmodule Mix.Tasks.BumpTest do
  use ExUnit.Case, async: true

  alias Mix.Tasks.Bump

  describe "parse_version/1" do
    test "parses clean version" do
      assert Bump.parse_version("4.0.17") == {"4.0.17", nil, 0}
    end

    test "parses version with tag" do
      assert Bump.parse_version("4.0.18-dev.1") == {"4.0.18", "dev", 1}
    end

    test "parses version with high tag number" do
      assert Bump.parse_version("4.0.18-dev.15") == {"4.0.18", "dev", 15}
    end

    test "parses beta tag" do
      assert Bump.parse_version("1.2.3-beta.3") == {"1.2.3", "beta", 3}
    end

    test "parses rc tag" do
      assert Bump.parse_version("0.0.1-rc.1") == {"0.0.1", "rc", 1}
    end

    test "parses alpha tag" do
      assert Bump.parse_version("12.5.2-alpha.7") == {"12.5.2", "alpha", 7}
    end
  end

  describe "bump_base/2" do
    test "patch bump" do
      assert Bump.bump_base("4.0.17", :patch) == "4.0.18"
    end

    test "minor bump" do
      assert Bump.bump_base("4.0.17", :minor) == "4.1.0"
    end

    test "major bump" do
      assert Bump.bump_base("4.0.17", :major) == "5.0.0"
    end

    test "patch bump resets only patch" do
      assert Bump.bump_base("1.2.3", :patch) == "1.2.4"
    end

    test "minor bump resets patch" do
      assert Bump.bump_base("1.2.3", :minor) == "1.3.0"
    end

    test "major bump resets minor and patch" do
      assert Bump.bump_base("1.2.3", :major) == "2.0.0"
    end
  end

  describe "compute_new_version/3 — clean version + tag" do
    test "patch + dev tag from clean version" do
      assert Bump.compute_new_version("4.0.17", :patch, "dev") == "4.0.18-dev.1"
    end

    test "minor + dev tag from clean version" do
      assert Bump.compute_new_version("4.0.17", :minor, "dev") == "4.1.0-dev.1"
    end

    test "major + beta tag from clean version" do
      assert Bump.compute_new_version("1.2.3", :major, "beta") == "2.0.0-beta.1"
    end

    test "patch + rc tag from clean version" do
      assert Bump.compute_new_version("0.0.1", :patch, "rc") == "0.0.2-rc.1"
    end
  end

  describe "compute_new_version/3 — same tag increments" do
    test "dev.1 + dev = dev.2" do
      assert Bump.compute_new_version("4.0.18-dev.1", :patch, "dev") == "4.0.18-dev.2"
    end

    test "dev.5 + dev = dev.6" do
      assert Bump.compute_new_version("4.0.18-dev.5", :patch, "dev") == "4.0.18-dev.6"
    end

    test "beta.1 + beta = beta.2" do
      assert Bump.compute_new_version("4.0.18-beta.1", :patch, "beta") == "4.0.18-beta.2"
    end

    test "rc.3 + rc = rc.4" do
      assert Bump.compute_new_version("1.0.0-rc.3", :patch, "rc") == "1.0.0-rc.4"
    end
  end

  describe "compute_new_version/3 — tag change (keeps base)" do
    test "dev → beta keeps base version" do
      assert Bump.compute_new_version("4.0.18-dev.3", :patch, "beta") == "4.0.18-beta.1"
    end

    test "dev → rc keeps base version" do
      assert Bump.compute_new_version("4.0.18-dev.1", :patch, "rc") == "4.0.18-rc.1"
    end

    test "beta → rc keeps base version" do
      assert Bump.compute_new_version("4.0.18-beta.5", :patch, "rc") == "4.0.18-rc.1"
    end

    test "alpha → dev keeps base version" do
      assert Bump.compute_new_version("1.0.0-alpha.2", :patch, "dev") == "1.0.0-dev.1"
    end

    test "rc → beta keeps base version (downgrade tag)" do
      assert Bump.compute_new_version("2.0.0-rc.1", :patch, "beta") == "2.0.0-beta.1"
    end
  end

  describe "compute_new_version/3 — clean version without tag" do
    test "patch without tag" do
      assert Bump.compute_new_version("4.0.17", :patch, nil) == "4.0.18"
    end

    test "minor without tag" do
      assert Bump.compute_new_version("4.0.17", :minor, nil) == "4.1.0"
    end

    test "major without tag" do
      assert Bump.compute_new_version("4.0.17", :major, nil) == "5.0.0"
    end
  end

  describe "full lifecycle" do
    test "complete dev → beta → release cycle" do
      # Start from stable
      v0 = "4.0.17"

      # First dev bump
      v1 = Bump.compute_new_version(v0, :patch, "dev")
      assert v1 == "4.0.18-dev.1"

      # Iterate in dev
      v2 = Bump.compute_new_version(v1, :patch, "dev")
      assert v2 == "4.0.18-dev.2"

      v3 = Bump.compute_new_version(v2, :patch, "dev")
      assert v3 == "4.0.18-dev.3"

      # Promote to beta (same base!)
      v4 = Bump.compute_new_version(v3, :patch, "beta")
      assert v4 == "4.0.18-beta.1"

      # Fix in beta
      v5 = Bump.compute_new_version(v4, :patch, "beta")
      assert v5 == "4.0.18-beta.2"

      # Release candidate
      v6 = Bump.compute_new_version(v5, :patch, "rc")
      assert v6 == "4.0.18-rc.1"

      # Final release
      {base, _tag, _n} = Bump.parse_version(v6)
      assert base == "4.0.18"
    end

    test "semver ordering is correct for pre-release" do
      # Verify that Elixir's Version module agrees with our ordering
      assert Version.compare("4.0.18-alpha.1", "4.0.18-beta.1") == :lt
      assert Version.compare("4.0.18-beta.1", "4.0.18-dev.1") == :lt
      assert Version.compare("4.0.18-dev.1", "4.0.18-rc.1") == :lt
      assert Version.compare("4.0.18-rc.1", "4.0.18") == :lt
    end
  end
end
