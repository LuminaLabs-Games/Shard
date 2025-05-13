export type Dispatcher = {
	new: () -> Dispatcher,
	Subscribe: (self: Dispatcher, event: string, callback: any, callbackName: string?) -> nil,
	subscribe: (self: Dispatcher, event: string, callback: any, callbackName: string?) -> nil,
	listen: (self: Dispatcher, event: string, callback: any, callbackName: string?) -> nil,
	Listen: (self: Dispatcher, event: string, callback: any, callbackName: string?) -> nil,
	SubscribeOnce: (self: Dispatcher, event: string, callback: any, callbackName: string?) -> nil,
	Unsubscribe: (self: Dispatcher, event: string, callbackName: string?) -> nil,
	unsubscribe: (self: Dispatcher, event: string, callbackName: string?) -> nil,
	Publish: (self: Dispatcher, event: string, payload: any) -> nil,
	publish: (self: Dispatcher, event: string, payload: any) -> nil,
	PublishDeferred: (self: Dispatcher, event: string, payload: any) -> nil,
	PublishNoYield: (event: string, payload: any) -> nil,
}

local Dispatcher = {}
Dispatcher.__index = Dispatcher

local DispatcherSingleton = setmetatable({}, Dispatcher)
DispatcherSingleton._events = {}

function Dispatcher.new()
	local self = setmetatable({}, Dispatcher)
	self._events = {}
	return self
end

function Dispatcher:_getEventTable()
	return self == Dispatcher and DispatcherSingleton._events or self._events
end

function Dispatcher:Subscribe(event: string, callback: any, callbackName: string?)
	local eventTable = self:_getEventTable()

	if not eventTable[event] then
		eventTable[event] = {}
	end

	if callbackName then
		eventTable[event][callbackName] = callback
	else
		table.insert(eventTable[event], callback)
	end

	return function()
		self:Unsubscribe(event, callbackName)
	end
end

function Dispatcher:subscribe(event: string, callback: any, callbackName: string?)
	return self:Subscribe(event, callback, callbackName)
end

function Dispatcher:listen(event: string, callback: any, callbackName: string?)
	return self:Subscribe(event, callback, callbackName)
end

function Dispatcher:Listen(event: string, callback: any, callbackName: string?)
	return self:Subscribe(event, callback, callbackName)
end

function Dispatcher:SubscribeOnce(event: string, callback: any, callbackName: string?)
	local function oneTimeCallback(...)
		self:Unsubscribe(event, callbackName)
		callback(...)
	end
	self:Subscribe(event, callbackName, oneTimeCallback)
end

function Dispatcher:Unsubscribe(event: string, callbackName: string?)
	local eventTable = self:_getEventTable()
	local eventListeners = eventTable[event]

	if not eventListeners then
		return
	end

	if callbackName then
		eventListeners[callbackName] = nil
	else
		eventTable[event] = nil
	end
end

function Dispatcher:unsubscribe(event: string, callbackName: string?)
	self:Unsubscribe(event, callbackName)
end

function Dispatcher:Publish(event: string, ...: any)
	local eventTable = self:_getEventTable()
	local eventListeners = eventTable[event]

	if not eventListeners then
		return
	end

	local results = {}

	for _, callback in eventListeners do
		local result = table.pack(callback(...))
		for i = 1, result.n do
			table.insert(results, result[i])
		end
	end

	if #results > 0 then
		return unpack(results)
	end

	return
end


function Dispatcher:PublishDeferred(event: string, ...: any)
	local args = { ... }
	task.defer(function()
		self:Publish(event, unpack(args))
	end)
end

function Dispatcher:publish(event: string, ...: any)
	self:Publish(event, ...)
end

function Dispatcher:PublishNoYield(event: string, ...: any)
	local eventTable = self:_getEventTable()
	local eventListeners = eventTable[event]

	if not eventListeners then
		return
	end

	for _, callback in eventListeners do
		task.spawn(callback, ...)
	end
end

return setmetatable(Dispatcher, {
	__index = DispatcherSingleton,
})
