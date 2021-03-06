using BenchmarkTools
using CUDA
using Test

include("galois-field.jl")

###################### CODE ####################

global const Nks = CuArray([4, 6, 8])
global const Nbs = CuArray([4, 4, 4])
global const Nb = 4
global const Nrs = CuArray([10, 12, 14])
global const WORDLENGTH = 4

global const SBOX = CuArray([
0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
])
global const SBOX_CuDeviceVector = cudaconvert(SBOX)

global const INVSBOX = CuArray([
0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
])

global const MIXCOLUMNSMATRIX2 = CuArray([
0x02, 0x03, 0x01, 0x01,
0x01, 0x02, 0x03, 0x01,
0x01, 0x01, 0x02, 0x03,
0x03, 0x01, 0x01, 0x02
])

global const MIXCOLUMNSMATRIX = cudaconvert(MIXCOLUMNSMATRIX2)

global const INVMIXCOLUMNSMATRIX = cudaconvert(CuArray([
0x0e, 0x0b, 0x0d, 0x09,
0x09, 0x0e, 0x0b, 0x0d,
0x0d, 0x09, 0x0e, 0x0b,
0x0b, 0x0d, 0x09, 0x0e
]))

# Return a tuple (Nk, Nr) where Nk is the number of key blocks
# and Nr is the number of rounds for the key size.
function AESParameters(key::CuArray{UInt8, 1})
	if mod(length(key), WORDLENGTH) != 0
		error("the key length must be a multiple of four!")
	end

	Nk = div(length(key), WORDLENGTH)
	i = first(indexin([Nk], Nks)) 

	if i == 0
		error("key length is non-standard!")
	end

	Nr = Nrs[i]
	return (Nk, Nr)
end

function AESCipher(o::CuDeviceVector{UInt8, 1}, plain::CuDeviceVector{UInt8, 1}, w::CuDeviceVector{UInt8, 1}, Nr::Int, begin_ind::Int, end_ind::Int, buffer::CuDeviceVector{UInt8, 1})
	@assert(WORDLENGTH == Nb)
	@assert((end_ind - begin_ind + 1) == (WORDLENGTH * Nb))
	@assert(length(w) == (WORDLENGTH * Nb * (Nr + 1)))

	# Copy
	for i=begin_ind:end_ind
		o[i] = plain[i]
	end

	# AddRoundKey
	for i=begin_ind:end_ind
		o[i] = gadd(o[i], w[i - begin_ind + 1])
	end

	for round=1:(Nr-1)
		# SubBytes
		for i=begin_ind:end_ind
			o[i] = SBOX_CuDeviceVector[Int(o[i]) + 1]
		end

		# ShiftRows
		for r=2:Nb
			step = r
			cnt = 0
			tmp = 0
			for index=r:Nb:Nb*Nb
				buffer[begin_ind + index - 1] = o[begin_ind + index - 1]
			end
			for index=r:Nb:Nb*Nb
				p = mod(cnt + step - 1, Nb) + 1
				p_index = r + Nb * (p - 1)
				o[begin_ind + index - 1] = buffer[begin_ind + p_index - 1]
				cnt += 1
			end
		end

 		# MixColumns
		for c=1:Nb
			for index=((c - 1) * Nb + 1):(c * Nb)
				buffer[begin_ind + index - 1] = o[begin_ind + index - 1]
			end
			for r=1:Nb
				indices_r = ((c - 1) * Nb + 1) + r - 1
				for j=((r - 1) * Nb + 1):(r * Nb)
					mij = MIXCOLUMNSMATRIX[j]
					nth_element = j - ((r - 1) * Nb + 1) # 0-indexed
					aij = buffer[begin_ind + ((c - 1) * Nb + 1) - 1 + nth_element]
					res = gmul2(aij, mij)
					if j == ((r - 1) * Nb + 1)
						o[begin_ind + indices_r - 1] = res
					else
						o[begin_ind + indices_r - 1] = gadd(o[begin_ind + indices_r - 1], res)
					end
				end
			end
		end

 		# AddRoundKey(state, w[(round * Nb * WORDLENGTH + 1):((round + 1) * Nb * WORDLENGTH)])
		for i=begin_ind:end_ind
			o[i] = gadd(o[i], w[i - begin_ind + (round * Nb * WORDLENGTH + 1)])
		end

	end

 	# SubBytes(state)
	for i=begin_ind:end_ind
		o[i] = SBOX_CuDeviceVector[Int(o[i]) + 1]
	end

 	# ShiftRows(state)
	for r=2:Nb
		step = r
		cnt = 0
		tmp = 0
		for index=r:Nb:Nb*Nb
			buffer[begin_ind + index - 1] = o[begin_ind + index - 1]
		end
		for index=r:Nb:Nb*Nb
			p = mod(cnt + step - 1, Nb) + 1
			p_index = r + Nb * (p - 1)
			o[begin_ind + index - 1] = buffer[begin_ind + p_index - 1]
			cnt += 1
		end
	end

 	# AddRoundKey(state, w[(Nr * Nb * WORDLENGTH + 1):((Nr + 1) * Nb * WORDLENGTH)])
	for i=begin_ind:end_ind
		o[i] = gadd(o[i], w[i - begin_ind + (Nr * Nb * WORDLENGTH + 1)])
	end

