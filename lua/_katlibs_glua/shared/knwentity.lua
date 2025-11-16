if KNWEntity then return end
KNWEntity = {}
AddCSLuaFile()

--[[ DOCS:
Purpose:
A static clientside entity table that is accessible even if the entity is not networked due to being out of PVS.
Contains hook methods that act as convenient callbacks on entity clientside initialization, clientside deinitialization, and serverside removal.

SERVER:
    Functions:
        void net.WriteKNWEntity(Entity ent)
        void KNWEntity.SendRemoveCall(Entity ent,Player ply)
        void KNWEntity.BroadcastRemoveCall(Entity ent)

CLIENT:
    Classes:
        KNWEntity {
            void OnInitialize(eid,ent)
            void OnDeinitialize(eid,ent)
            void OnRemove(eid)
            Entity GetEntity()
        }

    Functions:
        KNWEntity KNWEntity(int entIndex)
        KNWEntity net.ReadKNWEntity()
        KNWEntity Entity:GetKNWEntity()
]]

local ent_meta = FindMetaTable("Entity")
local e_EntIndex = ent_meta.EntIndex

local n_Start = net.Start
local n_WriteUInt = net.WriteUInt
local n_ReadUInt = net.ReadUInt
local n_Send = net.Send
local n_Broadcast = net.Broadcast
local IsValid = IsValid
local t_Simple = timer.Simple
local Entity = Entity

local NETSTRING_ENTREMOVED = "kat_EntityNetworking_er"

local activeEnts = {}
if SERVER then
    util.AddNetworkString(NETSTRING_ENTREMOVED)

    function net.WriteKNWEntity(ent)
        activeEnts[ent] = true
        n_WriteUInt(e_EntIndex(ent),13)
    end

    function KNWEntity.SendRemoveCall(ent,ply)
        n_Start(NETSTRING_ENTREMOVED)
        n_WriteUInt(e_EntIndex(ent),13)
        n_Send(ply)
    end

    function KNWEntity.BroadcastRemoveCall(ent)
        if not activeEnts[ent] then return end
        activeEnts[ent] = nil

        n_Start(NETSTRING_ENTREMOVED)
        n_WriteUInt(e_EntIndex(ent),13)
        n_Broadcast()
    end
    hook.Add("EntityRemoved","KNWEntity",KNWEntity.BroadcastRemoveCall)
elseif CLIENT then
    local retTrue = function() return true end
    local retFalse = function() return false end

    local initialized = {}
    local hooks = setmetatable({},{__index = function(t,k)
        local nT = {
            OnInitialize = {},
            OnDeinitialize = {},
            OnRemove = {},
        }
        t[k] = nT
        return nT
    end})

    local function callHooks(eid,hooktype)
        local ent = Entity(eid)
        local valid = IsValid(ent)

        for _,func in pairs(hooks[eid][hooktype]) do
            func(eid,valid and ent or nil)
        end
    end

    function net.ReadKNWEntity()
        local eid = n_ReadUInt(13)

        local knwEnt = activeEnts[eid]
        if knwEnt then
            knwEnt.IsFirstTimeNetworked = retFalse
            return knwEnt
        end

        local st = SysTime()
        knwEnt = {
            AddHook = function(_,hooktype,id,func)
                local hookTab = hooks[eid][hooktype]
                if not hookTab then error("invalid hooktype") end
                hookTab[id] = func
            end,
            GetEntity = function() return Entity(eid) end,
            EntIndex = function() return eid end,
            GetNWLifetime = function() return SysTime() - st end,
            IsFirstTimeNetworked = retTrue,
        }
        activeEnts[eid] = knwEnt

        t_Simple(0,function()
            local ent = Entity(eid)
            if not IsValid(ent) then return end

            if initialized[eid] then return end
            initialized[eid] = true

            callHooks(eid,"OnInitialize")
        end)

        return knwEnt
    end

    function ent_meta:GetKNWEntity()
        return activeEnts[e_EntIndex(self)]
    end

    function KNWEntity(eid)
        return activeEnts[eid]
    end

    hook.Add("NetworkEntityCreated","KNWEntity",function(ent)
        if not IsValid(ent) then return end

        local eid = e_EntIndex(ent)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        if initialized[eid] then return end
        initialized[eid] = true

        callHooks(eid,"OnInitialize")
    end)

    hook.Add("EntityRemoved","KNWEntity",function(ent)
        local eid = e_EntIndex(ent)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        initialized[eid] = nil

        callHooks(eid,"OnDeinitialize")
    end)

    net.Receive(NETSTRING_ENTREMOVED, function()
        local eid = n_ReadUInt(13)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        callHooks(eid,"OnRemove")
        activeEnts[eid] = nil
        hooks[eid] = nil
    end)
end

--solarembra 9/1/2025