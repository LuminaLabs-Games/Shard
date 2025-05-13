local BindableFunction = {}
BindableFunction.__index = BindableFunction

function BindableFunction.new(bindableFunction: BindableFunction)
	local self = setmetatable({}, BindableFunction)

	self._bindableFunction = bindableFunction

	return self
end

function BindableFunction:Invoke(...)
	return self._bindableFunction:Invoke(...)
end

function BindableFunction:InvokeDelayed(delay: number, ...)
	local args = { ... }
	task.delay(delay, function()
		self._bindableFunction:Invoke(unpack(args))
	end)
end

function BindableFunction:Connect(callback: (...any) -> any)
	self._bindableFunction.OnInvoke = callback
end

function BindableFunction:OnInvoke(callback: (...any) -> any)
	self._bindableFunction.OnInvoke = callback
end

function BindableFunction:Destroy()
	self._bindableFunction:Destroy()
end

return BindableFunction
