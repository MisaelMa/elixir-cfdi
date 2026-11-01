ExUnit.start()

# Los tests de integracion contra el portal real del SAT (firman con FIEL y
# golpean el portal) estan excluidos por default. Se activan con:
#
#     source .env   # ver packages/sat/cfdi_descarga/env.example
#     mix test --include real_sat
ExUnit.configure(exclude: [:real_sat])
