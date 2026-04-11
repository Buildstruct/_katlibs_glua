---@class Entity
local ent_meta = FindMetaTable("Entity")
local e_SetPos = ent_meta.SetPos
local e_SetAngles = ent_meta.SetAngles
local e_SetupBones = ent_meta.SetupBones
local e_DrawModel = ent_meta.DrawModel
local e_EnableMatrix = ent_meta.EnableMatrix
---@class VMatrix
local vm_meta = FindMetaTable("VMatrix")
local vm_SetScale = vm_meta.SetScale
local vm_GetTranslation = vm_meta.GetTranslation
local vm_GetAngles = vm_meta.GetAngles
local vm_GetScale = vm_meta.GetScale

local cam_GetModelMatrix = cam.GetModelMatrix

local function modelExists(path)
	if string.find(path, "models/", 1, true) ~= 1 then return false end
	return file.Exists(path, "GAME")
end

---@class KAllocatedModel
---@field ClientsideEntity Entity
---@field Keys {[number] : boolean}

local allocatedModels = {}
local uidItr = 0

local getPriv
---CLIENT<br/>
---A wrapper class for clientside models that automatically handles memory management.
---@class KClientsideModel
---@overload fun(model: string): KClientsideModel
KClientsideModel,getPriv = KClass(function(model)
	KError.ValidateArg("model",KVarConditions.StringNotEmpty(model))
	assert(modelExists(model),"Model does not exist!")

	local allocatedModel = allocatedModels[model]
	if not allocatedModel then
		local csm = ClientsideModel(model)
		csm:SetNoDraw(true)
		allocatedModel = {
			ClientsideEntity = csm,
			Keys = {},
		}
		allocatedModels[model] = allocatedModel
	end

	uidItr = uidItr + 1
	local uid = uidItr
	allocatedModel.Keys[uid] = true

	return {
		UID = uid,
		Model = model,
		Keys = allocatedModel.Keys,
		ClientsideEntity = allocatedModel.ClientsideEntity,
	}
end,{
	Destructor = function(priv)
		local keys = priv.Keys
		keys[priv.UID] = nil
		if next(keys) then return end

		priv.ClientsideEntity:Remove()
		allocatedModels[priv.Model] = nil
	end,
})

local scaleMatrix = Matrix()
local defaultScale = Vector(1,1,1)

---CLIENT<br/>
---Draws the clientside model.<br/>
---@param flags STUDIO?
function KClientsideModel:Draw(flags)
	local csm = getPriv(self).ClientsideEntity

	local currMatrix = cam_GetModelMatrix()

	local scale = vm_GetScale(currMatrix)
	if scale ~= defaultScale then
		vm_SetScale(scaleMatrix,scale)
		e_EnableMatrix(csm,"RenderMultiply",scaleMatrix)
	end

	e_SetPos(csm,vm_GetTranslation(currMatrix))
	e_SetAngles(csm,vm_GetAngles(currMatrix))
	e_SetupBones(csm)
	e_DrawModel(csm,flags)
end

---CLIENT,STATIC<br/>
---Gets the a table of model strings for all active KClientsideModels.<br/>
function KClientsideModel.GetActiveList()
	return table.GetKeys(allocatedModels)
end