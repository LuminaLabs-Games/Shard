export type Queue = {
	_enqueue: { [number]: any },
	_processing: boolean,
	_interval: number,
	_batchSize: number,
	_callback: ((any) -> ())?,

	push: (self: Queue, object: any) -> (),
	pop: (self: Queue, amountToPop: number?) -> any | { [number]: any },
	find: (self: Queue, object: any) -> number?,
	clear: (self: Queue) -> (),
	count: (self: Queue) -> number,
	size: (self: Queue) -> number,
	peek: (self: Queue) -> any,
	IsEmpty: (self: Queue) -> boolean,
	Destroy: (self: Queue) -> (),
	add: (self: Queue, object: any) -> (),
	remove: (self: Queue, amountToRemove: number?) -> any | { [number]: any },
	isEmpty: (self: Queue) -> boolean,

	setInterval: (self: Queue, interval: number, batchSize: number, callback: (any) -> ()) -> (),
	startProcessing: (self: Queue) -> (),
	stopProcessing: (self: Queue) -> (),
}

local Queue = {}
Queue.__index = Queue

function Queue.new()
	local self = setmetatable({}, Queue)

	self._enqueue = {}
	self._processing = false
	self._interval = 1 -- Default to 1 second
	self._batchSize = 5 -- Default batch size
	self._callback = nil

	return self
end

function Queue:push(object: any)
	table.insert(self._enqueue, object)
	if not self._processing then
		self:startProcessing()
	end
end

function Queue:pop(amountToPop: number?)
	if not amountToPop then
		return table.remove(self._enqueue, 1)
	end

	local popped = {}
	for i = 1, amountToPop do
		if #self._enqueue == 0 then
			break
		end
		table.insert(popped, table.remove(self._enqueue, 1))
	end

	return popped
end

function Queue:find(object: any)
	for i = 1, #self._enqueue do
		if self._enqueue[i] == object then
			return i
		end
	end
	return nil
end

function Queue:clear()
	self._enqueue = {}
end

function Queue:count()
	return #self._enqueue
end

function Queue:size()
	return #self._enqueue
end

function Queue:peek()
	return self._enqueue[1]
end

function Queue:overview()
	return self._enqueue
end

function Queue:IsEmpty()
	return #self._enqueue == 0
end

function Queue:Destroy()
	self:stopProcessing()
	self._enqueue = nil
	setmetatable(self, nil)
end

-- ALIASES
function Queue:add(object: any)
	self:push(object)
end

function Queue:remove(amountToRemove: number?)
	return self:pop(amountToRemove)
end

function Queue:isEmpty()
	return self:IsEmpty()
end

-- PROCESSING SYSTEM
function Queue:setInterval(interval: number, batchSize: number, callback: (any) -> ())
	self._interval = interval or 1
	self._batchSize = batchSize or 5
	self._callback = callback
end

function Queue:startProcessing()
	if self._processing or not self._callback then
		return
	end
	self._processing = true

	task.spawn(function()
		while self._processing do
			if self:IsEmpty() then
				self._processing = false
				break
			end

			local batch = self:pop(self._batchSize)
			if type(batch) == "table" then
				for _, item in batch do
					self._callback(item)
				end
			else
				self._callback(batch)
			end

			task.wait(self._interval)
		end
	end)
end

function Queue:stopProcessing()
	self._processing = false
end

return Queue
