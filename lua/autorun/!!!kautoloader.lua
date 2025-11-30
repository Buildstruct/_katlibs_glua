AddCSLuaFile()

KAutoLoader = {}

local function nop() end

local fileActions
if SERVER then
    fileActions = {
        sv = include,
        cl = AddCSLuaFile,
        sh = function(path)
            AddCSLuaFile(path)
            include(path)
        end,
    }
elseif CLIENT then
    fileActions = {
        sv = nop,
        cl = include,
        sh = include,
    }
end

local function addFile(file,directory,realm)
	if not realm then realm = string.lower(string.Left(file, 2)) end

    local action = fileActions[realm]
    action(directory .. file)
end

function KAutoLoader.IncludeDir(directory,optionalArgs)
    local searchFolder = optionalArgs.SearchFolder or "LUA"
    local realm = optionalArgs.Realm
    if realm then assert(fileActions[realm] ~= nil,"argument #2, optionalArgs.Realm: expected \"sv\",\"cl\",\"sh\"") end

	directory = directory .. "/"
	local files, directories = file.Find(directory .. "*",searchFolder)

	for _,v in ipairs(files) do
		if not string.EndsWith(v,".lua") then continue end
		addFile(v,directory,realm)
	end

	for _,v in ipairs(directories) do
		KAutoLoader.IncludeDir(directory .. v,optionalArgs)
	end
end

KAutoLoader.IncludeDir("_katlibs_glua/universal",{Realm = "sh"})
KAutoLoader.IncludeDir("_katlibs_glua/shared",{Realm = "sh"})
KAutoLoader.IncludeDir("_katlibs_glua/server",{Realm = "sv"})
KAutoLoader.IncludeDir("_katlibs_glua/client",{Realm = "cl"})