local Players = game:GetService("Players")
local RemoteEvent = {}
RemoteEvent.__index = RemoteEvent

function RemoteEvent.new(remoteEvent: RemoteEvent)
	local self = setmetatable({}, RemoteEvent)

	self._remoteEvent = remoteEvent

	return self
end

function RemoteEvent:Fire(player: Player, ...: any): ()
	self._remoteEvent:FireClient(player, ...)
end

function RemoteEvent:FireClient(player: Player, ...: any): ()
	self._remoteEvent:FireClient(player, ...)
end

function RemoteEvent:FireAll(...: any): ()
	self._remoteEvent:FireAllClients(...)
end

function RemoteEvent:FireAllClients(...: any): ()
	self._remoteEvent:FireAllClients(...)
end

function RemoteEvent:FireFilter(filter: (player: Player) -> boolean, ...: any): ()
	for _, player in Players:GetPlayers() do
		if filter(player) then
			self._remoteEvent:FireClient(player, ...)
		end
	end
end

function RemoteEvent:FireAllExceptFilter(filter: (player: Player) -> boolean, ...: any): ()
	for _, player in Players:GetPlayers() do
		if not filter(player) then
			self._remoteEvent:FireClient(player, ...)
		end
	end
end

function RemoteEvent:FireAllExcept(player: Player, ...: any): ()
	for _, p in Players:GetPlayers() do
		if p ~= player then
			self._remoteEvent:FireClient(p, ...)
		end
	end
end

function RemoteEvent:FireDelayed(player: Player, delay: number, ...: any): ()
	local args = { ... }
	task.delay(delay, function()
		self._remoteEvent:FireClient(player, unpack(args))
	end)
end

function RemoteEvent:FireAllDelayed(delay: number, ...: any): ()
	local args = { ... }
	task.delay(delay, function()
		self._remoteEvent:FireAllClients(unpack(args))
	end)
end

function RemoteEvent:Connect(callback: (player: Player, args: any) -> ()): ()
	return self._remoteEvent.OnServerEvent:Connect(function(player: Player, ...: any): ()
		callback(player, ...)
	end)
end

function RemoteEvent:Destroy()
	self._remoteEvent:Destroy()
end

return RemoteEvent
