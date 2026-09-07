---@class Vector
local v_meta = FindMetaTable("Vector")
local v_SetUnpacked = v_meta.SetUnpacked
local r_SuppressEngineLighting = render.SuppressEngineLighting
local r_SetLocalModelLights = render.SetLocalModelLights
local util_GetSunInfo = util.GetSunInfo

local SUN = 1
local X = 1
local Y = 2
local Z = 3
local SUN_DISTANCE = 99999999

---@class _KSceneInternal
local internal = {}

---@type {[string]: _KRenderPropertySet}
local propertySets = {}

---@type {[integer]: {[string]: boolean}}
local uidHashLookup = {}

local model = KClientsideModel("models/editor/air_node.mdl")
local function renderAllFunctions(functions)
    --Forces the source engine to recompute the color modulation on a material by using an entity draw call
    --This fucking sucks but I'm not sure how else to fix this issue.
    local st = SysTime()
    model:Draw()
    print((SysTime() - st) * 1e6)

    for _,func in pairs(functions) do
        func()
    end
end

local modelLights = {
    [SUN] = {
        type = MATERIAL_LIGHT_POINT,
        color = render.GetAmbientLightColor() * 0.1,
        pos = Vector(0,0,0),
        dir = Vector(0,0,0),
    }
}

local function updateGlobalModelLights()
    local sunInfo = util_GetSunInfo()
    if not sunInfo then return end
    local sunColor = sunInfo.sunColor
    local sunDirection = sunInfo.direction

    local sunLight = modelLights[SUN]
    v_SetUnpacked(sunLight.pos,sunColor.r * SUN_DISTANCE,sunColor.g * SUN_DISTANCE,sunColor.b * SUN_DISTANCE)
    v_SetUnpacked(sunLight.dir,-sunDirection[X],-sunDirection[Y],-sunDirection[Z])
end

hook.Add("PreRender","KScene",function()
    updateGlobalModelLights()
end)

hook.Remove("PostDrawOpaqueRenderables","KScene")
hook.Add("PreDrawOpaqueRenderables","KScene",function(_,_,drawingSkybox)
    if drawingSkybox then return end

    render.ModelMaterialOverride(nil)
    r_SuppressEngineLighting(true)
    r_SetLocalModelLights(modelLights)
    for _,propertySet in pairs(propertySets) do
        local renderPropertiesWrapper = propertySet.RenderPropertiesWrapper
        renderPropertiesWrapper(renderAllFunctions,propertySet.Opaque)
    end
    r_SetLocalModelLights(nil)
    r_SuppressEngineLighting(false)
end)

hook.Remove("PostDrawTranslucentRenderables","KScene")
hook.Add("PreDrawTranslucentRenderables","KScene",function(_,_,drawingSkybox)
    if drawingSkybox then return end

    render.ModelMaterialOverride(nil)
    r_SuppressEngineLighting(true)
    r_SetLocalModelLights(modelLights)
    for _,propertySet in pairs(propertySets) do
        local renderPropertiesWrapper = propertySet.RenderPropertiesWrapper
        renderPropertiesWrapper(renderAllFunctions,propertySet.Translucent)
    end
    r_SetLocalModelLights(nil)
    r_SuppressEngineLighting(false)
end)

---@class _KDrawGroup
---@field Meshes IMesh[]
---@field RenderProperties KRenderProperty
---@field StudioProperties KStudioProperty

---@param renderProperties KRenderProperty[]
local function getPropertySetOrNew(hash,renderProperties)
    local propertySet = propertySets[hash]
    if propertySet then return propertySet end

    local renderPropertiesWrapper = KRenderProperty.Compile(renderProperties)
    ---@class _KRenderPropertySet
    propertySet = {
        Opaque = {},
        Translucent = {},
        RenderPropertiesWrapper = renderPropertiesWrapper,
    }
    propertySets[hash] = propertySet
    return propertySet
end

---@param uid integer
local function getRegisteredHashesOrNew(uid)
    local registeredHashes = uidHashLookup[uid]
    if registeredHashes then return registeredHashes end
    registeredHashes = {}
    uidHashLookup[uid] = registeredHashes
    return registeredHashes
end

local switchAdd = {
    [RENDERGROUP_BOTH] = function(propertySet,uid,renderFunction)
        propertySet.Opaque[uid] = renderFunction
        propertySet.Translucent[uid] = renderFunction
    end,
    [RENDERGROUP_OPAQUE] = function(propertySet,uid,renderFunction)
        propertySet.Opaque[uid] = renderFunction
    end,
    [RENDERGROUP_TRANSLUCENT] = function(propertySet,uid,renderFunction)
        propertySet.Translucent[uid] = renderFunction
    end,
}

---@param uid integer
---@param renderProperties KRenderProperty[]
---@param renderGroup integer
---@param renderFunction fun()
function internal.AddToRenderStack(uid,renderProperties,renderGroup,renderFunction)
    local hash = KRenderProperty.GetUniqueHash(renderProperties)
    local propertySet = getPropertySetOrNew(hash,renderProperties)

    local switch = switchAdd[renderGroup]
    if switch then switch(propertySet,uid,renderFunction) end

    local registeredHashes = getRegisteredHashesOrNew(uid)
    registeredHashes[hash] = true
end

---@param uid integer
function internal.RemoveFromRenderStack(uid)
    local registeredHashes = getRegisteredHashesOrNew(uid)

    for hash,_ in pairs(registeredHashes) do
        local propertySet = propertySets[hash]

        local opaque = propertySet.Opaque
        propertySet.Opaque[uid] = nil

        local translucent = propertySet.Translucent
        propertySet.Translucent[uid] = nil

        if next(opaque) or next(translucent) then continue end
        propertySets[hash] = nil
    end

    uidHashLookup[uid] = nil
end

return internal