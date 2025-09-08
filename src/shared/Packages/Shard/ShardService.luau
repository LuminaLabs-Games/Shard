local SimpleNet = require(script.Parent.Parent.SimpleNet)
local Signal = require(script.Parent.Parent.Signal)
local Log = require(script.Parent.Log)

local ShardService = {}
ShardService.__index = ShardService

function ShardService.new(name: string)
	local self = setmetatable({}, ShardService)
	self.name = name
	self._remoteEvents = {}
	self._remoteFunctions = {}
	self._bindableEvents = {}
	self._bindableFunctions = {}
	self._signals = {}
	self._dependencies = {}
	self._tags = {}
	self._cleanupTasks = {}
	self._lifecycle = {}
	self._featureFlags = {}
	self._config = {}
	self._profiling = {
		enabled = false,
		metrics = {},
		timers = {},
	}
	self._healthCheck = {
		enabled = false,
		checks = {},
		interval = 30,
		lastCheck = 0,
	}
	self.log = Log.new(name)

	return self
end

--[=[
    Creates RemoteEvents for this service with optional callbacks
    @param remotes -- Table of remote names or {name = callback} pairs
    @return self -- For method chaining
]=]
function ShardService:withRemoteEvents(remotes: { string | { [string]: any } })
	for _, remote in remotes do
		if type(remote) == "string" then
			self._remoteEvents[remote] = SimpleNet:remoteEvent(remote)
		elseif type(remote) == "table" then
			for name, callback in remote do
				self._remoteEvents[name] = SimpleNet:remoteEvent(name, callback)
			end
		end
	end
	return self
end

--[=[
    Creates RemoteFunctions for this service with optional callbacks
    @param remotes -- Table of remote names or {name = callback} pairs
    @return self -- For method chaining
]=]
function ShardService:withRemoteFunctions(remotes: { string | { [string]: any } })
	for _, remote in remotes do
		if type(remote) == "string" then
			self._remoteFunctions[remote] = SimpleNet:remoteFunction(remote)
		elseif type(remote) == "table" then
			for name, callback in remote do
				self._remoteFunctions[name] = SimpleNet:remoteFunction(name, callback)
			end
		end
	end
	return self
end

--[=[
    Creates BindableEvents for this service with optional callbacks
    @param bindables -- Table of bindable names or {name = callback} pairs
    @return self -- For method chaining
]=]
function ShardService:withBindableEvents(bindables: { string | { [string]: any } })
	for _, bindable in bindables do
		if type(bindable) == "string" then
			self._bindableEvents[bindable] = SimpleNet:bindableEvent(self.name .. "_" .. bindable)
		elseif type(bindable) == "table" then
			for name, callback in bindable do
				self._bindableEvents[name] = SimpleNet:bindableEvent(self.name .. "_" .. name, callback)
			end
		end
	end
	return self
end

--[=[
    Creates BindableFunctions for this service with optional callbacks
    @param bindables -- Table of bindable names or {name = callback} pairs
    @return self -- For method chaining
]=]
function ShardService:withBindableFunctions(bindables: { string | { [string]: any } })
	for _, bindable in bindables do
		if type(bindable) == "string" then
			self._bindableFunctions[bindable] = SimpleNet:bindableFunction(self.name .. "_" .. bindable)
		elseif type(bindable) == "table" then
			for name, callback in bindable do
				self._bindableFunctions[name] = SimpleNet:bindableFunction(self.name .. "_" .. name, callback)
			end
		end
	end
	return self
end

--[=[
    Gets a RemoteEvent by name
    @param name -- The name of the RemoteEvent
    @return RemoteEvent -- The RemoteEvent wrapper
]=]
function ShardService:getRemoteEvent(name: string)
	return self._remoteEvents[name]
end

--[=[
    Gets a RemoteFunction by name
    @param name -- The name of the RemoteFunction
    @return RemoteFunction -- The RemoteFunction wrapper
]=]
function ShardService:getRemoteFunction(name: string)
	return self._remoteFunctions[name]
end

--[=[
    Gets a BindableEvent by name
    @param name -- The name of the BindableEvent
    @return BindableEvent -- The BindableEvent wrapper
]=]
function ShardService:getBindableEvent(name: string)
	return self._bindableEvents[name]
end

--[=[
    Gets a BindableFunction by name
    @param name -- The name of the BindableFunction
    @return BindableFunction -- The BindableFunction wrapper
]=]
function ShardService:getBindableFunction(name: string)
	return self._bindableFunctions[name]
