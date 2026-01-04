local classes = setmetatable({},{__mode = "k"})

local currObj

---@class KClass
---OOP implementation<br>
---Constructor returns initial table of private fields.
---@param constructor fun(...): table?
---@param inherit table?
---@param privateConstructor boolean?
---@return table class The newly defined class
---@return fun(privTab : table): table? getPriv A getter for the class's private table
---@return fun(privTab : table): table instantiate A factory for a new object
KClass = function(constructor,inherit,privateConstructor)
	constructor = constructor or function(...) end
	KError.ValidateArg(1,"constructor",KVarCondition.Function(constructor))

	if inherit then KError.ValidateArg(2,"params.Inherit",KVarCondition.Table(inherit)) end

	local privTab = setmetatable({},{__mode = "k"})
	local function getPriv(obj) return privTab[obj] end

	local class = {}
	classes[class] = true

	local function instantiate(_,...)
		local newObj = setmetatable({},{__index = class})
		currObj = newObj
		privTab[newObj] = constructor(...) or {}
		currObj = nil
		return newObj
	end

	setmetatable(class,{
		__index = inherit,
		__call = (privateConstructor ~= nil) and instantiate or nil,
	})

	function instantiate(...) return constructor(_,...) end

	return class,getPriv,instantiate
end

---Get the current public object being instantiated.<br>
---<b><u>Can only be called inside constructors!<u/><b/>
function KClass.GetSelf()
	return currObj
end