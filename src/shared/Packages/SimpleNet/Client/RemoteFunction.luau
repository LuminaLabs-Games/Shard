local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new(remoteFunction: RemoteFunction)
	local self = setmetatable({}, RemoteFunction)

	self._remoteFunction = remoteFunction

	return self
end

function RemoteFunction:Invoke(...)
	return self._remoteFunction:InvokeServer(...)
end

function RemoteFunction:InvokeServer(...)
	return self._remoteFunction:InvokeServer(...)
end

function RemoteFunction:InvokeDelayed(delay: number, ...)
	local args = { ... }
	task.delay(delay, function()
		self._remoteFunction:InvokeServer(unpack(args))
	end)
end

function RemoteFunction:Destroy()
	self._remoteFunction:Destroy()
end

return RemoteFunction