end

--[=[
    Destroys all network objects created by this service
]=]
function ShardService:destroy()
	-- Run cleanup tasks first
	for _, cleanupTask in self._cleanupTasks do
		local success, err = pcall(cleanupTask)
		if not success then
			warn(`Cleanup task failed for service {self.name}: {err}`)
		end
	end

	-- Destroy signals
	for _, signal in self._signals do
		if signal.Destroy then
			signal:Destroy()
		end
	end

	for _, remoteEvent in self._remoteEvents do
		remoteEvent:Destroy()
	end
	for _, remoteFunction in self._remoteFunctions do
		remoteFunction:Destroy()
	end
	for _, bindableEvent in self._bindableEvents do
		bindableEvent:Destroy()
	end
	for _, bindableFunction in self._bindableFunctions do
		bindableFunction:Destroy()
	end

	table.clear(self._remoteEvents)
	table.clear(self._remoteFunctions)
	table.clear(self._bindableEvents)
	table.clear(self._bindableFunctions)
	table.clear(self._signals)
	table.clear(self._dependencies)
	table.clear(self._tags)
	table.clear(self._cleanupTasks)
	table.clear(self._lifecycle)
	table.clear(self._featureFlags)
	table.clear(self._config)
	table.clear(self._profiling.metrics)
	table.clear(self._profiling.timers)
	table.clear(self._healthCheck.checks)
end

--[=[
    Sets up feature flags for this service
    @param flags -- Table of feature flag names and their values
    @return self -- For method chaining
]=]
function ShardService:withFeatureFlags(flags: { [string]: boolean })
	for name, enabled in flags do
		self._featureFlags[name] = enabled
	end
	return self
end

--[=[
    Sets up configuration for this service
    @param config -- Configuration table
    @return self -- For method chaining
]=]
function ShardService:withConfig(config: { [string]: any })
	for key, value in config do
		self._config[key] = value
	end
	return self
end

--[=[
    Enables profiling for this service
    @param options -- Profiling options
    @return self -- For method chaining
]=]
function ShardService:withProfiling(options: { enabled: boolean?, trackMemory: boolean?, trackExecution: boolean? }?)
	local opts = options or {}
	self._profiling.enabled = if opts.enabled ~= nil then opts.enabled else true
	self._profiling.trackMemory = if opts.trackMemory ~= nil then opts.trackMemory else false
	self._profiling.trackExecution = if opts.trackExecution ~= nil then opts.trackExecution else true
	self._profiling.metrics = {}
	self._profiling.timers = {}
	return self
end

--[=[
    Sets up health checks for this service
    @param checks -- Table of health check functions
    @param interval -- Check interval in seconds (default: 30)
    @return self -- For method chaining
]=]
function ShardService:withHealthCheck(checks: { [string]: () -> boolean }, interval: number?)
	self._healthCheck.enabled = true
	self._healthCheck.interval = interval or 30
	for name, checkFunc in checks do
		self._healthCheck.checks[name] = checkFunc
	end
	return self
end

--[=[
    Sets up lifecycle methods for this service
    @param lifecycle -- Table with init and/or start functions
    @return self -- For method chaining
]=]
function ShardService:withLifecycle(lifecycle: { init: ((any) -> ())?, start: ((any) -> ())? })
	if lifecycle.init then
		self._lifecycle.init = lifecycle.init
	end
	if lifecycle.start then
		self._lifecycle.start = lifecycle.start
	end
	return self
end

--[=[
    Creates custom signals for this service
    @param signalNames -- Table of signal names
    @return self -- For method chaining
]=]
function ShardService:withSignals(signalNames: { string })
	for _, signalName in signalNames do
		self._signals[signalName] = Signal.new()
	end
	return self
end

--[=[
    Sets dependencies for this service
    @param dependencies -- Table of service names this service depends on
    @return self -- For method chaining
]=]
function ShardService:withDependencies(dependencies: { string })
	self._dependencies = dependencies
	return self
end

--[=[
    Adds tags to this service for categorization
    @param tags -- Table of tag strings
    @return self -- For method chaining
]=]
function ShardService:withTags(tags: { string })
	for _, tag in tags do
		table.insert(self._tags, tag)
	end
	return self
end

--[=[
    Adds cleanup tasks to run when the service is destroyed
    @param cleanupTask -- Function to run on cleanup
    @return self -- For method chaining
]=]
function ShardService:withCleanup(cleanupTask: () -> ())
	table.insert(self._cleanupTasks, cleanupTask)
	return self
