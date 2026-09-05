
local ENTITY_CLASS = "kat_meshrenderbase"
local INVISIBLE_MESH = Mesh()
INVISIBLE_MESH:BuildFromTriangles({
    {pos = Vector(0.000,0.000,0.000)},
    {pos = Vector(0.000,0.000,0.002)},
    {pos = Vector(0.000,0.002,0.000)},
})
local NO_MAT = Material("models/debug/debugwhite")

local empty = {}
---@class Entity
local ent_meta = FindMetaTable("Entity")
local e_SetupBones = ent_meta.SetupBones
local e_DrawModel = ent_meta.DrawModel
local e_EnableMatrix = ent_meta.EnableMatrix
local e_RemoveAllDecals = ent_meta.RemoveAllDecals
---@class IMesh
local im_meta = FindMetaTable("IMesh")
local im_DrawSkinned = im_meta.DrawSkinned
local c_PushModelMatrix = cam.PushModelMatrix
local c_PopModelMatrix = cam.PopModelMatrix

local currMesh,currModelMatrix,currBoneTable

---@class _KSceneInternal
local internal = {}

local hideMatrix = Matrix()
hideMatrix:SetScale(Vector(0,0,0))

local function drawOverride(ent)
	e_EnableMatrix(ent,"RenderMultiply",hideMatrix)
	e_DrawModel(ent)
	c_PushModelMatrix(currModelMatrix)
	im_DrawSkinned(currMesh,currBoneTable or empty,true)
	c_PopModelMatrix()
end

local testModel = KClientsideModel("models/props_junk/watermelon01.mdl")
---Draw a mesh with the specified arguments using an entity draw call.<br/>
---https://github.com/Facepunch/garrysmod-issues/issues/4070#issuecomment-761080930
---@param ent Entity
---@param mesh IMesh
---@param modelMatrix VMatrix
---@param boneTable VMatrix[]
function internal.DrawMesh(ent,mesh,modelMatrix,boneTable)
    currMesh = mesh
    currBoneTable = boneTable
	currModelMatrix = modelMatrix

	local temp = ent.RenderOverride
	ent.RenderOverride = drawOverride
	e_RemoveAllDecals(ent)
    e_SetupBones(ent)
    e_DrawModel(ent)
	ent.RenderOverride = temp
end

return internal