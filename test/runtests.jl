using SafeTestsets

@time begin
	@time @safetestset "Interface Tests" begin include("AES-old/interface.jl") end
	@time @safetestset "Block Encryption/Decryption tests" begin include("AES-old/blocktest.jl") end
	@time @safetestset "CBC Mode tests" begin include("AES-old/cbc.jl") end
	@time @safetestset "CTR Mode tests" begin include("AES-old/ctr.jl") end
	@time @safetestset "ECB Mode tests" begin include("AES-old/ecb.jl") end
end
