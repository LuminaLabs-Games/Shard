local RunService = game:GetService("RunService")

local Trove = require(script.Parent.Trove)
local Cache = {}
Cache.__index = Cache

function Cache.new()
	local self = setmetatable({}, Cache)

	self._cache = {}
	self._lifetime = 60 -- Default to 60 seconds
	self._cacheSize = math.huge -- Default cache size

	self._trove = Trove.new()

	self:_setup()

	return self
end

function Cache:setLifetime(lifetime: number)
	self._lifetime = time
end

function Cache:setSize(size: number)
	self._cacheSize = size
end

function Cache:add(key: string, value: any, lifetime: number?)
	if value == nil then
		return nil
	end

	if #self._cache >= self._cacheSize then
		table.remove(self._cache, 1)
	end

	table.insert(
		self._cache,
		{ key = key, value = value, timeAdded = os.time(), lifetime = lifetime or self._lifetime }
	)

	return self._cache[#self._cache]
end

function Cache:clearExpired()
	local currentTime = os.time()
	for i = #self._cache, 1, -1 do
		local cache = self._cache[i]
		if currentTime - cache.timeAdded >= cache.lifetime then
			table.remove(self._cache, i)
		end
	end
end

function Cache:get(key: string, defaultValue: any?)
	for _, cache in self._cache do
		if cache.key == key then
			return cache.value
		end
	end

	return self:add(key, defaultValue)
end

function Cache:Destroy()
	self._trove:Destroy()

	self._cache = nil
	self._lifetime = nil
	self._cacheSize = nil

	setmetatable(self, nil)
end

function Cache:_setup()
	local lastCheck = 0
	self._trove:Add(RunService.Heartbeat:Connect(function()
		if os.time() - lastCheck >= self._lifetime / 3 then
			lastCheck = os.time()
			self:clearExpired()
		end
	end))
end

return Cache
