include("aes-code.jl")
using Base.Threads

global const BLOCK_BYTES = (Nb * WORDLENGTH)

# Carries out AES in ECB mode on the given blocks using the given key and
# returns the result.
# ECB mode is carried out in encryption direction if the parameter
# encrypt is true. Otherwise, ECB mode is carried out in decryption
# direction.
# Both the blocks and key must be represented as strings consisting of
# only hexadecimal characters.
# The returned result is a string consisting of only hexadecimal
# characters.
function AESECB(blocks::String, key::String, encrypt::Bool)
	bytes2hex(AESECB(hex2bytes(blocks), hex2bytes(key), encrypt))
end

# Carries out AES in ECB mode on the given blocks using the given key.
# CBC mode is carried out in encryption direction if the parameter
# encrypt is true. Otherwise, ECB mode is carried out in decryption
# direction.
function AESECB(blocks::Array{UInt8, 1}, key::Array{UInt8, 1}, encrypt::Bool)
	noBlocks = paddedCheck(blocks, key)
	o = Array{UInt8}(undef, length(blocks))

	granularity = 100
	(Nk, Nr) = AESParameters(key)
	w = KeyExpansion(key, Nk, Nr)
	@threads for i in 1:convert(Int, ceil( noBlocks/ granularity))
		for j in ((i-1) * granularity + 1) : min(i * granularity, noBlocks)
			local indices = blockIndices(blocks, j)
			o[indices] = encrypt ? AESEncrypt2(blocks[indices], w, Nr) : AESDecrypt2(blocks[indices], w, Nr)
		end
	end

	return o
end

# Carries out AES in CBC mode on the given blocks using the given key and
# returns the result.
# CBC mode is carried out in encryption direction if the parameter
# encrypt is true. Otherwise, CBC mode is carried out in decryption
# direction.
# Both the blocks and key must be represented as strings consisting of
# only hexadecimal characters.
# The returned result is a string consisting of only hexadecimal
# characters.
function AESCBC(blocks::String, key::String,
	iv::String, encrypt::Bool)
	bytes2hex(AESCBC(hex2bytes(blocks), hex2bytes(key), hex2bytes(iv),
	encrypt))
end

# Carries out AES in CBC mode on the given blocks using the given key.
# CBC mode is carried out in encryption direction if the parameter
# encrypt is true. Otherwise, CBC mode is carried out in decryption
# direction.
function AESCBC(blocks::Array{UInt8, 1}, key::Array{UInt8, 1},
	iv::Array{UInt8, 1}, encrypt::Bool)
	noBlocks = paddedCheck(blocks, key)
	if length(iv) != BLOCK_BYTES
		error("IV does not have 16 bytes!")
	end
	o = Array{UInt8}(undef, length(blocks))
	prev = iv

	if encrypt
		for i in 1:noBlocks
			indices = blockIndices(blocks, i)
			curr = AESEncrypt(xor.(prev, blocks[indices]), key)
			o[indices] = curr
			prev = curr
		end
	else
		granularity = 48
		indices = blockIndices(blocks, 1)
		curr = xor.(AESDecrypt(blocks[indices], key), iv)
		o[indices] = curr
		@threads for i in 1:convert(Int, ceil( (noBlocks-1)/ granularity))
			for j in ((i-1) * granularity + 2) : min(i * granularity+1, noBlocks)
				local indices = blockIndices(blocks, j)
				local curr = xor.(AESDecrypt(blocks[indices], key), blocks[blockIndices(blocks, j-1)])
				o[indices] = curr
			end
		end
	end
	return o
end

# Carries out AES in CFB mode on the given blocks using the given key and
# returns the result.
# CFB mode is carried out in encryption direction if the parameter
# encrypt is true. Otherwise, CFB mode is carried out in decryption
# direction.
# Both the blocks and key must be represented as strings consisting of
# only hexadecimal characters.
# The returned result is a string consisting of only hexadecimal
# characters.
function AESCFB(blocks::String, key::String,
	iv::String, encrypt::Bool)
	bytes2hex(AESCFB(hex2bytes(blocks), hex2bytes(key), hex2bytes(iv),
	encrypt))
end

# Carries out AES in CFB mode on the given blocks using the given key.
# CFB mode is carried out in encryption direction if the parameter
# encrypt is true. Otherwise, CFB mode is carried out in decryption
# direction.
function AESCFB(blocks::Array{UInt8, 1}, key::Array{UInt8, 1},
	iv::Array{UInt8, 1}, encrypt::Bool)
	noBlocks = keyStreamCheck(blocks, key, iv)
	o = Array{UInt8}(undef, length(blocks))
	curr = iv

	if encrypt
		for i=1:noBlocks
			indices = blockIndices(blocks, i)
			o[indices] = xor.(AESEncrypt(curr, key)[1:length(indices)], blocks[indices])
			curr = o[indices]
		end
	else
		granularity = 48
		indices = blockIndices(blocks, 1)
		o[indices] = xor.(AESEncrypt(curr, key)[1:length(indices)], blocks[indices])
		@threads for i in 1:convert(Int, ceil( (noBlocks-1)/ granularity))
			for j in ((i-1) * granularity + 2) : min(i * granularity+1, noBlocks)
				local indices = blockIndices(blocks, j)
				local curr = xor.(AESEncrypt(blocks[blockIndices(blocks, j-1)], key)[1:length(indices)], blocks[indices])
				o[indices] = curr
			end
		end
	end

	return o
