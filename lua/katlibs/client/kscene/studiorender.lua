---@class VMatrix
local vm_meta = FindMetaTable("VMatrix")
local vm_GetTranslation = vm_meta.GetTranslation
---@class IMesh
local im_meta = FindMetaTable("IMesh")
local im_DrawSkinned = im_meta.DrawSkinned
local c_PushModelMatrix = cam.PushModelMatrix
local c_PopModelMatrix = cam.PopModelMatrix
local r_ComputeLighting = render.ComputeLighting
local r_SetModelLighting = render.SetModelLighting
local BOX_FRONT = BOX_FRONT
local BOX_BACK = BOX_BACK
local BOX_RIGHT = BOX_RIGHT
local BOX_LEFT = BOX_LEFT
local BOX_TOP = BOX_TOP
local BOX_BOTTOM = BOX_BOTTOM
local FRONT = Vector(1,0,0)
local BACK = Vector(-1,0,0)
local RIGHT = Vector(0,1,0)
local LEFT = Vector(0,-1,0)
local TOP = Vector(0,0,1)
local BOTTOM = Vector(0,0,-1)
local X = 1
local Y = 2
local Z = 3
local empty = {}

---@class _KSceneInternal
local internal = {}

local function getLighting(pos)
	local fr = r_ComputeLighting(pos,FRONT)
	local bk = r_ComputeLighting(pos,BACK)
	local rt = r_ComputeLighting(pos,RIGHT)
	local lt = r_ComputeLighting(pos,LEFT)
	local tp = r_ComputeLighting(pos,TOP)
	local bm = r_ComputeLighting(pos,BOTTOM)

	return
		fr[X],fr[Y],fr[Z],
		bk[X],bk[Y],bk[Z],
		rt[X],rt[Y],rt[Z],
		lt[X],lt[Y],lt[Z],
		tp[X],tp[Y],tp[Z],
		bm[X],bm[Y],bm[Z]
end

local function setLighting(pos)
	local frX,frY,frZ,bkX,bkY,bkZ,rtX,rtY,rtZ,ltX,ltY,ltZ,tpX,tpY,tpZ,bmX,bmY,bmZ = getLighting(pos)

	r_SetModelLighting(BOX_FRONT,frX,frY,frZ)
	r_SetModelLighting(BOX_BACK,bkX,bkY,bkZ)
	r_SetModelLighting(BOX_RIGHT,rtX,rtY,rtZ)
	r_SetModelLighting(BOX_LEFT,ltX,ltY,ltZ)
	r_SetModelLighting(BOX_TOP,tpX,tpY,tpZ)
	r_SetModelLighting(BOX_BOTTOM,bmX,bmY,bmZ)
end

function internal.DrawMesh(mesh,modelMatrix,boneTable)
	setLighting(vm_GetTranslation(modelMatrix))
	c_PushModelMatrix(modelMatrix)
	im_DrawSkinned(mesh,boneTable or empty,true)
	c_PopModelMatrix()
end

return internal