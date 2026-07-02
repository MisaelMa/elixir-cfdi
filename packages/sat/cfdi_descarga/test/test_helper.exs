ExUnit.start()

# Los tests de integracion contra el SAT real (firman con FIEL y golpean los
# endpoints oficiales) estan excluidos por default. Se activan con:
#
#     mix test --include real_sat
ExUnit.configure(exclude: [:real_sat])
