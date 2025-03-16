local Signal = require(script.Parent.Signal)
local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new()
	local self = setmetatable({}, StateMachine)

	self.state = nil
	self.states = {}
	self.Changed = Signal.new()

	return self
end

function StateMachine:Add(stateName, state: { Complete: (any) -> any })
	if self.states[stateName] then
		error(`State {stateName} already exists`)
	end

	self.states[stateName] = state
end

function StateMachine:Remove(stateName)
	if not self.states[stateName] then
		error(`State {stateName} does not exist`)
	end

	self.states[stateName] = nil
end

function StateMachine:Enter(stateName, ...)
	if not self.states[stateName] then
		error(`State {stateName} does not exist`)
	end

	if self.state and self.state.Complete then
		self.state:Complete()
	end

	self.state = self.states[stateName]

	if self.state.Start then
		self.state:Start(...)
	end

	self.Changed:Fire(self.state)

	return self.state
end

function StateMachine:Exit()
	self.state = nil
	self.Changed:Fire(self.state)
end

return StateMachine
