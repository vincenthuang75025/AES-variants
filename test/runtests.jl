using SafeTestsets

# @safetestset "Old AES Tests" begin include("aes-old.jl") end
@safetestset "AES CPU Tests" begin include("aes-cpu.jl") end
