module AES

using StaticArrays, Random

abstract type AbstractSymmetricKey end
abstract type AbstractCipher end
abstract type AbstractCipherCache end

abstract type AbstractAESKey <: AbstractSymmetricKey end
abstract type AbstractAESCache <: AbstractCipherCache end

include("AES-old/constants.jl")
include("AES-old/types.jl")
include("AES-old/block_encryption.jl")
include("AES-old/block_decryption.jl")
include("AES-old/modes/cbc.jl")
include("AES-old/modes/ctr.jl")
include("AES-old/modes/ecb.jl")
include("AES-old/encrypt.jl")
include("AES-old/decrypt.jl")

export AESCipher
export AES128Key, AES192Key, AES256Key
export AESCache
export encrypt, decrypt

end # module
