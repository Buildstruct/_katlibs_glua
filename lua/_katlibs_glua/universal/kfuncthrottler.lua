local privTab = setmetatable({},{__mode = "k"})

KFuncThrottler = setmetatable({},{
    __call = function(_,limiter)
        assert(getmetatable(limiter).__index == KRegenResourcePool,"arg #1, limiter: expected KRegenResourcePool")

        local newObj = setmetatable({},{__index = KFuncThrottler})
        privTab[newObj] = {
            Limiter = limiter,
            Queue = KQueue(),
        }
        return newObj
    end,
})

local function tryExecute(priv,cost,func,...)
    if not priv.Limiter:Use(cost) then return false end
    func(...)
    return true
end

function KFuncThrottler:Execute(cost,func,...)
    local priv = privTab[self]
    local limiter = priv.Limiter
    local max = priv.Limiter:GetMax()
    assert(isnumber(cost) and cost <= max,string.format("arg #1, cost: expected number <= %i",max))
    assert(isfunction(func),"arg #2, func: expected function")

    if limiter:Use(cost) then
        func(...)
        return
    end

    local queue = priv.Queue

    queue:PushRight({cost,func,{...}})
    limiter:SetHook(self,function(currVal)
        local queued = queue:GetLeft()
        if not queued then
            limiter:SetHook(self,nil)
            return
        end

        local cost = queued[1]
        if cost > currVal then return end

        limiter:Use(cost)
        queued[2](unpack(queued[3]))
        queue:PopLeft()
    end)
end