end

# Carries out AES in OFB mode on the given blocks using the given key and
# returns the result.
# Both the blocks and key must be represented as strings consisting of
# only hexadecimal characters.
# The returned result is a string consisting of only hexadecimal
# characters.
function AESOFB(blocks::String, key::String, iv::String)
	bytes2hex(AESOFB(hex2bytes(blocks), hex2bytes(key), hex2bytes(iv)))
end

# Carries out AES in OFB mode on the given blocks using the given key.
function AESOFB(blocks::Array{UInt8, 1}, key::Array{UInt8, 1},
	iv::Array{UInt8, 1})
	noBlocks = keyStreamCheck(blocks, key, iv)
	o = Array{UInt8}(undef, length(blocks))
	prev = iv

	for i=1:noBlocks
		indices = blockIndices(blocks, i)
		eb = AESEncrypt(prev, key)
		o[indices] = xor.(eb[1:length(indices)] , blocks[indices])
		prev = eb
	end

	return o
end

# Carries out AES in CTR mode on the given blocks using the given key and
# returns the result.
# Both the blocks and key must be represented as strings consisting of
# only hexadecimal characters.
# The returned result is a string consisting of only hexadecimal
# characters. Treats the low eight bytes of the iv array as the little endian
# counter.
function AESCTR(blocks::String, key::String, iv::String)
	bytes2hex(AESCTR(hex2bytes(blocks), hex2bytes(key), hex2bytes(iv)))
end

# Carries out AES in CTR mode on the given blocks using the given key.
# CTR mode is carried out in encryption direction if the parameter
# encrypt is true. Otherwise, CTR mode is carried out in decryption
# direction. Treats the least-significant eight bytes of the iv array
# as the big endian counter.
function AESCTR(blocks::Array{UInt8, 1}, key::Array{UInt8, 1},
	iv::Array{UInt8, 1})
	noBlocks = keyStreamCheck(blocks, key, iv)
	curr_base = iv[end] + 256 * iv[end-1] + 256^2 * iv[end-2] + 256^3 * iv[end-3] + 256^4 * iv[end-4] + 256^5 * iv[end-5] + 256^6 * iv[end-6] + 256^7 * iv[end-7]
	o = Array{UInt8}(undef, length(blocks))

	granularity = 36
	@threads for i in 1:convert(Int, ceil( noBlocks/ granularity))
		for j in ((i-1) * granularity + 1) : min(i * granularity, noBlocks)
			local indices = blockIndices(blocks, j)
			local eb = AESEncrypt(vcat(iv[1:8], to_bytes(curr_base + j-1)), key)
			o[indices] = xor.(eb[1:length(indices)] , blocks[indices])
		end
	end

	return o
end

function to_bytes(n::Integer; len=8)
	bytes = Array{UInt8}(undef, len)
	for byte in reverse(1:len)
		bytes[byte] = n & 0xff
		n >>= 8
	end
	return bytes
end

# Checks whether the parameters are OK for ECB/CBC mode.
# Returns the number of blocks including the last block whose length must
# be as long as the standard block length (16 bytes).
function paddedCheck(blocks::Array{UInt8, 1}, key::Array{UInt8, 1})
	noBlocks = div(length(blocks), BLOCK_BYTES)
	if (noBlocks < 1) || ((noBlocks * BLOCK_BYTES) != length(blocks))
		error("No blocks or length of blocks is not a multplile of ",
		"16!")
	end
	# Check if key is OK
	AESParameters(key)
	return noBlocks
end

# Checks whether the parameters are OK for CFB/OFB/CTR mode.
# Returns the number of blocks including the last block whose length may
# be less than standard block length (16 bytes).
function keyStreamCheck(blocks::Array{UInt8, 1}, key::Array{UInt8, 1},
	iv::Array{UInt8, 1})
	if length(blocks) < 1
		error("blocks must contain at least one byte!")
	end
	noBlocks = div(length(blocks) + BLOCK_BYTES - 1, BLOCK_BYTES)
	# Check if key is OK
	AESParameters(key)
	if length(iv) != BLOCK_BYTES
		error("iv does not have 16 bytes!")
	end
	return noBlocks
end

# Returns the indices of the bytes of a block given a one-based
# block number. The last block may be incomplete.
function blockIndices(blocks::Array{UInt8, 1}, blockNumber::Int)
	@assert(blockNumber >= 1)
	((blockNumber - 1) * BLOCK_BYTES + 1):(min(blockNumber * BLOCK_BYTES, length(blocks)))
end