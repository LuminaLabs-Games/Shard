local Signal = require(script.Parent.Signal)

local Value = {}
Value.__index = Value

local ValueSingleton = setmetatable({}, Value)

function Value.new(arg: any)
	local self = setmetatable({}, Value)

	self.Changed = Signal.new()
	self.Value = arg

	return self
end

function Value:get()
	return self.Value
end

function Value:set(value)
	self.Value = value
	self.Changed:Fire(value)
end

return setmetatable(Value, {
	__index = ValueSingleton,
	__call = function(_, arg: any)
		return Value.new(arg)
	end,
})
