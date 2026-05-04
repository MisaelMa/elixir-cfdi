defmodule SaxonHe.BlahTest do
  @moduledoc """
  Port de [`test/blah.test.ts`](https://github.com/MisaelMa/node-cfdi/blob/main/packages/clir/saxon-he/test/blah.test.ts).
  Smoke test trivial para validar que la suite carga.
  """

  use ExUnit.Case, async: true

  describe "blah" do
    test "works", do: assert(2 == 2)
  end
end