end

--[=[
    Checks if a feature flag is enabled
    @param name -- The name of the feature flag
    @return boolean -- Whether the flag is enabled
]=]
function ShardService:isFeatureEnabled(name: string)
	return self._featureFlags[name] or false
end

--[=[
    Gets a configuration value
    @param key -- The configuration key
    @param default -- Default value if key doesn't exist
    @return any -- The configuration value
]=]
function ShardService:getConfig(key: string?, default: any?)
	if key == nil and default == nil then
		return self._config
	end
	return if self._config[key] ~= nil then self._config[key] else default
end

--[=[
    Sets a configuration value
    @param key -- The configuration key
    @param value -- The value to set
]=]
function ShardService:setConfig(key: string, value: any)
	self._config[key] = value
end

--[=[
    Starts a profiling timer
    @param name -- The timer name
]=]
function ShardService:startTimer(name: string)
	if self._profiling.enabled and self._profiling.trackExecution then
		self._profiling.timers[name] = tick()
	end
end

--[=[
    Ends a profiling timer and records the metric
    @param name -- The timer name
]=]
function ShardService:endTimer(name: string)
	if self._profiling.enabled and self._profiling.trackExecution and self._profiling.timers[name] then
		local elapsed = tick() - self._profiling.timers[name]
		if not self._profiling.metrics[name] then
			self._profiling.metrics[name] = {
				count = 0,
				total = 0,
				average = 0,
				min = math.huge,
				max = 0,
			}
		end

		local metric = self._profiling.metrics[name]
		metric.count += 1
		metric.total += elapsed
		metric.average = metric.total / metric.count
		metric.min = math.min(metric.min, elapsed)
		metric.max = math.max(metric.max, elapsed)

		self._profiling.timers[name] = nil
		self.log:debug(`Timer '{name}' completed in {elapsed}s`)
	end
end

--[=[
    Gets profiling metrics
    @return table -- Profiling data
]=]
function ShardService:getMetrics()
	return {
		enabled = self._profiling.enabled,
		metrics = self._profiling.metrics,
		activeTimers = self._profiling.timers,
	}
end

--[=[
    Runs health checks
    @return table -- Health check results
]=]
function ShardService:runHealthChecks()
	if not self._healthCheck.enabled then
		return { enabled = false }
	end

	local results = {
		enabled = true,
		timestamp = tick(),
		checks = {},
		healthy = true,
	}

	for name, checkFunc in self._healthCheck.checks do
		local success, result = pcall(checkFunc)
		results.checks[name] = {
			passed = success and result,
			error = if not success then result else nil,
		}

		if not (success and result) then
			results.healthy = false
			self.log:warn(
				`Health check '{name}' failed`,
				{ error = if not success then result else "check returned false" }
			)
		end
	end

	self._healthCheck.lastCheck = tick()
	return results
end

--[=[
    Checks if service should run health checks
    @return boolean -- Whether checks should run
]=]
function ShardService:shouldRunHealthChecks()
	if not self._healthCheck.enabled then
		return false
	end

	local timeSinceLastCheck = tick() - self._healthCheck.lastCheck
	return timeSinceLastCheck >= self._healthCheck.interval
end

--[=[
    Gets a signal by name
    @param name -- The name of the signal
    @return Signal -- The signal instance
]=]
function ShardService:getSignal(name: string)
	return self._signals[name]
end

--[=[
    Gets the dependencies of this service
    @return table -- Array of dependency names
]=]
function ShardService:getDependencies()
	return self._dependencies
end

--[=[
    Gets the tags of this service
    @return table -- Array of tag strings
]=]
function ShardService:getTags()
	return self._tags
end

--[=[
    Checks if this service has a specific tag
    @param tag -- The tag to check for
    @return boolean -- Whether the service has the tag
]=]
function ShardService:hasTag(tag: string)
	for _, serviceTag in self._tags do
		if serviceTag == tag then
			return true
		end
	end
	return false
end

--[=[
    Calls the lifecycle init method if it exists
]=]
function ShardService:_callInit()
	if self._lifecycle.init then
		self._lifecycle.init(self)
	elseif self.init then
		self:init()
	end
end

--[=[
    Calls the lifecycle start method if it exists
]=]
function ShardService:_callStart()
	if self._lifecycle.start then
		self._lifecycle.start(self)
	elseif self.start then
		self:start()
	end
end

return ShardService