end

function AESEncrypt(o::CuDeviceVector{UInt8, 1}, plain::CuDeviceVector{UInt8, 1}, key::CuDeviceVector{UInt8, 1}, begin_ind::Int, end_ind::Int, Nk::Int, Nr::Int, w::CuDeviceVector{UInt8, 1}, buffer::CuDeviceVector{UInt8, 1})
	AESCipher(o, plain, w, Nr, begin_ind, end_ind, buffer)
end

function AESDecrypt(o::CuDeviceVector{UInt8, 1}, cipher::CuDeviceVector{UInt8, 1}, key::CuDeviceVector{UInt8, 1}, begin_ind::Int, end_ind::Int, Nk::Int, Nr::Int, w::CuDeviceVector{UInt8, 1}, buffer::CuDeviceVector{UInt8, 1})
	# (w, Nr) = AEScrypt(cipher, key, Nk, Nr)
	# return AESInvCipher(cipher, w, Nr)
	return cipher
end

function KeyExpansion!(w::CuArray{UInt8, 1}, key::CuArray{UInt8, 1}, Nk::Int, Nr::Int)
	@assert(length(key) == (WORDLENGTH * Nk))

	w[1:(WORDLENGTH * Nk)] = copy(key)
	i = Nk

	while i < (Nb * (Nr + 1))
		temp = w[((i - 1) * WORDLENGTH + 1):(i * WORDLENGTH)]
		if mod(i, Nk) == 0
			temp = xor.(SubWord(RotWord(temp)), Rcon(div(i, Nk)))
		elseif (Nk > 6) && (mod(i, Nk) == Nb)
			temp = SubWord(temp)
		end
		w[(i * WORDLENGTH + 1):((i + 1) * WORDLENGTH)] = xor.(w[((i - Nk) * WORDLENGTH + 1):((i - Nk + 1) * WORDLENGTH)] , temp)
		i += 1
	end

	return nothing
end

function SubWord(w::CuArray{UInt8, 1})
	@assert(length(w) == WORDLENGTH)
	# map!(x -> SBOX[Int(x) + 1], w, w)
	# return w
	for i=1:length(w)
		w[i] = SBOX[Int(w[i]) + 1]
	end
	return w
end

function RotWord(w::CuArray{UInt8, 1})
	@assert(length(w) == WORDLENGTH)
	# permute!(w, [2, 3, 4, 1])
	tmp = w[1]
	w[1] = w[2]
	w[2] = w[3]
	w[3] = w[4]
	w[4] = tmp
    return w
end

function Rcon(i::Int)
	@assert(i > 0)
	x = 0x01
	for j=1:(i-1)
		x = gmul(x, 0x02)
	end
	return CuArray([x, 0x00, 0x00, 0x00])
end

####################### MODES #######################

global const BLOCK_BYTES = (Nb * WORDLENGTH)

