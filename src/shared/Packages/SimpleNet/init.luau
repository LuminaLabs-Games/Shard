local RunService = game:GetService("RunService")

local Client = script:WaitForChild("Client")
local Server = script:WaitForChild("Server")
local Bindable = script:WaitForChild("Bindable")

--[=[
    @class SimpleNet
    A networking utility module that provides a simplified interface for RemoteEvents, 
    RemoteFunctions, BindableEvents, and BindableFunctions.
]=]
local SimpleNet = {}

export type RemoteEvent = {
	--- **Server:** fires to the given player. **Client:** fires the server
	Fire: (self: RemoteEvent, player: Player?, ...any?) -> RemoteEvent,
	
	--- **Client Only:** fires the server
	FireServer: (self: RemoteEvent, ...any) -> RemoteEvent,
	
	--- **Server Only:** fires to the given player
	FireClient: (self: RemoteEvent, player: Player, ...any) -> RemoteEvent,

	--- **Server Only:** fires to all players in the game
	FireAll: (self: RemoteEvent, ...any) -> RemoteEvent,

	--- **Server Only:** fires to all players in the game
	FireAllClients: (self: RemoteEvent, ...any) -> RemoteEvent,

	--- **Server Only:** Fires to a subset of clients that match a filter
	FireFilter: (self: RemoteEvent, (player: Player) -> boolean, ...any) -> RemoteEvent,

	--- **Server Only:** Fires to all clients except the given player
	FireAllExcept: (self: RemoteEvent, player: Player, ...any) -> RemoteEvent,

	--- **Server Only:** Fires to all clients *except* those filtered out
	FireAllExceptFilter: (self: RemoteEvent, (player: Player) -> boolean, ...any) -> RemoteEvent,
	
	--- **Client Or Server:** Fires with a delay 
	FireDelayed: (self: RemoteEvent, player: Player, number, ...any) -> RemoteEvent,

	--- **Client Or Server:** Connects a function to be called when the event is fired. **Client**: No player argument in callback. **Server**: Player argument in callback 
	Connect: (self: RemoteEvent, callback: ContextualCallback) -> RemoteEvent,

	--- Cleans up the RemoteEvent
	Destroy: (self: RemoteEvent) -> (),
}

export type RemoteFunction = {
	--- **Client to Server:** Invokes the remote function (client to server)
	Invoke: (...any) -> any,

	--- **Client to Server:** Invokes the remote function (client to server)
	InvokeServer: (...any) -> any,

	--- **Client to Server:** Invokes the remote function after a delay (client to server)
	InvokeDelayed: (number, ...any) -> any,

    --- **Server Only:** Sets the callback for when the remote function is invoked
	Connect: (self: RemoteFunction, callback: (any, ...any) -> ()) -> RemoteFunction,

	--- **Server Only:** Sets the callback for when the remote function is invoked
	OnServerInvoke: (self: RemoteFunction, callback: (any, ...any) -> ()) -> RemoteFunction,
	
	--- Cleans up the RemoteFunction
	Destroy: () -> any,
}

export type BindableEvent = {
    --- Fires the event
    Fire: (self: BindableEvent, ...any) -> (),

    --- Fires the event after a delay
    FireDelayed: (self: BindableEvent, delay: number, ...any) -> (),

    --- Connects to the event
    Connect: (self: BindableEvent, callback: (...any) -> ()) -> RBXScriptConnection,

    --- Destroys the bindable event
    Destroy: (self: BindableEvent) -> ()
}


export type BindableFunction = {
    --- Calls the function
    Invoke: (self: BindableFunction, ...any) -> any,

    --- Calls the function after a delay
    InvokeDelayed: (self: BindableFunction, delay: number, ...any) -> (),

    --- Sets the function callback
    Connect: (self: BindableFunction, callback: (...any) -> any) -> (),
	
	--- Sets the function callback
    OnInvoke: (self: BindableFunction, callback: (...any) -> any) -> (),

    --- Destroys the bindable function
    Destroy: (self: BindableFunction) -> ()
}

export type ContextualCallback = (Player, ...any) -> () | (...any) -> ()

--[=[
    Creates or retrieves a RemoteEvent with the specified name.
    @param name -- The name of the RemoteEvent
    @param callback -- Optional callback function to connect to the RemoteEvent
    @return RemoteEvent -- The wrapped RemoteEvent instance
]=]
function SimpleNet:remoteEvent(name: string, callback: ContextualCallback?): RemoteEvent
	local RunContext = RunService:IsServer() and Server or Client
	name = "RE/" .. name

	local remoteEvent
	if RunService:IsServer() then
		remoteEvent = script:FindFirstChild(name)
		if not remoteEvent then
			remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = name
			remoteEvent.Parent = script
		end
	else
		remoteEvent = script:WaitForChild(name, 10)
		if not remoteEvent then
			error("Failed to find RemoteEvent: " .. name, 2)
		end
	end

	local wrapper = require(RunContext.RemoteEvent).new(remoteEvent)
	if callback then
		wrapper:Connect(callback)
	end

	return wrapper
end

--[=[
    Creates or retrieves a RemoteFunction with the specified name.
    @param name -- The name of the RemoteFunction
    @param callback -- Optional callback function to connect to the RemoteFunction
    @return RemoteFunction -- The wrapped RemoteFunction instance
]=]
function SimpleNet:remoteFunction(name: string, callback: ContextualCallback?): RemoteFunction
	local RunContext = RunService:IsServer() and Server or Client
	name = "RF/" .. name

	local remoteFunction
	if RunService:IsServer() then
		remoteFunction = script:FindFirstChild(name)
		if not remoteFunction then
			remoteFunction = Instance.new("RemoteFunction")
			remoteFunction.Name = name
			remoteFunction.Parent = script
		end
	else
		remoteFunction = script:WaitForChild(name, 10)
		if not remoteFunction then
			error("Failed to find RemoteFunction: " .. name, 2)
		end
	end

	local wrapper = require(RunContext.RemoteFunction).new(remoteFunction)
	if callback then
		wrapper:Connect(callback)
	end

	return wrapper
end

--[=[
    Creates or retrieves a BindableEvent with the specified name.
    @param name -- The name of the BindableEvent
    @param callback -- Optional callback function to connect to the BindableEvent
    @return BindableEvent -- The wrapped BindableEvent instance
]=]
function SimpleNet:bindableEvent(name: string, callback: ContextualCallback?): BindableEvent
	name = "BE/" .. name

	local bindableEvent = script:FindFirstChild(name)
	if not bindableEvent then
		bindableEvent = Instance.new("BindableEvent")
		bindableEvent.Name = name
		bindableEvent.Parent = script
	end

	local wrapper = require(Bindable.BindableEvent).new(bindableEvent)
	if callback then
		wrapper:Connect(callback)
	end

	return wrapper
end

--[=[
    Creates or retrieves a BindableFunction with the specified name.
    @param name -- The name of the BindableFunction
    @param callback -- Optional callback function to connect to the BindableFunction
    @return BindableFunction -- The wrapped BindableFunction instance
]=]
function SimpleNet:bindableFunction(name: string, callback: ContextualCallback?): BindableFunction
	name = "BF/" .. name

	local bindableFunction = script:FindFirstChild(name)
	if not bindableFunction then
		bindableFunction = Instance.new("BindableFunction")
		bindableFunction.Name = name
		bindableFunction.Parent = script
	end

	local wrapper = require(Bindable.BindableFunction).new(bindableFunction)
	if callback then
		wrapper:Connect(callback)
	end

	return wrapper
end

return SimpleNet
