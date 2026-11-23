local n_WriteUInt = net.WriteUInt
local n_ReadUInt = net.ReadUInt

local function getBitsInNum(n)
    local ct = 0
    while n ~= 0 do
        ct = ct + 1
        n = bit.rshift(n,1)
    end

    return ct
end

local getPriv
---SHARED<br/>
---Helper class for pre-defined enum-based networked actions.<br/>
---<b><u><i>Never trust the client!!!</i></u></b>
---@class KNetEnumDispatch
---@overload fun(enums: {[string]: number}): KNetEnumDispatch
KNetEnumDispatch,getPriv = KClass(function(enums)
    local allowedEnums = {}
    local highest = -1

    assert(next(enums) ~= nil,"Enums table is empty!")
    for _,value in pairs(enums) do
        assert(
            isnumber(value)
            and value >= 0
            and value <= 4294967295
            and value % 1 == 0
        ,"All enums must be integers [0,4294967295]!")

        if value > highest then highest = value end
        allowedEnums[value] = true
    end

    return {
        AllowedEnums = allowedEnums,
        Bits = getBitsInNum(highest),
        Callbacks = {},
    }
end)

---SHARED<br/>
---Registers a callback on this realm for this enum.<br/>
---Pass a nil callback to clear.
---@param enum integer
---@param callback? function
function KNetEnumDispatch:Register(enum,callback)
    local priv = getPriv(self)
    assert(priv.AllowedEnums[enum] ~= nil,
        "Enum was not defined at instantiation of this KNetEnumDispatch!")
    priv.Callbacks[enum] = callback
end

---SHARED<br/>
---Writes the action enum to the net stream.
---@param enum integer
function KNetEnumDispatch:WriteToNet(enum)
    n_WriteUInt(enum,getPriv(self).Bits)
end

---SHARED<br/>
---Reads the action enum from the netstream and invokes the associated callback.
function KNetEnumDispatch:ReadFromNetAndInvoke(...)
    local priv = getPriv(self)
    local enum = n_ReadUInt(priv.Bits)
    local callback = priv.Callbacks[enum]
    if not callback then return end
    callback(...)
end