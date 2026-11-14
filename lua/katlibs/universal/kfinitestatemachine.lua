do
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
        if priv.CurrentState then priv.CurrentState:OnExit() end
        priv.CurrentState = nil

        if name == nil then return end

        local class = getPriv(self).StateTable[name]
        priv.CurrentState = class(...)
    end
end

do
    local function noOp() end

    ---SHARED, ABSTRACT<br/>
    ---State class for use with KFiniteStateMachine.
    ---@class KState
    KState = KClass(nil,{AbstractConstructor = noOp})

    ---SHARED, ABSTRACT<br/>
    ---Defines the string used to switch to this state in a statemachine.
    ---@return string?
    function KState:GetName() end

    ---SHARED, VIRTUAL<br/>
    ---Callback when leaving this state in a statemachine.
    function KState:OnExit() end
end