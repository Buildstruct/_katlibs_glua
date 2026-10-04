local t_insert = table.insert
local iscolor = IsColor
local isentity = isentity

local COLOR_RED = Color(255,0,0)
local COLOR_WHITE = Color(255,255,255)

local getPriv
---SHARED<br/>
---A log utility, branchable into subsystems.
---@class KLogger
---@overload fun(systemName: string): KLogger
KLogger,getPriv = KClass(function(systemName)
    return {
        SystemName = systemName
    }
end)

local function format(...)
    local result = {}
    local lastColor = COLOR_WHITE
    for i = 1,select("#",...) do
        local obj = select(i,...)
        if iscolor(obj) then
            lastColor = obj
            continue
        end

        --format player colors
        if isentity(obj) and obj:IsPlayer() then
            t_insert(result,team.GetColor(obj:Team()))
            t_insert(result,obj:Nick())
            t_insert(result,lastColor)
            continue
        end

        t_insert(result,obj)
    end

    return unpack(result)
end

---SHARED<br/>
---Log a message to console.
function KLogger:LogConsole(...)
    MsgC(COLOR_RED,"[",getPriv(self).SystemName,"] ",COLOR_WHITE,format(...))
    MsgC('\n')
end

if SERVER then return end

---CLIENT<br/>
---Log a message to chat.
function KLogger:LogChat(...)
    chat.AddText(COLOR_RED,"[",getPriv(self).SystemName,"] ",COLOR_WHITE,format(...))
end
