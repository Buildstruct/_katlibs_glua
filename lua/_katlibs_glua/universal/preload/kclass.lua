local unpack = unpack
local setmetatable = setmetatable
local rawset = rawset
local classInternalsLookup = setmetatable({},{__mode = "k"})

local function KVarCondition_KClass(class)
	return {classInternalsLookup[class] ~= nil,"KClass"}
end

local baseClassArgs,currObj
---SHARED<br>
---OOP implementation<br>
---@class KClass
---@overload fun(publicConstructor?: (fun(...): table), inheritedClass?: KClass) : (table, fun(any: any): table?)
KClass = setmetatable({},{
	__call = function(_,publicConstructor,inheritedClass)
		if publicConstructor then KError.ValidateArg("constructor",KVarCondition.Function(publicConstructor)) end
		if inheritedClass then KError.ValidateArg("inheritedClass",KVarCondition_KClass(inheritedClass)) end
		local classMetatable = {}
		local class = setmetatable({},classMetatable)

		local classInternals = {}
		classInternalsLookup[class] = classInternals

		local classPrivDirectory = setmetatable({},{__mode = "k"})

		local populateObjectPriv
		if inheritedClass then
			local inheritedInternals = classInternalsLookup[inheritedClass]
			classMetatable.__index = inheritedClass

			local inheritedPublicConstructor = inheritedInternals.PublicConstructor
			if not inheritedPublicConstructor then error("Cannot inherit from a KClass without a public constructor!") end

			local basePopulateObjectPriv = inheritedInternals.PopulateObjectPriv
			function populateObjectPriv(object,constructor,...)
				baseClassArgs = nil
				classPrivDirectory[object] = constructor(...)
				if not baseClassArgs then error("Failed to call KClass.CallBaseConstructor in inherited class!") end
				basePopulateObjectPriv(object,inheritedPublicConstructor,unpack(baseClassArgs))
			end

			classInternals.ParentClasses = setmetatable({
				[class] = true,
			},{
				__mode = "k",
				__index = inheritedInternals.ParentClasses
			})
		else
			function populateObjectPriv(object,constructor,...)
				classPrivDirectory[object] = constructor(...)
			end

			classInternals.ParentClasses = setmetatable({
				[class] = true,
			},{__mode = "k"})
		end

		classInternals.PopulateObjectPriv = populateObjectPriv

		local function getObjectFactory(constructor)
			return function(...)
				local object = setmetatable({},{__index = class})
				currObj = object
				populateObjectPriv(object,constructor,...)
				currObj = nil
				return object
			end
		end

		if publicConstructor then
			classInternals.PublicConstructor = publicConstructor

			local publicFactory = getObjectFactory(publicConstructor)
			classMetatable.__call = function(_,...)
				return publicFactory(...)
			end
		end

		rawset(classPrivDirectory,class,{
			GetFactory = getObjectFactory,
		})

		local function getPriv(obj)
			return classPrivDirectory[obj]
		end

		return class,getPriv
	end
})

---SHARED<br>
---Calls the baseclass constructor for inheritance.<br>
---<b><u>Can only be called inside constructors!<u/><b/>
function KClass.CallBaseConstructor(...)
	baseClassArgs = {...}
end

---SHARED<br>
---Get the current public object being instantiated.<br>
---<b><u>Can only be called inside constructors!<u/><b/>
function KClass.GetSelf()
	return currObj
end

---SHARED<br>
---Check if object is or is a derivative of a class.
function KClass.Is(object,comparisonClass)
	if not istable(object) then return false end

	local objectClass = getmetatable(object).__index
	if not objectClass then return false end

	local classInternals = classInternalsLookup[objectClass]
	if not classInternals.ParentClasses[comparisonClass] then return false end
	return true
end