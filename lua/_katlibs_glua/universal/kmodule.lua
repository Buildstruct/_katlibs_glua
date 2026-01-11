local function getOrAddChildTable(parentTab,childTabKey,callbackIfAdd)
    local childTable = parentTab[childTabKey]
    if childTable ~= nil then return childTable end

    childTable = {}
    if callbackIfAdd then callbackIfAdd(childTable) end
    parentTab[childTabKey] = childTable
    return childTable
end

local function removeChildTableKey(parentTab,childTabKey,childKey,callbackIfChildTabEmpty)
    local childTable = parentTab[childTabKey]
    if not childTable then return end

    childTable[childKey] = nil
    if not table.IsEmpty(parentTab) then return end
    if not callbackIfChildTabEmpty then return end
    callbackIfChildTabEmpty()
end

local activeModules = {}
local moduleHooks = {}

local getPriv
---@class KModule
---A pcall wrapper for code that allows for modular code that can be stopped at any time.
---@overload fun(moduleName: string, entryPoint: fun(...)): KRegenResourcePool
---@return KModule KModule
KModule,getPriv = KClass(function(moduleName,entryPoint)
    if activeModules[moduleName] then activeModules[moduleName]:Dispose() end

    local this = KClass.GetSelf()
    activeModules[moduleName] = this
    local localHooks = {}
    local disposeCBs = {}

    local function removeHook(hookType,hookName)
        local function removeGlobalHook()
            hook.Remove(hookType,"KModule")
        end

        removeChildTableKey(moduleHooks,hookType,hookName,removeGlobalHook)
        removeChildTableKey(localHooks,hookType,hookName)
    end

    local function reportError(trace)
        local errMsg = string.format("[KModule] Error in module [%s]",moduleName)
        MsgC(Color(255,0,0),errMsg)
        MsgC(Color(255,100,100),string.format("\n%s\n",trace))
        hook.Run("KModule_Error",moduleName,trace)
    end

    local function dispose()
        for hookType,tab in pairs(localHooks) do
            for hookName,_ in pairs(tab) do
                removeHook(hookType,hookName)
            end
        end

        for key,func in pairs(disposeCBs) do
            if istable(key) and not IsValid(key) then continue end
            xpcall(func,reportError)
        end

        activeModules[this] = nil
    end

    local function onHookError(trace)
        dispose()
        reportError(trace)
    end

    local function addHook(hookType,hookName,callback)
        hookName = hookName

        local function addGlobalHook(newTab)
            hook.Add(hookType,"KModule",function(...)
                for _,func in pairs(newTab) do
                    local worked,value = xpcall(func,onHookError,...)
                    if worked and value ~= nil then return value end
                end
            end)
        end

        getOrAddChildTable(moduleHooks,hookType,addGlobalHook)[hookName] = callback
        getOrAddChildTable(localHooks,hookType)[hookName] = true
    end

    local env = setmetatable({
        hook = {
            Add = function(hookType,hookName,callback)
                addHook(hookType,hookName,callback)
            end,

            Remove = function(hookType,hookName)
                removeHook(hookType,hookName)
            end,

            Run = function(hookType,...)
                local hookTable = getOrAddChildTable(localHooks,hookType)
                local returns = {}
                for _,func in pairs(hookTable) do
                    table.insert(returns,func(...))
                    if #returns >= 6 then break end
                end
                return unpack(returns)
            end,
        },

        SetModuleDisposeCB = function(key,callback)
            if callback then KError.ValidateArg(1,"key",KVarCondition.Function(callback)) end
            disposeCBs[key] = callback
        end,
    },{__index = _G})

    setfenv(entryPoint,env)
    xpcall(entryPoint,onHookError)

    return {
        Name = moduleName,
        Dispose = dispose,
    }
end)

function KModule:GetName() return getPriv(self).Name end
function KModule:Dispose() getPriv(self).Dispose() end

function KModule.GetActiveModules()
    local result = {}
    for k,v in pairs(activeModules) do
        result[k] = v
    end

    return result
end