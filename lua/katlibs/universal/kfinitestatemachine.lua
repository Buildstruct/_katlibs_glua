local getPriv
---SHARED<br/>
---State machine implementation.
---@class KFiniteStateMachine
---@overload fun(states: KState[]): KFiniteStateMachine
KFiniteStateMachine,getPriv = KClass(function(states)
    local stateTable = {}

    for _,class in pairs(states) do
        local name = class:GetName()
        assert(name ~= nil,"State does not implement abstract GetName() method!")
        assert(stateTable[name] ~= nil,string.format("Duplicate state name [%s]!",name))
        stateTable[name] = class
    end

    return {
        StateTable = stateTable,
        --CurrentState
    }
end)

---SHARED<br/>
---Sets the current state of the statemachine.<br/>
---Pass nil as the name argument to stop execution of the statemachine.
---@param ... any Arguments to pass into the new state's constructor
---@param name? string
function KFiniteStateMachine:SetState(name,...)
    local priv = getPriv(self)
    local currState = priv.CurrentState
    if currState and currState.OnExit then currState:OnExit() end
    priv.CurrentState = nil

    if name == nil then return end

    local class = getPriv(self).StateTable[name]
    priv.CurrentState = class(...)
end

---SHARED<br/>
---Gets the current state object of the statemachine.
function KFiniteStateMachine:GetState()
    return getPriv(self).CurrentState
end