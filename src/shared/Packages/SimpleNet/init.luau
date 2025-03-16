local RunService = game:GetService("RunService")

local Client = script:WaitForChild("Client")
local Server = script:WaitForChild("Server")
local Bindable = script:WaitForChild("Bindable")

local SimpleNet = {}

type RemoteEvent = {
    Fire: (self: RemoteEvent, player: Player?, ...any?) -> RemoteEvent,
	FireServer: (self: RemoteEvent, ...any) -> RemoteEvent,
    FireAll: (self: RemoteEvent, ...any) -> RemoteEvent,
    FireFilter: (self: RemoteEvent, (player: Player) -> boolean, ...any) -> RemoteEvent,
    FireAllExcept: (self: RemoteEvent, player: Player, ...any) -> RemoteEvent,
    FireAllExceptFilter: (self: RemoteEvent, (player: Player) -> boolean, ...any) -> RemoteEvent,
    FireDelayed: (self: RemoteEvent, player: Player, number, ...any) -> RemoteEvent,
    Connect: (self: RemoteEvent, callback: (player: Player, ...any) -> ()) -> RemoteEvent,
    Destroy: (self: RemoteEvent) -> (),
}

type RemoteFunction = {
	Invoke: (...any) -> any,
	Destroy: () -> any,
	Connect: (self: RemoteFunction, callback: (any, ...any) -> ()) -> RemoteFunction,
}

type BindableEvent = {
	Fire: (...any) -> any,
	FireDelayed: (number, ...any) -> any,
	Connect: ((any) -> any) -> RBXScriptConnection,
	Destroy: () -> any,
}

type BindableFunction = {
	Invoke: (...any) -> any,
	Destroy: () -> any,
	Connect: ((...any) -> any) -> RBXScriptConnection,
}

function SimpleNet:remoteEvent(name: string): RemoteEvent
	local RunContext = RunService:IsServer() and Server or Client
	name = "RE/" .. name
	if RunService:IsServer() then
		local remoteEvent = script:FindFirstChild(name)
		if not remoteEvent then
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = name
			remoteEvent.Parent = script
		end
		return require(RunContext.RemoteEvent).new(remoteEvent)
	else
		local remoteEvent = script:WaitForChild(name, 10)
		if not remoteEvent then
			error("Failed to find RemoteEvent: " .. name, 2)
		end
		return require(RunContext.RemoteEvent).new(remoteEvent)
	end
end

function SimpleNet:remoteFunction(name: string): RemoteFunction
	local RunContext = RunService:IsServer() and Server or Client
	name = "RF/" .. name
	if RunService:IsServer() then
		local remoteFunction = script:FindFirstChild(name)
		if not remoteFunction then
			remoteFunction = Instance.new("RemoteFunction")
			remoteFunction.Name = name
			remoteFunction.Parent = script
		end
		return require(RunContext.RemoteFunction).new(remoteFunction)
	else
		local remoteFunction = script:WaitForChild(name, 10)
		if not remoteFunction then
			error("Failed to find RemoteFunction: " .. name, 2)
		end
		return require(RunContext.RemoteFunction).new(remoteFunction)
	end
end

function SimpleNet:bindableEvent(name: string)
	name = "BE/" .. name
	local bindableEvent = script:FindFirstChild(name)
	if not bindableEvent then
		bindableEvent = Instance.new("BindableEvent")
		bindableEvent.Name = name
		bindableEvent.Parent = script
	end
	return require(Bindable.BindableEvent).new(bindableEvent)
end

function SimpleNet:bindableFunction(name: string)
	name = "BF/" .. name
	local bindableFunction = script:FindFirstChild(name)
	if not bindableFunction then
		bindableFunction = Instance.new("BindableFunction")
		bindableFunction.Name = name
		bindableFunction.Parent = script
	end
	return require(Bindable.BindableFunction).new(bindableFunction)
end

return SimpleNet
