local classes = setmetatable({},{__mode = "k"})

local currObj,baseClassArgs

---@class KClass
---OOP implementation<br>
---Constructor returns initial table of private fields.
---If inheriting, elements of constructor vararg are passed into baseclass
---@overload fun(constructor: (fun(...): table?), inherit: table?, privateConstructor : boolean?) : (table, (fun(obj : table): table?), fun(...): table)
KClass = setmetatable({},{
	__call = function(_,constructor,inherit,privateConstructor)
		constructor = constructor or function(...) end
		KError.ValidateArg(1,"constructor",KVarCondition.Function(constructor))

		if inherit then KError.ValidateArg(2,"params.Inherit",KVarCondition.Table(inherit)) end

		local privTab = setmetatable({},{__mode = "k"})
		local function getPriv(obj) return privTab[obj] end

		local class = {}
		classes[class] = true

		local function instantiate(...)
			local newObj = setmetatable({},{__index = class})
			currObj = newObj
			baseClassArgs = nil

			local constructorPriv = constructor(...) or {}

			if inherit then
				if not baseClassArgs then error("Failed to call baseclass constructor in inherited class!") end
				local priv = inherit(unpack(baseClassArgs))
				table.Merge(priv,constructorPriv,true)
				privTab[newObj] = priv
			else
				privTab[newObj] = constructorPriv
			end

			currObj = nil
			return newObj
		end

		setmetatable(class,{
			__index = inherit,
			__call = (privateConstructor == true) and nil or function(_,...) return instantiate(...) end,
		})

		return class,getPriv,instantiate
	end
})

---Get the current public object being instantiated.<br>
---<b><u>Can only be called inside constructors!<u/><b/>
function KClass.GetSelf()
	return currObj
end

---Calls the baseclass constructor for inheritance.<br>
---<b><u>Can only be called inside constructors!<u/><b/>
function KClass.CallBaseConstructor(...)
	baseClassArgs = {...}
end