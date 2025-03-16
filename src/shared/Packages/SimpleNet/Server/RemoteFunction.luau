local RemoteFunction = {}
RemoteFunction.__index = RemoteFunction

function RemoteFunction.new(remoteFunction: RemoteFunction, callback: (player: Player, args: any) -> ())
	local self = setmetatable({}, RemoteFunction)

	self._remoteFunction = remoteFunction

	self:Connect(callback)

	return self
end

function RemoteFunction:Connect(callback: (player: Player, args: any) -> ())
	self._remoteFunction.OnServerInvoke = function(player: Player, ...: any): ...any
		return callback(player, ...)
	end
end

function RemoteFunction:Destroy()
	self._remoteFunction:Destroy()
end

return RemoteFunction
