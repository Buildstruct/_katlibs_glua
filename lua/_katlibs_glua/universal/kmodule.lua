if KModule then KModule.DisposeAll() end

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

    local function removeLocalHook(hookType,hookName)
        local function removeGlobalHook()
            hook.Remove(hookType,"KModule")
        end

        removeChildTableKey(moduleHooks,hookType,hookName,removeGlobalHook)
        removeChildTableKey(localHooks,hookType,hookName)
    end

    local function reportError(trace)
        local traceback = debug.traceback(trace,5)
        hook.Run("KModuleError",moduleName,trace,traceback)
    end

    local function dispose()
        for hookType,tab in pairs(localHooks) do
            for hookName,_ in pairs(tab) do
                removeLocalHook(hookType,hookName)
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

    local function addLocalHook(hookType,hookName,callback)
        local function addGlobalHook(newTab)
            hook.Add(hookType,"KModule",function(...)
                for key,func in pairs(newTab) do
                    local worked,value
                    if isstring(key) then
                        worked,value = xpcall(func,onHookError,...)
                    elseif not IsValid(key) then
                        removeLocalHook(hookType,hookName)
                        continue
                    else
                        worked,value = xpcall(func,onHookError,key,...)
                    end

                    if worked and value ~= nil then
                        print("returning value to global hook",moduleName,hookType,hookName,value)
                        return value
                    end
                end
            end)
        end

        getOrAddChildTable(moduleHooks,hookType,addGlobalHook)[hookName] = callback
        getOrAddChildTable(localHooks,hookType)[hookName] = true
    end

    local env = setmetatable({
        hook = {
            Add = function(hookType,hookName,callback)
                addLocalHook(hookType,hookName,callback)
            end,

            Remove = function(hookType,hookName)
                removeLocalHook(hookType,hookName)
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

function KModule.DisposeAll()
    for _,v in pairs(activeModules) do
        v:Dispose()
    end
end