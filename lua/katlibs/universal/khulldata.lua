local getPriv
---SHARED<br/>
---Serializable physics hull datatype and physics hull utility class.
---@class KHullData
---@overload fun(): KHullData
KHullData,getPriv = KClass(function() end)

local function copy(vectors)
    local result = {}
    for i = 1,#vectors do
        result[i] = Vector(vectors[i])
    end
    return result
end

---SHARED<br/>
---Adds a convex to the hull from an array of vertices.
---@param vertices Vector[]
function KHullData:AddConvexFromVertices(vertices)
    table.insert(getPriv(self),copy(vertices))
end

---SHARED<br/>
---Adds a convex to the hull from the definition of a rectangular prism.
---@param origin Vector
---@param angles Angle
---@param dimensions Vector
function KHullData:AddConvexFromRectangularPrism(origin,angles,dimensions)
    local w = dimensions.x
    local l = dimensions.y
    local h = dimensions.z

    local matrix = Matrix()
    matrix:SetTranslation(origin)
    matrix:SetAngles(angles)

    table.insert(getPriv(self),{
        matrix * Vector(w,l,h), matrix * Vector(w,-l,h),
        matrix * Vector(-w,l,h), matrix * Vector(-w,-l,h),

        matrix * Vector(w,l,-h), matrix * Vector(w,-l,-h),
        matrix * Vector(-w,l,-h), matrix * Vector(-w,-l,-h),
    })
end

---SHARED<br/>
---Initializes the physics hull on an entity.
---@return boolean success
---@param ent Entity
function KHullData:Apply(ent)
    if not ent:PhysicsInitMultiConvex(getPriv(self)) then return false end
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:EnableCustomCollisions()
    ent:PhysWake()
    return true
end

---SHARED, STATIC<br/>
---Write KHullData to a stream.
---@param stream KWriteStream
---@param hullData KHullData
---@param taskToken KTaskToken?
function KHullData.WriteToStream(stream,hullData,taskToken)
    local priv = getPriv(hullData)
    local convexCount = #priv
    stream:WriteUInt16(convexCount)

    local progress = 0
    for _,convex in pairs(priv) do
        local vertexCount = #convex
        stream:WriteUInt16(#convex)
        for i = 1,vertexCount do
            stream:WriteVectorF(convex[i])
        end

        progress = progress + 1
        if taskToken then taskToken:YieldAndReportProgress(progress / convexCount) end
    end
end

---SHARED, STATIC<br/>
---Read KHullData from a stream.
---@param stream KReadStream
---@param taskToken KTaskToken?
---@return KHullData
function KHullData.ReadFromStream(stream,taskToken)
    local new = KHullData()
    local priv = getPriv(new)

    local convexCount = stream:ReadUInt16()
    for i = 1,convexCount do
        local vertices = {}
        local vertexCount = stream:ReadUInt16()
        for j = 1,vertexCount do
            table.insert(vertices,stream:ReadVectorF())
        end

        table.insert(priv,vertices)
        if taskToken then taskToken:YieldAndReportProgress(i / convexCount) end
    end

    return new
end