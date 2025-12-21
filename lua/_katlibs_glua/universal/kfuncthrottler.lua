local privTab = setmetatable({},{__mode = "k"})

KFuncThrottler = setmetatable({},{
    __call = function(_,limiter)
        KError.ValidateArg(1,"limiter",KVarCondition.TableMeta(limiter,KRegenResourcePool,"KRegenResourcePool"))

        local newObj = setmetatable({},{__index = KFuncThrottler})
        privTab[newObj] = {
            Limiter = limiter,
            Queue = KQueue(),
        }
        return newObj
    end,
})

function KFuncThrottler:Execute(cost,func,...)
    local priv = privTab[self]
    local limiter = priv.Limiter
    local max = priv.Limiter:GetMax()
    KError.ValidateArg(1,"cost",KVarCondition.NumberInRange(cost,0,max))
    KError.ValidateArg(2,"func",KVarCondition.Function(func))

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

        local currCost = queued[1]
        if currCost > currVal then return end

        limiter:Use(currCost)
        queued[2](unpack(queued[3]))
        queue:PopLeft()
    end)
end