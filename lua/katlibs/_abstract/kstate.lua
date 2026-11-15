---@meta

---SHARED, ABSTRACT<br/>
---State class for use with KFiniteStateMachine.
---@class KState
KState = {}

---SHARED, ABSTRACT<br/>
---Defines the string used to switch to this state in a statemachine.
---@return string?
function KState:GetName() end

---SHARED, VIRTUAL<br/>
---Callback when leaving this state in a statemachine.
function KState:OnExit() end