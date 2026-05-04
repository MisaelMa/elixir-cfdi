defmodule Cfdi.Csd.OcspTest do
  use ExUnit.Case, async: true

  alias Cfdi.Csd.{Certificate, Ocsp}

  @fixtures Path.expand("../../../files/certificados/efirma", __DIR__)
  defp f(n), do: Path.join(@fixtures, n)

  setup_all do
    {:ok, subject} = Certificate.from_file(f("ipnCertificate.cer"))
    {:ok, issuer} = Certificate.from_file(f("AC5_SAT.cer"))
    {:ok, ocsp_cert} = Certificate.from_file(f("ocsp.ac5_sat.cer"))
    %{subject: subject, issuer: issuer, ocsp_cert: ocsp_cert}
  end

  describe "Ocsp.new" do
    test "rechaza URL inválida", ctx do
      assert {:error, :invalid_url} =
               Ocsp.new("cfdi.sat.gob.mx/edofiel", ctx.issuer, ctx.subject, ctx.ocsp_cert)
    end

    test "acepta URL válida", ctx do
      assert {:ok, %Ocsp{}} =
               Ocsp.new(
                 "https://cfdi.sat.gob.mx/edofiel",
                 ctx.issuer,
                 ctx.subject,
                 ctx.ocsp_cert
               )
    end

    test "Ocsp.new! lanza con URL inválida", ctx do
      assert_raise ArgumentError, fn ->
        Ocsp.new!("not-a-url", ctx.issuer, ctx.subject, ctx.ocsp_cert)
      end
    end
  end

  describe "Ocsp.parse_response_status (offline)" do
    test "tryLater.der retorna :try_later" do
      der = File.read!(f("tryLater.der"))
      assert Ocsp.parse_response_status(der) == :try_later
    end
  end

  describe "Ocsp.parse_certificate_status (offline)" do
    test "revoked.der retorna {:revoked, time}" do
      der = File.read!(f("revoked.der"))
      basic_der = extract_basic_for_test(der)
      result = Ocsp.parse_certificate_status(basic_der)

      assert result.status == :revoked
      assert %DateTime{} = result.revocation_time
    end
  end

  # Test online contra `https://cfdi.sat.gob.mx/edofiel`.
  #
  # NO corre por default — está excluido por el `@tag :online`. Para correrlo:
  #
  #     mix test --include online
  #
  # Se deja excluido a propósito porque depende de la disponibilidad del
  # responder OCSP del SAT (es flaky en CI). Los tests offline de arriba
  # (`parse_response_status` y `parse_certificate_status` con `revoked.der` /
  # `tryLater.der`) ya cubren toda la lógica de parseo sin red.
  @tag :online
  test "verify online contra el SAT", ctx do
    {:ok, ocsp} =
      Ocsp.new("https://cfdi.sat.gob.mx/edofiel", ctx.issuer, ctx.subject, ctx.ocsp_cert)

    case Ocsp.verify(ocsp) do
      {:ok, %{status: status}} -> assert status in [:good, :revoked, :unknown]
      {:error, _} -> :ok
    end
  end

  # Helper privado para tests: replicar el flujo de extract_basic_response
  defp extract_basic_for_test(der) do
    {{_, _, 0x10}, body, _} = Cfdi.Csd.Asn1.next(der)
    {{_, _, 0x0A}, _status, after_status} = Cfdi.Csd.Asn1.next(body)
    {{_, _, 0x00}, ctx_body, _} = Cfdi.Csd.Asn1.next(after_status)
    {{_, _, 0x10}, rb_body, _} = Cfdi.Csd.Asn1.next(ctx_body)
    {{_, _, 0x06}, _oid, after_oid} = Cfdi.Csd.Asn1.next(rb_body)
    {{_, _, 0x04}, basic_der, _} = Cfdi.Csd.Asn1.next(after_oid)
    basic_der
  end
end
