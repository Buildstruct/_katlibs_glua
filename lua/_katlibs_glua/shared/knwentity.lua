if KNWEntity then return end

local activeEnts = {}

---@class KNWEntity
---CLIENT<br>
---A clientside entity registry that is accessible even if the entity is invalid (not networked; out of PVS.)<br>
---Contains hook methods that act as convenient callbacks on entity clientside initialization, clientside deinitialization, and serverside removal.
---@overload fun(entIndex: number): KNWEntity
---@return KNWEntity KNWEntity
KNWEntity = setmetatable({},{__call = function(_,eid)
    return activeEnts[eid]
end})

local n_Start = net.Start
local n_WriteUInt = net.WriteUInt
local n_ReadUInt = net.ReadUInt
local n_Send = net.Send
local n_Broadcast = net.Broadcast
local IsValid = IsValid
local t_Simple = timer.Simple
local Entity = Entity
---@class Entity
local ent_meta = FindMetaTable("Entity")
local e_EntIndex = ent_meta.EntIndex

local NETSTRING_ENTREMOVED = "KEntityNetworking"

if SERVER then
    util.AddNetworkString(NETSTRING_ENTREMOVED)

    ---SERVER<br>
    ---Writes an entity to the net message to be read as a KNWEntity clientside.
    ---@param ent Entity
    function net.WriteKNWEntity(ent)
        KError.ValidateArg(2,"ent",KVarCondition.Entity(ent))

        n_WriteUInt(e_EntIndex(ent),13)
        activeEnts[ent] = true
    end

    ---SERVER<br>
    ---Manually call the OnRemove hook on a clientside KNWEntity.<br>
    ---Sends to a specific player.
    ---@param ent Entity
    ---@param ply Player
    function KNWEntity.SendRemoveCall(ent,ply)
        if not activeEnts[ent] then return end
        KError.ValidateArg(2,"ply",KVarCondition.Player(ply))

        n_Start(NETSTRING_ENTREMOVED)
        n_WriteUInt(e_EntIndex(ent),13)
        n_Send(ply)
    end

    ---SERVER<br>
    ---Manually call the OnRemove hook on a clientside KNWEntity.<br>
    ---Broadcasts to all players.
    ---@param ent Entity
    function KNWEntity.BroadcastRemoveCall(ent)
        if not activeEnts[ent] then return end
        activeEnts[ent] = nil

        n_Start(NETSTRING_ENTREMOVED)
        n_WriteUInt(e_EntIndex(ent),13)
        n_Broadcast()
    end
    hook.Add("EntityRemoved","KNWEntity",KNWEntity.BroadcastRemoveCall)
elseif CLIENT then
    local privTab = setmetatable({},{__mode = "k"})

    ---CLIENT<br>
    ---Gets an entity's KNWEntity.
    ---@returns KNWEntity
    function ent_meta:GetKNWEntity()
        return activeEnts[e_EntIndex(self)]
    end

    ---private constructor
    ---@param eid number
    local function registerNewKNWEntity(eid)
        local newObj = setmetatable({},{__index = KNWEntity})

        privTab[newObj] = {
            EntIndex = eid,
            NWTime = SysTime(),
            IsFirstTimeNetworked = true,
            Active = false,
            Hooks = {
                OnInitialize = {},
                OnDenitialize = {},
                OnRemove = {},
            },
        }

        return newObj
    end

    ---CLIENT<br>
    ---Reads a KNWEntity from a net message.
    ---@returns KNWEntity KNWEntity
    function net.ReadKNWEntity()
        local eid = n_ReadUInt(13)
        local knwEnt = activeEnts[eid]

        if knwEnt then
            privTab[knwEnt].IsFirstTimeNetworked = false
            return knwEnt
        end

        knwEnt = registerNewKNWEntity(eid)

        t_Simple(0,function()
            local ent = Entity(eid)
            if not IsValid(ent) then return end

            local priv = privTab[knwEnt]

            priv.Active = true
            priv.Hooks.OnInitialize(eid,ent)
        end)

        return knwEnt
    end

    ---CLIENT<br>
    ---Gets an KNWEntity's Entity.
    function KNWEntity:GetEntity()
        return Entity(privTab[self].EntIndex)
    end

    ---CLIENT<br>
    ---Gets an KNWEntity's entity index.
    function KNWEntity:EntIndex()
        return privTab[self].EntIndex
    end

    ---CLIENT<br>
    ---Returns the time in seconds since this KNWEntity was registered.
    function KNWEntity:GetNWLifetime()
        return SysTime() - privTab[self].NWTime
    end

    ---CLIENT<br>
    ---Returns if this KNWEntity has only been registered once.
    function KNWEntity:IsFirstTimeNetworked()
        return privTab[self].IsFirstTimeNetworked
    end

    ---CLIENT<br>
    ---Register a hook with this KNWEntity.
    ---Hooks:
    --- - OnInitialize(number entIndex, Entity ent)
    --- - OnDeinitialize(number entIndex)
    --- - OnRemove(number entIndex)
    function KNWEntity:AddHook(hooktype,id,func)
        KError.ValidateArg(3,"func",KVarCondition.Function(func))

        local hookTab = privTab[self].Hooks[hooktype]
        if not hookTab then return end
        hookTab[id] = func
    end

    hook.Add("NetworkEntityCreated","KNWEntity",function(ent)
        if not IsValid(ent) then return end

        local eid = e_EntIndex(ent)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        local priv = privTab[knwEnt]
        if priv.Active then return end

        priv.Active = true
        priv.Hooks.OnInitialize(eid,ent)
    end)

    hook.Add("EntityRemoved","KNWEntity",function(ent)
        local eid = e_EntIndex(ent)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        local priv = privTab[knwEnt]
        if not priv.Active then return end

        priv.Active = false
        priv.Hooks.OnDeinitialize(eid)
    end)

    net.Receive(NETSTRING_ENTREMOVED, function()
        local eid = n_ReadUInt(13)
        local knwEnt = activeEnts[eid]
        if not knwEnt then return end

        local priv = privTab[knwEnt]

        priv.Hooks.OnRemove(eid)
        activeEnts[eid] = nil
    end)
end