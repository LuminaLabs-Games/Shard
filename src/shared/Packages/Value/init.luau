local Signal = require(script.Parent.Signal)

local Value = {}
Value.__index = Value

local ValueSingleton = setmetatable({}, Value)

function Value.new(initialValue: any)
	local self = setmetatable({}, Value)

	self.Changed = Signal.new()
	self._value = initialValue

	return self
end

function Value:get()
	return self._value
end

function Value:set(value)
	self._value = value
	self.Changed:Fire(value)
end

function Value:observe(callback)
	local cleanFunction = nil
	local changedConnection = nil
	local changedId = 0

	local function OnValueChanged()
		if cleanFunction ~= nil then
			task.spawn(cleanFunction)
			cleanFunction = nil
		end

		changedId += 1
		local id = changedId

		task.spawn(function()
			local clean = callback(self._value)
			if id == changedId and changedConnection.Connected then
				cleanFunction = clean
			else
				task.spawn(clean)
			end
		end)
	end

	-- get changed values:
	changedConnection = self.Changed:Connect(OnValueChanged)

	-- get initial value:
	task.defer(function()
		if not changedConnection.Connected then
			return
		end
		OnValueChanged()
	end)

	return function()
		changedConnection:Disconnect()

		if cleanFunction ~= nil then
			task.spawn(cleanFunction)
			cleanFunction = nil
		end
	end
end

function Value:Destroy()
	self.Changed:Destroy()
	setmetatable(self, nil)
end

return setmetatable(Value, {
	__index = ValueSingleton,
	__call = function(_, initialValue: any)
		return Value.new(initialValue)
	end,
})
