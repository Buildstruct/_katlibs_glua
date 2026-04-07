--A lot of this is directly based on code from my dear friend and mentor Xayr.
--https://github.com/XAYRGA

local NULL_TERMINATOR = "\x00"
local INT8_MAX = 127
local INT8_MIN = -128
local INT16_MAX = 32767
local INT16_MIN = -32768
local INT32_MAX = 2147483647
local INT32_MIN = -2147483648

local math_huge = math.huge
local math_ldexp = math.ldexp
local math_frexp = math.frexp
local math_floor = math.floor
local math_modf = math.modf
local bit_rshift = bit.rshift
local bit_band = bit.band
local bit_bnot = bit.bnot
local string_char = string.char
local string_byte = string.byte
local string_rep = string.rep
local string_sub = string.rep

local convertBytesToInt,convertToBytesFromInt,isInt,unpackIEEE754Double,packIEEE754Double

local getPriv
---SHARED<br>
---@class KBinaryStream
---@overload fun(modelDataTable: KModelData[]): KBinaryStream
KBinaryStream,getPriv = KClass(function(str)
	KError.ValidateArg("str",KVarConditions.String(str))

	return {
		ByteStream = str or "",
		Size = 0,
		Position = 1,
	}
end)

do -- static
	---SHARED, STATIC<br>
	function KBinaryStream.GetTwosCompliment(int,bits)
		local mask = 2^(bits - 1)
		return -(bit_band(int,mask)) + (bit_band(int,bit_bnot(mask)))
	end

	function KBinaryStream.GetInt8BytesLE(n)
		assert(isInt(n) and n >= INT8_MIN and n <= INT8_MAX,"int is not 8-bit!")
		local _,_,_,d  = convertToBytesFromInt(n)
		return string_char(d)
	end

	function KBinaryStream.GetInt8BytesBE(n)
		assert(isInt(n) and n >= INT8_MIN and n <= INT8_MAX,"int is not 8-bit!")
		local a,_,_,_ = convertToBytesFromInt(n)
		return string_char(a)
	end

	function KBinaryStream.GetInt16BytesLE(n)
		assert(isInt(n) and n >= INT16_MIN and n <= INT16_MAX,"int is not 16-bit!")
		local _,_,c,d  = convertToBytesFromInt(n)
		return string_char(d,c)
	end

	function KBinaryStream.GetInt16BytesBE(n)
		assert(isInt(n) and n >= INT16_MIN and n <= INT16_MAX,"int is not 16-bit!")
		local a,b,_,_ = convertToBytesFromInt(n)
		return string_char(a,b)
	end

	function KBinaryStream.GetInt32BytesLE(n)
		assert(isInt(n) and n >= INT32_MIN and n <= INT32_MAX,"int is not 32-bit!")
		local a,b,c,d = convertToBytesFromInt(n)
		return string_char(d,c,b,a)
	end

	function KBinaryStream.GetInt32BytesBE(n)
		assert(isInt(n) and n >= INT32_MIN and n <= INT32_MAX,"int is not 32-bit!")
		local a,b,c,d = convertToBytesFromInt(n)
		return string_char(a,b,c,d)
	end
end

do --set/get properties
	function KBinaryStream:Seek(int)
		getPriv(self).Position = 1 + int
	end

	function KBinaryStream:Skip(int)
		local priv = getPriv(self)
		priv.Position = priv.Position + int
	end

	function KBinaryStream:Reset()
		getPriv(self).Position = 1
	end

	function KBinaryStream:GetSize()
		return getPriv(self).Size
	end

	function KBinaryStream:GetPosition()
		return getPriv(self).Size
	end

	function KBinaryStream:GetStream()
		return getPriv(self).ByteStream
	end
end

