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

function RemoteFunction:Destroy()
	self._remoteFunction:Destroy()
end

return RemoteFunction
