if KClientInit then return end
KClientInit = {}
AddCSLuaFile()

--[[ DOCS:
Purpose:
Quick and convenient sync the client with the server on choice data.
Has a hook to know when it's safe to assume the client is up to date.

SERVER:
    Functions:
        void KClientInit.SendClientData(string key,function netmsg)

	Hooks:
		kat_OnClientInit(Player ply)

CLIENT:
    Functions:
        void KClientInit.ReceiveServerData(string key,function netmsg)
]]

local NETSTRING = "KClientInit"

local h_Run = hook.Run
local n_Start = net.Start
local n_WriteString = net.WriteString
local n_ReadString = net.ReadString
local n_Send = net.Send
local n_SendToServer = net.SendToServer
local pairs = pairs

local receivers = {}

if SERVER then
	util.AddNetworkString(NETSTRING)

	local alreadyLoaded = {}
	hook.Add("PlayerDisconnected","KClientInit",function(ply)
		alreadyLoaded[ply] = nil
	end)

	net.Receive("KClientInit", function(_,ply)
		if alreadyLoaded[ply] then return end
		alreadyLoaded[ply] = true

		h_Run("kat_OnClientInit",ply)

		for key,func in pairs(receivers) do
			n_Start(NETSTRING)
			n_WriteString(key)
			func()
			n_Send(ply)
		end
	end)

	function KClientInit.SendClientData(key,func)
		receivers[key] = func
	end
elseif CLIENT then
	hook.Add("InitPostEntity","KClientInit",function()
		n_Start(NETSTRING)
		n_SendToServer()
	end)

	function KClientInit.ReceiveServerData(key,func)
		receivers[key] = func
	end

	net.Receive("KClientInit",function()
		local func = receivers[n_ReadString()]
		if func then func() end
	end)
end