do --read/write
	local getTwosCompliment = KBinaryStream.GetTwosCompliment
	local getInt8BytesLE = KBinaryStream.GetInt8BytesLE
	local getInt16BytesLE = KBinaryStream.GetInt16BytesLE
	local getInt32BytesLE = KBinaryStream.GetInt32BytesLE

	function KBinaryStream:Read(amount)
		local priv = getPriv(self)

		local pos = priv.Position
		local bytes = string_sub(priv.ByteStream,pos,pos + amount - 1)

		priv.Position = pos + amount
		return bytes
	end

	function KBinaryStream:Write(bytes)
		local priv = getPriv(self)

		local startPos = priv.Position
		local endPos = priv.Position + #bytes
		local stream = priv.ByteStream
		local streamLength = #stream

		if endPos > streamLength then
			local paddingAmount = endPos - streamLength
			stream = stream .. string_rep("\x00",paddingAmount)
		end

		priv.Position = endPos
		priv.ByteStream = string_sub(stream,0,startPos - 1) .. bytes .. string_sub(stream,endPos)
	end

	local read = KBinaryStream.Read
	local write = KBinaryStream.Write

	function KBinaryStream:ReadUntil(byte)
		local bytes = ""
		if type(byte) == "number" then
			byte = string_char(byte)
		end

		local lastread
		while lastread ~= byte do
			lastread = read(self,1)
			bytes = bytes .. lastread
		end

		return bytes
	end

	local readUntil = KBinaryStream.ReadUntil

	--uint8
	function KBinaryStream:ReadUInt8()
		return convertBytesToInt(read(self,1))
	end

	function KBinaryStream:WriteUInt8(int)
		write(self,getInt8BytesLE(int))
	end

	local readUInt8 = KBinaryStream.ReadUInt8

	--uint16
	function KBinaryStream:ReadUInt16()
		return readUInt8(self)
			+ readUInt8(self) * 0x100
	end

	function KBinaryStream:WriteUInt16(int)
		write(self,getInt16BytesLE(int))
	end

	local readUInt16 = KBinaryStream.ReadUInt16

	--uint32
	function KBinaryStream:ReadUInt32()
		return readUInt8(self)
			+ readUInt8(self) * 0x100
			+ readUInt8(self) * 0x10000
			+ readUInt8(self) * 0x1000000
	end

	function KBinaryStream:WriteUInt32(int)
		write(self,getInt32BytesLE(int))
	end

	local readUInt32 = KBinaryStream.ReadUInt32

	--int8
	function KBinaryStream:ReadInt8()
		return getTwosCompliment(readUInt8(self),8)
	end

	function KBinaryStream:WriteInt8(int)
		write(self,getInt8BytesLE(int))
	end

	--int16
	function KBinaryStream:ReadInt16()
		return getTwosCompliment(readUInt16(self),16)
	end

	function KBinaryStream:WriteInt16(int)
		write(self,getInt16BytesLE(int))
	end

	--int32
	function KBinaryStream:ReadInt32()
		return getTwosCompliment(readUInt32(self),32)
	end

	function KBinaryStream:WriteInt32(int)
		write(self,getInt32BytesLE(int))
	end

	--double
	function KBinaryStream:ReadDouble()
		return unpackIEEE754Double(
			readUInt8(self),
			readUInt8(self),
			readUInt8(self),
			readUInt8(self),
			readUInt8(self),
			readUInt8(self),
			readUInt8(self),
			readUInt8(self))
	end

	function KBinaryStream:WriteDouble(double)
		write(self,string_char(packIEEE754Double(double)))
	end

	--string
	function KBinaryStream:ReadString()
		return readUntil(self,NULL_TERMINATOR)
	end

	function KBinaryStream:WriteString(str)
		write(self,str .. NULL_TERMINATOR)
	end
end

do --helper functions
	local function bytesToIntRecursive(exp, num, digit, ...)
		if not digit then return num end
		return bytesToIntRecursive(exp * 256, num + digit * exp, ...)
	end

	function convertBytesToInt(str)
		if str == nil then return 0 end
		return bytesToIntRecursive(256, string_byte(str, 1, -1))
	end

	function convertToBytesFromInt(n)
		n = (n < 0) and (4294967296 + n) or n -- adjust for 2's complement
		return (math_modf(n / 16777216)) % 256, (math_modf(n / 65536)) % 256, (math_modf(n / 256)) % 256, n % 256
	end

	function isInt(int) return math_floor(int) == int end

	function unpackIEEE754Double(b1, b2, b3, b4, b5, b6, b7, b8)
		local exponent = (b1 % 0x80) * 0x10 + bit_rshift(b2, 4)
		local mantissa = math_ldexp(((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8, -52)
		if exponent == 0x7FF then
			if mantissa > 0 then
				return 0 / 0
			else
				if b1 >= 0x80 then
					return -math_huge
				else
					return math_huge
				end
			end
		elseif exponent > 0 then
			mantissa = mantissa + 1
		else
			exponent = exponent + 1
		end
		if b1 >= 0x80 then
			mantissa = -mantissa
		end
		return math_ldexp(mantissa, exponent - 0x3FF)
	end

	function packIEEE754Double(number)
		if number == 0 then
			return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
		elseif number == math_huge then
			return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x7F
		elseif number == -math_huge then
			return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xFF
		elseif number ~= number then
			return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF8, 0xFF
		else
			local sign = 0x00
			if number < 0 then
				sign = 0x80
				number = -number
			end
			local mantissa, exponent = math_frexp(number)
			exponent = exponent + 0x3FF

			if exponent <= 0 then
				mantissa = math_ldexp(mantissa, exponent - 1)
				exponent = 0
			elseif exponent > 0 then
				if exponent >= 0x7FF then
					return 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, sign + 0x7F
				elseif exponent == 1 then
					exponent = 0
				else
					mantissa = mantissa * 2 - 1
					exponent = exponent - 1
				end
			end

			mantissa = math_floor(math_ldexp(mantissa, 52) + 0.5)

			return mantissa % 0x100,
				math_floor(mantissa / 0x100) % 0x100,
				math_floor(mantissa / 0x10000) % 0x100,
				math_floor(mantissa / 0x1000000) % 0x100,
				math_floor(mantissa / 0x100000000) % 0x100,
				math_floor(mantissa / 0x10000000000) % 0x100,
				(exponent % 0x10) * 0x10 + math_floor(mantissa / 0x1000000000000),
				sign + bit_rshift(exponent, 4)
		end
	end
end