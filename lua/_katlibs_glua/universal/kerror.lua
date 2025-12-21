KError = {}

local isnumber = isnumber
local isstring = isstring
local istable = istable
local isentity = isentity
local IsValid = IsValid
local getmetatable = getmetatable
local s_format = string.format
local error = error

KVarCondition = {
	NotNull = function(val)
		return val ~= nil, "object"
	end,

	Number = function(val)
		return isnumber(val), "number"
	end,

	NumberGreater = function(val,compare)
		return isnumber(val) and val > compare, s_format("number > %d",compare)
	end,

	NumberLess = function(val,compare)
		return isnumber(val) and val < compare, s_format("number < %d",compare)
	end,

	NumberGreaterOrEqual = function(val,compare)
		return isnumber(val) and val >= compare, s_format("number >= %d",compare)
	end,

	NumberLessOrEqual = function(val,compare)
		return isnumber(val) and val <= compare, s_format("number <= %d",compare)
	end,

	NumberInRange = function(val,min,max)
		return isnumber(val) and val >= min and val <= max, s_format("%d <= number <= %d",min,max)
	end,

	String = function(val)
		return isstring(val), "string"
	end,

	StringNotEmpty = function(val)
		return isstring(val), "string (len > 0)"
	end,

	Table = function(val)
		return istable(val), "table"
	end,

	TableSequential = function(val)
		return istable(val) and table.IsSequential(val), "sequential table"
	end,

	TableMeta = function(val,compare,typeName)
		return istable(val) and getmetatable(val).__index == compare, typeName
	end,

	Bool = function(val)
		return isbool(val), "bool"
	end,

	Function = function(val)
		return isfunction(val), "function"
	end,

	Entity = function(val)
		return isentity(val) and IsValid(val), "valid entity"
	end,

	Player = function(val)
		return isentity(val) and IsValid(val) and val:IsPlayer(), "valid player"
	end,

	Color = function(val)
		return IsColor(val), "color"
	end,
}

function KError.ValidateArg(index,name,result,expectation)
	if result then return end
	error(s_format("arg #%i, [%s]: expected [%s].",index,name,expectation))
end

function KError.ValidateKVArg(index,name,kResult,kExpectation,vResult,vExpectation)
	if kResult and vResult then return end
	error(s_format("arg #%i, [%s]: expected key [%s], expected value [%s].",index,name,kExpectation,vExpectation))
end