if KEnumNetMsg then return end

local n_Start = net.Start
local n_WriteUInt = net.WriteUInt
local n_ReadUInt = net.ReadUInt

local function getBitsInNum(n)
    local ct = 0;
    while n ~= 0 do
        ct = ct + 1
        n = bit.rshift(n,1)
    end

    return ct
end

---SHARED, STATIC<br>
---Trades network efficiency for less NWString usage.<br>
---Probably good for organizing net messages in use cases where net efficiency isn't a priority.<br>
---
---the only moral action is the minimization of NW slots - sun tzu
---@param netstring string
---@return function netMsgStart(number messageEnum)
---@return function netMsgReceiver(number messageEnum, function callback)
function KEnumNetMsg(netstring,enums)
    KError.ValidateArg(1,"netstring",KVarCondition.StringNotEmpty(netstring))
    KError.ValidateArg(2,"enums",KVarCondition.Table(enums))
    for k,v in pairs(enums) do
        KError.ValidateKVArg(2,"enums." .. k,KVarCondition.StringNotEmpty(netstring),KVarCondition.NumberGreaterOrEqual(v,0))
    end

    if SERVER then util.AddNetworkString(netstring) end

    local highestEnum = enums[table.GetWinningKey(enums)]
    local enum_bitcount = getBitsInNum(highestEnum)
    local receivers = {}

    ---SHARED<br>
    ---Starts a netmessage with the a netmessage enum.
    ---@param messageEnum number
    local function netMsgStart(messageEnum)
        n_Start(netstring)
        n_WriteUInt(messageEnum,enum_bitcount)
    end

    ---SHARED<br>
    ---Receives a netmessage with the a netmessage enum.
    ---@param messageEnum number
    ---@param func function
    local function netMsgReceiver(messageEnum,func)
        receivers[messageEnum] = func
    end

    net.Receive(netstring,function(_,ply)
        local receiver = receivers[n_ReadUInt(enum_bitcount)]
        if receiver then receiver(ply) end
    end)

    return netMsgStart,netMsgReceiver
end