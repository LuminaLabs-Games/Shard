local PlayerProfile = {}
PlayerProfile.__index = PlayerProfile

function PlayerProfile.new(player, profile, replica)
	local self = setmetatable({}, PlayerProfile)

	self._player = player
	self._profile = profile
	self._replica = replica

	self._profile:MessageHandler(function(message, processed)
		--[[```lua
		-- This is where you handle global updates, like gifting:
		if message[1] == "Gift" then
			local sender = message[2]
			local giftType = message[3]
			print(`gift received from {sender} of type {giftType}`)
		end

		processed()
		--]]
	end)

	return self
end

-- Define custom player profile functions here:

--[[```lua
-- Example:
function PlayerProfile:addCash(amount: number)
	if not self:IsActive() then return end -- Check if the profile is still active

	local retrieved = self:Get("Cash")
	local newAmount = retrieved + amount

	if newAmount < 0 then
		newAmount = 0
	end

	self:Set("Cash", newAmount)
end
```]]

-- INTERNAL API

function PlayerProfile:Get(path: string | { string }): any
	if not self:IsActive() then
		return
	end

	if typeof(path) == "string" then
		if self._profile.Data[path] ~= nil then
			return self._profile.Data[path]
		end
		return self:_getRecursive(path)
	elseif typeof(path) == "table" then
		local currentTable = self._profile.Data
		for _, key in path do
			if currentTable[key] == nil then
				return nil
			end
			currentTable = currentTable[key]
		end
		return currentTable
	end
	return nil
end

function PlayerProfile:_getRecursive(keyToGet: string, tableToSearch: {}): any
	tableToSearch = tableToSearch or self._profile.Data
	for key, value in tableToSearch do
		if key == keyToGet then
			return value
		end

		if typeof(value) == "table" then
			local result = self:_getRecursive(keyToGet, value)
			if result ~= nil then
				return result
			end
		end
	end

	return nil
end

function PlayerProfile:Set(path: string | { string }, value: any): any
	if not self:IsActive() then
		return nil
	end

	if typeof(path) == "string" then
		if self._profile.Data[path] ~= nil then
			self._replica:Set({ path }, value)
			return value
		end
		return if self:_setRecursive(path, value) then value else nil
	elseif typeof(path) == "table" then
		self._replica:Set(path, value)
		return value
	end

	return nil
end

function PlayerProfile:_setRecursive(keyToSet: string, valueToSet: any, tableToSearch: {}, path: { string })
	tableToSearch = tableToSearch or self._profile.Data
	path = path or {}

	for key, currentValue in tableToSearch do
		local newPath = { unpack(path) }
		table.insert(newPath, key)

		if key == keyToSet then
			-- tableToSearch[key] = valueToSet
			self._replica:Set(newPath, valueToSet)
			return true
		end

		if typeof(currentValue) == "table" then
			local result = self:_setRecursive(keyToSet, valueToSet, currentValue, newPath)
			if result then
				return true
			end
		end
	end

	return false
end

function PlayerProfile:Increment(currencyPath: string | { string }, amount: number): any
	local retrieved = self:Get(currencyPath)
	if retrieved == nil then
		return
	end

	local newAmount = retrieved + amount

	if newAmount < 0 then
		newAmount = 0
	end

	return self:Set(currencyPath, newAmount)
end

function PlayerProfile:Decrement(currencyPath: string | { string }, amount: number): any
	local retrieved = self:Get(currencyPath)
	if retrieved == nil then
		return
	end

	local newAmount = retrieved - amount

	if newAmount < 0 then
		newAmount = 0
	end

	return self:Set(currencyPath, newAmount)
end

function PlayerProfile:CanAfford(currencyPath: string | { string }, cost: number): boolean
	local currentAmount = self:Get(currencyPath) or 0
	return currentAmount >= cost
end

function PlayerProfile:GetPlayer()
	return self._player
end

function PlayerProfile:GetUserId()
	return self._userId
end

function PlayerProfile:GetProfile()
	return self._profile
end

function PlayerProfile:GetReplica()
	return self._replica
end

function PlayerProfile:IsActive()
	return self._profile:IsActive()
end


return PlayerProfile
