defmodule Sat.Certificados do
  @moduledoc """
  Lectura y operación de certificados X.509 (`.cer`) y llaves privadas RSA
  (`.key`) del SAT mexicano. Cubre **CSD** (Certificado de Sello Digital) y
  **FIEL** (también conocida como e.firma).

  ## Módulos

  | Módulo | Responsabilidad |
  |---|---|
  | `Sat.Certificados.Certificate` | Wrapper del `.cer` X.509 (CSD o FIEL) |
  | `Sat.Certificados.PrivateKey`  | Wrapper del `.key` RSA (PKCS#8 cifrado, PKCS#8 plano o PKCS#1) |
  | `Sat.Certificados.Credential`  | Une `Certificate` + `PrivateKey` para firmar/verificar |
  | `Sat.Certificados.Ocsp`        | Validación de revocación contra el responder OCSP del SAT |

  ## Compatibilidad con `e.firma` (npm)

  Equivalencias con el paquete [`e.firma`](https://www.npmjs.com/package/e.firma):

  | `e.firma` (Node) | `Sat.Certificados` (Elixir) |
  |---|---|
  | `new x509Certificate(bin)` | `Certificate.from_file/1` o `Certificate.from_der/1` |
  | `cert.certificateType` (`'CSD' \\| 'EFIRMA'`) | `Certificate.certificate_type/1` (`:csd \\| :fiel`) |
  | `cert.acVersion` | `Certificate.ac_version/1` |
  | `cert.subjectType` | `Certificate.subject_type/1` (`:moral \\| :fisica`) |
  | `cert.valid` | `Certificate.valid?/1` |
  | `cert.serialNumber` | `Certificate.serial_number/1` |
  | `cert.getPEM()` | `Certificate.to_pem/1` |
  | `cert.getBinary()` | `Certificate.to_der/1` |
  | `cert.verifyIntegrity(issuer)` | `Certificate.issued_by?/2` (alias `verify_integrity/2`) |
  | `cert.rsaEncrypt(msg)` | `Certificate.rsa_encrypt/2` |
  | `cert.rsaVerifySignature(msg, sig)` | `Certificate.verify/4` |
  | `new PrivateKey(bin)` (cifrada solamente) | `PrivateKey.from_file(path, pwd, strict: true)` |
  | `key.rsaDecrypt(text, pwd)` | `PrivateKey.rsa_decrypt/2` (la pwd va en el `from_*`) |
  | `key.rsaSign(msg, pwd)` | `PrivateKey.sign/3` |
  | `new Ocsp(url, issuer, subject, ocsp)` | `Ocsp.new/4` |

  ## Ejemplo

      {:ok, cred} = Sat.Certificados.Credential.create("mi.cer", "mi.key", "12345678a")

      Sat.Certificados.Credential.rfc(cred)              # "LAN7008173R5"
      Sat.Certificados.Credential.is_csd?(cred)          # true
      Sat.Certificados.Certificate.ac_version(cred.certificate)   # 5
      Sat.Certificados.Certificate.subject_type(cred.certificate) # :fisica | :moral

      sello = Sat.Certificados.Credential.sign(cred, "||cadena|original||")
      true = Sat.Certificados.Credential.verify(cred, "||cadena|original||", sello)
  """

  @doc false
  def version, do: Application.spec(:sat_certificados, :vsn)
end
