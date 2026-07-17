defmodule Cfdi.Complementos.RegistryTest do
  use ExUnit.Case, async: true

  alias Cfdi.Complementos.{Iedu, Nomina12, Pago20, Registry, Tfd}
  alias Cfdi.Complementos.{CartaPorte20, CartaPorte31}

  describe "all/0" do
    test "descubre todos los complementos del paquete" do
      mods = Registry.all()

      assert Pago20 in mods
      assert Tfd in mods
      assert Iedu in mods
      assert Nomina12 in mods
      # 32 complementos concretos; el módulo base no cuenta.
      assert length(mods) == 32
      refute Cfdi.Complementos.Complemento in mods
    end

    test "no hay keys ni xmlns duplicados" do
      mods = Registry.all()

      keys = Enum.map(mods, & &1.key())
      xmlnses = Enum.map(mods, & &1.xmlns())

      assert length(Enum.uniq(keys)) == length(keys)
      assert length(Enum.uniq(xmlnses)) == length(xmlnses)
    end
  end

  describe "by_xmlns/1" do
    test "resuelve por la URI del namespace" do
      assert Registry.by_xmlns("http://www.sat.gob.mx/Pagos20") == Pago20
      assert Registry.by_xmlns("http://www.sat.gob.mx/iedu") == Iedu
      assert Registry.by_xmlns("http://www.sat.gob.mx/TimbreFiscalDigital") == Tfd
    end

    test "distingue CartaPorte 2.0 de 3.1 pese a compartir nombre local" do
      cp20 = Registry.by_xmlns(CartaPorte20.xmlns())
      cp31 = Registry.by_xmlns(CartaPorte31.xmlns())

      assert cp20 == CartaPorte20
      assert cp31 == CartaPorte31
      refute CartaPorte20.xmlns() == CartaPorte31.xmlns()
    end

    test "devuelve nil para namespace desconocido" do
      assert Registry.by_xmlns("http://ejemplo.com/no-existe") == nil
    end
  end

  describe "by_key/1" do
    test "resuelve por la key canónica con prefijo" do
      assert Registry.by_key("pago20:Pagos") == Pago20
      assert Registry.by_key("tfd:TimbreFiscalDigital") == Tfd
    end

    test "devuelve nil para key desconocida" do
      assert Registry.by_key("chafa:NoExiste") == nil
    end
  end
end
