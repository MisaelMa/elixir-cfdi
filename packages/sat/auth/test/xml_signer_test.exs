defmodule Sat.Auth.XmlSignerTest do
  use ExUnit.Case, async: true

  alias Sat.Auth.XmlSigner

  test "sha256_digest matches known vector" do
    assert XmlSigner.sha256_digest("test") == Base.encode64(:crypto.hash(:sha256, "test"))
  end
end
