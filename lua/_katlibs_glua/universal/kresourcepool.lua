local m_min = math.min

local Tick_Regen

local regenerating = setmetatable({},{__mode = "k"})

local privTab = setmetatable({},{__mode = "k"})
KResourcePool = setmetatable({},{
    __index = base,
    __call = function(_,max,regenRatePerSecond)
        local newObj = setmetatable({},{__index = KResourcePool})
        privTab[newObj] = {
            Amount = max,
            Max = max,
            RegenRatePerTick = regenRatePerSecond * engine.TickInterval(),
        }
        return newObj
    end,
})

function KResourcePool:Use(cost)
    local priv = privTab[self]
    assert(isnumber(cost),"expected number")
    assert(cost >= 0,"expected cost >= 0")

    regenerating[priv] = true
    hook.Add("Tick","KResourcePool",Tick_Regen)

    local val = priv.Amount - cost
    if val < 0 then return false end
    priv.Amount = val

    return true
end

function Tick_Regen()
    if not next(regenerating) then
        hook.Remove("Tick","KResourcePool")
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