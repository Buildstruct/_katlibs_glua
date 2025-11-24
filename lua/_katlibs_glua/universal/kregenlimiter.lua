local m_min = math.min

local Tick_Regen

local regenerating = setmetatable({},{__mode = "k"})
local privTab = setmetatable({},{__mode = "k"})

KRegenLimiter = setmetatable({},{
    __index = base,
    __call = function(_,max,regenRatePerSecond)
        local newObj = setmetatable({},{__index = KRegenLimiter})
        privTab[newObj] = {
            Amount = max,
            Max = max,
            RegenRatePerTick = regenRatePerSecond * engine.TickInterval(),
        }
        return newObj
    end,
})

function KRegenLimiter:Use(cost)
    local priv = privTab[self]
    assert(isnumber(cost),"expected number")
    assert(cost,"expected cost < 0")

    regenerating[priv] = true
    hook.Add("Tick","KRegenLimiter",Tick_Regen)

    local val = priv.Amount - cost
    if val < 0 then return false end
    priv.Amount = val

    return true
end

function Tick_Regen()
    if not next(regenerating) then
        hook.Remove("Tick","KRegenLimiter")
        return 
    end

    for priv,_ in pairs(regenerating) do
        local max = priv.Max
        local val = priv.Amount + priv.RegenRatePerTick

        if val > max then
            priv.Amount = max
            regenerating[priv] = nil
            continue
        end

        priv.Amount = m_min(val,max)
    end
end