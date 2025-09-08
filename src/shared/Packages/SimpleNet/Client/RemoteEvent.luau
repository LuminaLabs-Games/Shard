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

function RemoteEvent:Connect(callback: (args: any) -> ())
	return self._remoteEvent.OnClientEvent:Connect(function(...)
		callback(...)
	end)
end

function RemoteEvent:Destroy()
	self._remoteEvent:Destroy()
end

return RemoteEvent
