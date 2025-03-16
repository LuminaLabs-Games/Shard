local BindableEvent = {}
BindableEvent.__index = BindableEvent

function BindableEvent.new(bindableEvent: BindableEvent)
	local self = setmetatable({}, BindableEvent)

	self._bindableEvent = bindableEvent

	return self
end

function BindableEvent:Fire(...)
	self._bindableEvent:Fire(...)
end

function BindableEvent:FireDelayed(delay: number, ...)
	local args = { ... }
	task.delay(delay, function()
		self._bindableEvent:Fire(unpack(args))
	end)
end

function BindableEvent:Connect(callback: (...any) -> ())
	return self._bindableEvent.Event:Connect(callback)
end

function BindableEvent:Destroy()
	self._bindableEvent:Destroy()
end

return BindableEvent
