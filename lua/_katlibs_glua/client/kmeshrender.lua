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
---@class IMesh
local im_meta = FindMetaTable("IMesh")
---function is only on dev branch, does not exist in documentation yet
---@diagnostic disable-next-line: undefined-field
local im_DrawSkinned = im_meta.DrawSkinned or im_meta.Draw
local r_ModelMaterialOverride = render.ModelMaterialOverride
local IsValid = IsValid

local ENTITY_CLASS = "kat_meshrenderbase"
local currMesh,currMaterial,currBoneTable

do --entity singleton
	---@class KMeshRenderBase
	---CLIENT, STATIC<br/>
	---Class for drawing meshes using an entity draw call.<br/>
	---https://github.com/Facepunch/garrysmod-issues/issues/4070#issuecomment-761080930
	KMeshRenderBase = {}

	local singleton
	---CLIENT, STATIC<br/>
	---Draw a mesh with the specified arguments using an entity draw call.
	---@param mesh IMesh
	---@param material IMaterial
	function KMeshRenderBase.DrawMesh(mesh,material,boneTable)
		currMesh = mesh
		currMaterial = material
		currBoneTable = boneTable

		local currMatrix = cam_GetModelMatrix()
		e_SetPos(singleton,vm_GetTranslation(currMatrix))
		e_SetAngles(singleton,vm_GetAngles(currMatrix))
		e_SetupBones(singleton)
		e_DrawModel(singleton)
	end

	hook.Add("Think","KMeshRenderBase",function()
		if IsValid(singleton) then return end

		singleton = ents.CreateClientside(ENTITY_CLASS)
		singleton:SetModel("models/squad/sf_bars/sf_bar1.mdl")
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

	--TODO: None of this fuckass hacky bullshit needs be done if ENT:GetRenderMesh() is updated to actually pass a fucking bone table back
	local invisibleMesh = Mesh()
	invisibleMesh:BuildFromTriangles({
		{pos = Vector(0.000,0.000,0.000)},
		{pos = Vector(0.000,0.000,0.002)},
		{pos = Vector(0.000,0.002,0.000)},
	})

	local empty = {}
	function ENT:Draw()
		if not IsValid(currMesh) then return end
		r_ModelMaterialOverride(currMaterial)
		e_DrawModel(self)

		---function is only on dev branch, does not exist in documentation yet
		---@diagnostic disable-next-line: redundant-parameter
		im_DrawSkinned(currMesh,currBoneTable or empty,true)

		---documentation is straight up wrong
		---@diagnostic disable-next-line: missing-parameter
		r_ModelMaterialOverride()
	end

	function ENT:GetRenderMesh()
		return {Mesh = invisibleMesh, Material = currMaterial}
	end

	scripted_ents.Register(ENT,ENTITY_CLASS)
end