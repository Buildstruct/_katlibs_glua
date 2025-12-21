local m_min = math.min

local Tick_Regen
local regenerating = setmetatable({},{__mode = "k"})

local privTab = setmetatable({},{__mode = "k"})
KRegenResourcePool = setmetatable({},{
    __call = function(_,max,regenRatePerSecond)
        KError.ValidateArg(1,"max",KVarCondition.NumberGreaterOrEqual(max,0))
        KError.ValidateArg(2,"regenRatePerSecond",KVarCondition.NumberGreaterOrEqual(regenRatePerSecond,0))

        local newObj = setmetatable({},{__index = KRegenResourcePool})
        privTab[newObj] = {
            Amount = max,
            Max = max,
            RegenRatePerTick = regenRatePerSecond * engine.TickInterval(),
            Hooks = {},
        }
        return newObj
    end,
})

function KRegenResourcePool:Use(cost)
    local priv = privTab[self]
    KError.ValidateArg(1,"cost",KVarCondition.NumberGreaterOrEqual(cost,0))

    regenerating[priv] = true
    hook.Add("Tick","KRegenResourcePool",Tick_Regen)

    local val = priv.Amount - cost
    if val < 0 then return false end
    priv.Amount = val

    return true
end

function KRegenResourcePool:GetMax()
    return privTab[self].Max
end

function KRegenResourcePool:Count()
    return privTab[self].Amount
end

function KRegenResourcePool:SetHook(key,func)
    KError.ValidateArg(1,"key",KVarCondition.NotNull(key))
    if func ~= nil then KError.ValidateArg(2,"func",KVarCondition.Function(func)) end

    privTab[self].Hooks[key] = func
end

function Tick_Regen()
    if not next(regenerating) then
        hook.Remove("Tick","KRegenResourcePool")
        return
    end

    for priv,_ in pairs(regenerating) do
        local max = priv.Max
        local val = m_min(priv.Amount + priv.RegenRatePerTick,max)

        priv.Amount = val

        if val == max then regenerating[priv] = nil end

        for _,func in pairs(priv.Hooks) do
            func(val)
        end
    end
end