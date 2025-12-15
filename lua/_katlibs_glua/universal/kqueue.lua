if KQueue then return end

local privTab = setmetatable({},{__mode = "k"})

---@class KQueue
---@overload fun(): KQueue
---@return KQueue KQueue
---A queue data structure.
KQueue = setmetatable({},{
    __call = function()
        local newObj = setmetatable({},{__index = KQueue})

        privTab[newObj] = {
            first = 0,
            last = -1,
            empty = true,
        }

        return newObj
    end,
})

function KQueue:Any()
    local priv = privTab[self]

    return priv.first <= priv.last
end

function KQueue:Count()
    local priv = privTab[self]

    local ct = priv.last - priv.first
    if ct < 0 then return 0 end
    return ct + 1
end

function KQueue:PushLeft(value)
    KError.ValidateArg(1,"value",KVarCondition.NotNull(value))

    local priv = privTab[self]

    local first = priv.first - 1
    priv.first = first
    priv[first] = value
end

function KQueue:PushRight(value)
    KError.ValidateArg(1,"value",KVarCondition.NotNull(value))

    local priv = privTab[self]

    local last = priv.last + 1
    priv.last = last
    priv[last] = value
end

function KQueue:GetLeft()
    local priv = privTab[self]

    return priv[priv.first]
end

function KQueue:GetRight()
    local priv = privTab[self]

    return priv[priv.last]
end

function KQueue:PopLeft()
    local priv = privTab[self]

    local first = priv.first
    assert(priv.first <= priv.last,"list empty")
    local value = priv[first]
    priv[first] = nil
    priv.first = first + 1

    return value
end

function KQueue:PopRight()
    local priv = privTab[self]

    local last = priv.last
    assert(priv.first <= priv.last,"list empty")
    local value = priv[last]
    priv[last] = nil
    priv.last = last - 1

    return value
end

local noOp = function() return nil end

---Returns an iterator function for this queue.
function KQueue:Iterator()
    local priv = privTab[self]

    if priv.first > priv.last then return noOp end

    local curr = priv.first - 1
    return function()
        curr = curr + 1
        local val = priv[curr]
        if not val then return end
        return curr,val
    end
end