local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function RemoteEvent.new(remoteEvent: RemoteEvent)
	local self = setmetatable({}, RemoteEvent)

	self._remoteEvent = remoteEvent

	return self
end

function RemoteEvent:Fire(...)
	self._remoteEvent:FireServer(...)
end

function RemoteEvent:FireServer(...)
	self._remoteEvent:FireServer(...)
end

function RemoteEvent:FireDelayed(delay: number, ...)
	local args = { ... }
	task.delay(delay, function()
		self._remoteEvent:FireServer(unpack(args))
	end)
end

function RemoteEvent:Connect(callback: (player: Player, args: any) -> ())
	self._remoteEvent.OnClientEvent:Connect(function(player: Player, ...)
		callback(player, ...)
	end)
end

function RemoteEvent:Destroy()
	self._remoteEvent:Destroy()
end

return RemoteEvent
