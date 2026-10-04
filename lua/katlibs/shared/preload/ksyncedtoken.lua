local SYSTEM_NAME = "KSyncedToken"

if SERVER then
	util.AddNetworkString(SYSTEM_NAME)

	local uintTokenLookup = setmetatable({},{__mode = "v"})
	local stringTokenLookup = setmetatable({},{__mode = "v"})

	local function add(priv)
		net.Start(SYSTEM_NAME)
		net.WriteBool(true)
		net.WriteString(priv.Identifier)
		net.WriteUInt(priv.UInt,32)
		net.Broadcast()
	end

	local function remove(priv)
		net.Start(SYSTEM_NAME)
		net.WriteBool(false)
		net.WriteString(priv.Identifier)
		net.WriteUInt(priv.UInt,32)
		net.Broadcast()
	end

	local getPriv
	---SERVER<br/>
	---A token that is a unique string that is synced from the server to the client using a uint32 to decrease bandwith.<br/>
	---<br/>
	---Tokens are:
	--- - Alphanumeric characters and underscores only
	--- - Max 30 characters
	--- - Case insensitive
	---@class KSyncedToken
	KSyncedToken,getPriv = KClass(nil,{
		Destructor = remove,
	})

	local uidItr = 0
	local instantiate = getPriv(KSyncedToken).Instantiate
	---SERVER<br/>
	---Registers a new synced token, or an active token with the same identifier.<br/>
	---If the all token handles referencing the identifier are cleaned up by the garbage collector, the token will become invalid.<br/>
	---@param identifier string The identifier that will be used to sync the token with the client.<br/>
	---@return KSyncedToken
	function KSyncedToken.Get(identifier)
		identifier = string.lower(identifier)

		local token = stringTokenLookup[identifier]
		if token then return token end

		uidItr = uidItr + 1
		local uint = uidItr
		token = instantiate({
			Identifier = identifier,
			UInt = uint,
		})

		KError.ValidateArg("identifier",KVarConditions.StringLengthLessOrEqual(identifier,30))
		assert(identifier:match("^[A-Za-z0-9_]+$") ~= nil,"Tokens may only contain alphanumeric characters and underscores!")

		uintTokenLookup[uint] = token
		stringTokenLookup[identifier] = token

		add(getPriv(token))

		return token
	end

	---SHARED<br/>
	---Writes a token to the net stream.<br/>
	---Errors if the token is invalid (no active handles).
	---@param identifier string
	function KSyncedToken.WriteToNet(identifier)
		local token = stringTokenLookup[identifier]
		assert(token ~= nil,"Token invalid!")
		net.WriteUInt(getPriv(token).UInt,32)
	end

	---SHARED<br/>
	---Reads a token from the net stream.<br/>
	---Returns nil if this token is invalid (no active handles).
	---@return string?
	function KSyncedToken.ReadFromNet()
		return uintTokenLookup[net.ReadUInt(32)]
	end

	KClientInit.Register("KSyncedToken",function(ply)
		for _,token in pairs(uintTokenLookup) do
			local priv = getPriv(token)
			net.Start(SYSTEM_NAME)
			net.WriteBool(true)
			net.WriteString(priv.Identifier)
			net.WriteUInt(priv.UInt,32)
			net.Send(ply)
		end
	end)
else
	KSyncedToken = {}

	local uintStringLookup = {}
	local stringUintLookup = {}

	net.Receive(SYSTEM_NAME,function()
		local add = net.ReadBool()

		local identifier = net.ReadString()
		local uint = net.ReadUInt(32)

		uintStringLookup[uint] = add and identifier or nil
		stringUintLookup[identifier] = add and uint or nil
	end)

	---SHARED<br/>
	---Writes a token to the net stream.<br/>
	---Errors if the token is invalid (no active handles).
	---@param identifier string
	function KSyncedToken.WriteToNet(identifier)
		local uint = stringUintLookup[identifier]
		assert(uint ~= nil,"Token invalid!")
		net.WriteUInt(uint,32)
	end

	---SHARED<br/>
	---Reads a token from the net stream.<br/>
	---Returns nil if this token is invalid (no active handles).
	---@return string?
	function KSyncedToken.ReadFromNet()
		local uint = net.ReadUInt(32)
		return uintStringLookup[uint]
	end
end