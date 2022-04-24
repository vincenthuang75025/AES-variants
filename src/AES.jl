module AES

# include("AES-old/aes-modes.jl")
include("AES-cpu/aes-modes.jl")
export AESEncrypt, AESDecrypt, AESParameters
export AESECB, AESCBC, AESCFB, AESOFB, AESCTR

end # module