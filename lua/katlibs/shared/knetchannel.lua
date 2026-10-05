local SYSTEM_NAME = "KNetChannel"
if SERVER then util.AddNetworkString(SYSTEM_NAME) end

local function netStart(id,callback,...)
    net.Start(SYSTEM_NAME)
    KSyncedToken.WriteToNet(id)

    local bytesUsedStart = net.BytesWritten()
    callback(...)
    return net.BytesWritten() - bytesUsedStart
end

local function netSend(players)
    if CLIENT then
        net.SendToServer()
        return
    end

    if players ~= nil then
        net.Send(players)
        return
    end

    net.Broadcast()
end

local getPriv
KNetChannel,getPriv = KClass(function(identifier,burstLimit,regenRate,unreliable)
    return {
        SyncedToken = SERVER and KSyncedToken.Get(identifier),
        Identifier = identifier,
        Queue = KQueue(),
        TokenBucket = KTimeUtils.TokenBucket(burstLimit,regenRate,true),
        BurstLimit = burstLimit,
        Unreliable = unreliable and true or false,
    }
end)

local activeChannels = setmetatable({},{__mode = "v"})

function KNetChannel:Send(callback,players,...)
    local priv = getPriv(self)

    local cost = netStart(priv.Identifier,callback,...)
    if cost > priv.BurstLimit then
        net.Abort()
        error(string.format("Net channel burst limit exceeded! (%d > %d)",cost,priv.BurstLimit))
    end

    local queue = priv.Queue
    local canSend = priv.TokenBucket(cost)
    if queue:Any() or not canSend then
        if priv.Unreliable then
            net.Abort()
            return false
        end

        queue:PushRight({
            Cost = cost,
            Callback = callback,
            Args = {...},
            Players = players,
        })
        activeChannels[self] = true

        net.Abort()
        return false
    end

    netSend(players)
    return true
end

function KNetChannel:Flush()
    getPriv(self).Queue = KQueue()
end

hook.Add("Tick",SYSTEM_NAME,function()
    for channel,_ in pairs(activeChannels) do
        local priv = getPriv(channel)
        local queue = priv.Queue

        if not queue:Any() then
            activeChannels[channel] = nil
            continue
        end

        local message = queue:GetLeft()
        if not priv.TokenBucket(message.Cost) then continue end

        netStart(priv.Identifier,message.Callback,unpack(message.Args))
        netSend(message.Players)
        queue:PopLeft()
    end
end)

local callbacks = {}
function KNetChannel.Receive(identifier,callback)
    callbacks[identifier] = isfunction(callback) and {
        SyncedToken = SERVER and KSyncedToken.Get(identifier),
        Callback = callback
    } or nil
end

net.Receive(SYSTEM_NAME,function(len,ply)
    local identifier = KSyncedToken.ReadFromNet()

    local callback = callbacks[identifier].Callback
    if not callback then return end

    callback(len,ply)
end)