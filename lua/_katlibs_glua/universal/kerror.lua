KError = {}

local isnumber = isnumber
local isstring = isstring
local istable = istable
local isentity = isentity
local IsValid = IsValid
local getmetatable = getmetatable
local s_format = string.format
local assert = assert

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

	TableMeta = function(val,compare,typeName)
		return istable(val) and getmetatable(val).__index == compare, typeName
	end,

	Function = function(val)
		return isfunction(val), "function"
	end,

	Entity = function(val)
		return isentity(val) and IsValid(val), "entity"
	end,

	Player = function(val)
		return isentity(val) and IsValid(val) and val:IsPlayer(), "player"
	end,
}

function KError.ValidateArg(index,name,result,expectation)
	if result then return end
	error(s_format("arg #%i, %s: expected %s.",index,name,expectation))
end
local validateArg = KError.ValidateArg

function KError.ValidateParameter(index,tableName,key,result,expectation)
	assert(isstring(key),s_format("arg #%i, %s: expected key of type string, got %s.",index,tableName,key))
	validateArg(index,s_format("%s[%s]",tableName,key),result,expectation)
end