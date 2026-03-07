local ENTITY_CLASS = "kat_meshrenderbase"
local currMesh,currMaterial

do --entity singleton
	---@class Entity
	local ent_meta = FindMetaTable("Entity")
	local e_SetupBones = ent_meta.SetupBones
	local e_DrawModel = ent_meta.DrawModel
	local e_SetPos = ent_meta.SetPos
	local e_SetAngles = ent_meta.SetAngles
	---@class VMatrix
	local vm_meta = FindMetaTable("VMatrix")
	local vm_GetTranslation = vm_meta.GetTranslation
	local vm_GetAngles = vm_meta.GetAngles
	local cam_GetModelMatrix = cam.GetModelMatrix
	local IsValid = IsValid

	---@class KMeshRenderBase
	---CLIENT, STATIC<br/>
	---Class for drawing meshes with an entity draw call.
	KMeshRenderBase = {}

	local singleton
	---CLIENT, STATIC<br/>
	---Draw a mesh using an entity call with the specified arguments.
	---@param mesh IMesh
	---@param material IMaterial
	function KMeshRenderBase.DrawMesh(mesh,material)
		currMesh = mesh
		currMaterial = material

		local currMatrix = cam_GetModelMatrix()
		e_SetPos(singleton,vm_GetTranslation(currMatrix))
		e_SetAngles(singleton,vm_GetAngles(currMatrix))
		e_SetupBones(singleton)
		e_DrawModel(singleton)
	end

	hook.Add("Think","KMeshRenderBase",function()
		if IsValid(singleton) then return end

		singleton = ents.CreateClientside(ENTITY_CLASS)
		singleton:SetModel("models/props_c17/oildrum001.mdl")
		singleton:Spawn()
		singleton:Activate()
	end)
end

do --entity definition
	local ENT = {
		Type = "anim",
		Base = "base_anim",
		Author = "ember",
		Spawnable = false,
		Mins = Vector(-999999,-999999,-999999),
		Maxs = Vector(999999,999999,999999),
	}

	function ENT:Initialize()
		self:SetRenderBounds(self.Mins,self.Maxs)
		self:DrawShadow(false)
		self:SetNoDraw(true)
	end

	function ENT:GetRenderMesh()
		return { --this function demands a new table is made every call. what the fuck
			Mesh = currMesh,
			Material = currMaterial,
		}
	end

	scripted_ents.Register(ENT,ENTITY_CLASS)
end