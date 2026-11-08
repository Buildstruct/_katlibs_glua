local MAX_CACHE_SIZE = 1.5e6
local MAX_BYTES_PER_SECOND = 10e3

local SYSTEM_NAME = "KNetStream"

local maxChunks = math.ceil(MAX_CACHE_SIZE / MAX_BYTES_PER_SECOND)
local systemSyncedToken = KSyncedToken.Reserve(SYSTEM_NAME)
local netChannel = KNetChannel(systemSyncedToken,MAX_BYTES_PER_SECOND,MAX_BYTES_PER_SECOND)

--SHARED, STATIC<br/>
--A static net stream implementation.
KNetStream = {}

do
    ---@param token KSyncedToken
    local function sendHeader(token,numChunks)
        net.WriteBool(true)
        token:WriteToNet()
        net.WriteUInt(numChunks,32)
    end

    local function sendChunk(chunk)
        net.WriteBool(false)
        net.WriteData(chunk)
    end

    ---SHARED,STATIC<br/>
    ---Queue data to be sent to the opposite realm.<br/>
    ---@param syncedToken KSyncedToken
    ---@param data string
    ---@param players? CRecipientFilter|Player|Player[]
    function KNetStream.Send(syncedToken,data,players)
        KError.ValidateArg("data",KVarConditions.String(data))

        local dataSize = #data
        assert(dataSize > 0,"Stream size cannot be 0!")

        local numChunks = math.ceil(dataSize / MAX_BYTES_PER_SECOND)
        if CLIENT then assert(dataSize < MAX_CACHE_SIZE,string.format("Stream size cannot exceed more than %s!",string.NiceSize(MAX_CACHE_SIZE))) end

        netChannel:Send(sendHeader,players,syncedToken,numChunks)
        for i = 0, numChunks - 1 do
            local curr = MAX_BYTES_PER_SECOND * i
            local chunkSize = math.min(dataSize - curr, MAX_BYTES_PER_SECOND)

            local chunk = data:sub(curr + 1, curr + chunkSize)
            netChannel:Send(sendChunk,players,chunk)
        end
    end
end


do
    local receivers = {}

    ---SHARED,STATIC<br/>
    ---Set a callback for when a stream is fully received from the opposite realm.<br/>
    ---@param syncedToken KSyncedToken
    ---@param callback fun(data : string, ply : Player?)?
    function KNetStream.Receive(syncedToken,callback)
        receivers[syncedToken] = callback
    end

    local streamData = {}
    local function getStreamData(ply)
        if SERVER then return streamData[ply] end
        return streamData
    end

    local function setStreamData(tab,ply)
        if SERVER then streamData[ply] = tab return end
        streamData = tab
    end

    if SERVER then
        hook.Add("PlayerDisconnected",SYSTEM_NAME,function(ply)
            setStreamData(nil,ply)
        end)
    end

    KNetChannel.Receive(systemSyncedToken,function(len,ply)
        local header = net.ReadBool()
        if header then
            local syncedToken = KSyncedToken.ReadFromNet()
            local numChunks = net.ReadUInt(32)

            if SERVER and (numChunks > maxChunks or numChunks <= 0) then
                setStreamData(nil,ply)
                error(string.format("KNetStream header number of chunks out of bounds! Exploiter? SID: %s",ply:SteamID()))
            end

            setStreamData({
                SyncedToken = syncedToken,
                NumChunks = numChunks,
                Chunks = {},
                CurrSize = 0,
            },ply)
        else --receive data
            local data = getStreamData(ply)
            if not data then return end

            local chunks = data.Chunks
            local chunkSize = math.floor((len - 1) / 8)

            if SERVER and chunkSize > MAX_BYTES_PER_SECOND then
                setStreamData(nil,ply)
                error(string.format("KNetStream received chunk is larger than the defined rate limit! Exploiter? SID: %s",ply:SteamID()))
            end

            local chunk = net.ReadData(chunkSize)
            table.insert(chunks,chunk)

            local totalSize = data.CurrSize + chunkSize
            data.CurrSize = totalSize

            if SERVER and totalSize > MAX_CACHE_SIZE then
                setStreamData(nil,ply)
                error(string.format("KNetStream cache is receiving more data than the defined limit! Exploiter? SID: %s",ply:SteamID()))
            end

            if #chunks >= data.NumChunks then
                local callback = receivers[data.SyncedToken]
                if callback then ProtectedCall(callback,table.concat(chunks),ply) end

                setStreamData(nil,ply)
            end
        end
    end)
end