function AESECB(blocks::String, key::String, encrypt::Bool)
    blocks_cuarray, key_cuarray = CUDA.allowscalar() do
        blocks_cuarray = CuArray(hex2bytes(blocks))
        key_cuarray = CuArray(hex2bytes(key))
        return blocks_cuarray, key_cuarray
    end
    cipher_cuarray = AESECB(blocks_cuarray, key_cuarray, encrypt)
	return cipher_cuarray
#	  # NOTE: converting a CUDA array back to a string is superrrr slow; only use this for correctness testing but not performance testing
#     cipher = CUDA.allowscalar() do
#         return bytes2hex(cipher_cuarray)
#     end
#     return cipher
end

function AESECB(blocks::CuArray{UInt8, 1}, key::CuArray{UInt8, 1}, encrypt::Bool)
    noBlocks, Nk, Nr = CUDA.allowscalar() do
        return paddedCheck(blocks, key)
    end
	w = CuArray{UInt8, 1}(undef, WORDLENGTH * Nb * (Nr + 1))
	CUDA.allowscalar() do
		KeyExpansion!(w, key, Nk, Nr)
	end
	
	o = CuArray{UInt8, 1}(undef, length(blocks))
	buffer = CuArray{UInt8, 1}(undef, length(blocks))

    # hardcode threads: TODO find out a good number
	numblocks = ceil(Int, length(blocks) / BLOCK_BYTES / 256)
    @cuda threads=256 blocks=numblocks AESECB_do_blocks!(cudaconvert(o), noBlocks, cudaconvert(blocks), cudaconvert(key), encrypt, Nk, Nr, cudaconvert(w), cudaconvert(buffer))

	return o
end

function AESECB_do_blocks!(o::CuDeviceVector{UInt8, 1}, noBlocks::Int, blocks::CuDeviceVector{UInt8, 1}, key::CuDeviceVector{UInt8, 1}, encrypt::Bool, Nk::Int, Nr::Int, w::CuDeviceVector{UInt8, 1}, buffer::CuDeviceVector{UInt8, 1})
    # index = threadIdx().x    
    # stride = blockDim().x
	index = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = gridDim().x * blockDim().x
    for i=index:stride:noBlocks
		@assert(i >= 1)
		indices_begin = (i - 1) * BLOCK_BYTES + 1
		indices_end = min(i * BLOCK_BYTES, length(blocks))
		@assert(indices_end - indices_begin <= 16)
		encrypt ? AESEncrypt(o, blocks, key, indices_begin, indices_end, Nk, Nr, w, buffer) : AESDecrypt(o, blocks, key, indices_begin, indices_end, Nk, Nr, w, buffer)
	end
    return nothing
end

function paddedCheck(blocks::CuArray{UInt8, 1}, key::CuArray{UInt8, 1})
	noBlocks = div(length(blocks), BLOCK_BYTES)
	if (noBlocks < 1) || ((noBlocks * BLOCK_BYTES) != length(blocks))
		error("No blocks or length of blocks is not a multplile of ",
		"16!")
	end
	# Check if key is OK
	Nk, Nr = AESParameters(key)
	return noBlocks, Nk, Nr
end

# function blockIndices(blocks::CuArray{UInt8, 1}, blockNumber::Int)
# 	@assert(blockNumber >= 1)
# 	((blockNumber - 1) * BLOCK_BYTES + 1):(min(blockNumber * BLOCK_BYTES, length(blocks)))
# end

######################## DRIVER ##########################


# ###### Correctness Test

# const key4 =    "2b7e151628aed2a6abf7158809cf4f3c"
# const plain4 =  "6bc1bee22e409f96e93d7e117393172a"
# const cipher4 = "3ad77bb40d7a3660a89ecaf32466ef97"

# println(AESECB(plain4, key4, true) == cipher4)


###### Speed Test
key = "2b7e151628aed2a6abf7158809cf4f3c"
plaintext = "A"
while length(plaintext) < 2^20
    global plaintext
    plaintext = plaintext * plaintext
end

CUDA.allowscalar(false)

function bench_gpu(plaintext, key, encryption)
    CUDA.@sync begin
		AESECB(plaintext, key, encryption)
	end
end
@btime bench_gpu(plaintext, key, true)
# println(size(AESECB(plaintext, key, true)))