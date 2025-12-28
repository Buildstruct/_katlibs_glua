local classes = setmetatable({},{__mode = "k"})

---OOP implementation<br>
---Constructor returns initial table of private fields.
---@param constructor fun(...): table?
---@param inherit table?
---@return table class The newly defined class
---@return fun(privTab : table): table? getPriv A getter for the class's private table
KClass = function(constructor,inherit)
	constructor = constructor or function(...) end
	KError.ValidateArg(1,"constructor",KVarCondition.Function(constructor))

	if inherit then KError.ValidateArg(2,"params.Inherit",KVarCondition.Table(inherit)) end

	local privTab = setmetatable({},{__mode = "k"})
	local function getPriv(obj) return privTab[obj] end

	local class = {}
	classes[class] = true

	setmetatable(class,{
		__index = inherit,
		__call = function(_,...)
			local newObj = setmetatable({},{__index = class})
			privTab[newObj] = constructor(...) or {}
			return newObj
		end,
	})

	return class,getPriv
end