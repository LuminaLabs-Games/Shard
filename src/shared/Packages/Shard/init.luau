local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local RunContext = RunService:IsServer() and "Server" or "Client"
local Config = require(script.Config)
local SimpleNet = require(script.Parent.SimpleNet)
local Log = require(script.Log)

local Module = {}
Module._services = {}
Module._controllers = {}
Module._serverInit = false
Module._serverStart = false
Module._clientInit = false
Module._clientStart = false
Module._isInitializing = false -- Track if we're currently in the init phase

-- Export the Log module for global access
Module.log = Log
Module.log.configure(Config.Logger)
Module.Player = RunContext == "Client" and Players.LocalPlayer or nil

function Module.new(name: string)
	if RunContext == "Server" then
		local service = require(script.ShardService).new(name)
		if not Module._services then
			Module._services = {}
		end

		Module._services[name] = {
			_module = service,
			_init = false,
			_start = false,
		}

		return service
	elseif RunContext == "Client" then
		local controller = require(script.ShardController).new(name)

		if not Module._controllers then
			Module._controllers = {}
		end

		Module._controllers[name] = {
			_module = controller,
			_init = false,
			_start = false,
		}

		return controller
	end

	warn(`SOMETHING WENT HORRIBLY WRONG: Attempted to create a Shard in an unsupported context: {RunContext}`)
	return nil
end

function Module.get(name: string)
	if RunContext == "Server" then
		-- During initialization phase, allow access to dependencies that have been initialized
		if Module._isInitializing then
			if Module._services[name] then
				local service = Module._services[name]
				if service._init then
					return service._module
				else
					-- Service exists but not yet initialized - this means circular dependency or wrong order
					warn(`Service '{name}' is not yet initialized. Check dependency order or circular dependencies.`)
					return nil
				end
			else
				warn(`Service '{name}' not found in Shard._services`)
				return nil
			end
		end

		-- Normal operation - wait for full initialization
		while not Module._serverInit and not Module._serverStart do
			task.wait()
		end

		if Module._services[name] then
			return Module._services[name]._module
		else
			warn(`Service '{name}' not found in Shard._services`)
			return nil
		end
	elseif RunContext == "Client" then
		-- During initialization phase, allow access to dependencies that have been initialized
		if Module._isInitializing then
			if Module._controllers[name] then
				local controller = Module._controllers[name]
				if controller._init then
					return controller._module
				else
					-- Controller exists but not yet initialized - this means circular dependency or wrong order
					warn(`Controller '{name}' is not yet initialized. Check dependency order or circular dependencies.`)
					return nil
				end
			else
				warn(`Controller '{name}' not found in Shard._controllers`)
				return nil
			end
		end

		-- Normal operation - wait for full initialization
		while not Module._clientInit and not Module._clientStart do
			task.wait()
		end

		if Module._controllers[name] then
			return Module._controllers[name]._module
		else
			warn(`Controller '{name}' not found in Shard._controllers`)
			return nil
		end
	end

	warn(`SOMETHING WENT HORRIBLY WRONG: Attempted to get a Shard in an unsupported context: {RunContext}`)
	return nil
end

function Module.init()
	if RunContext == "Server" then
		Module._isInitializing = true -- Set flag to indicate we're in init phase
		local bootTimes = {}
		if not Module._services then
			warn("No services found to initialize.")
			Module._isInitializing = false
			return
		end

		-- Sort services by dependencies
		local sortedServices = {}
		local function addServiceAndDependencies(serviceName, visited)
			if visited[serviceName] then
				return -- Already processed or circular dependency
			end
			visited[serviceName] = true

			local serviceData = Module._services[serviceName]
			if serviceData then
				-- Add dependencies first
				local dependencies = serviceData._module:getDependencies()
				for _, depName in dependencies do
					if Module._services[depName] then
						addServiceAndDependencies(depName, visited)
					else
						warn(`Service '{serviceName}' depends on '{depName}' which doesn't exist`)
					end
				end
				table.insert(sortedServices, serviceName)
			end
		end

		local visited = {}
		for serviceName, _ in Module._services do
			addServiceAndDependencies(serviceName, visited)
		end

		-- Initialize services in dependency order
		for _, serviceName in sortedServices do
			local service = Module._services[serviceName]
			local start = tick()
			if not service._init then
				service._module:_callInit()
				service._init = true
				if Config.VERBOSE_LOGGING then
					local elapsed = tick() - start
					bootTimes[serviceName] = tostring(elapsed)
					print(`Service '{serviceName}' initialized!`)
				end
			end
		end

		if Config.VERBOSE_LOGGING then
			print("All services initialized:", bootTimes)
		end
		Module._isInitializing = false -- Clear flag when done
		Module._serverInit = true
	elseif RunContext == "Client" then
		Module._isInitializing = true -- Set flag to indicate we're in init phase
		local bootTimes = {}
		if not Module._controllers then
			warn("No controllers found to initialize.")
			Module._isInitializing = false
			return
		end

		-- Sort controllers by dependencies
		local sortedControllers = {}
		local function addControllerAndDependencies(controllerName, visited)
			if visited[controllerName] then
				return -- Already processed or circular dependency
			end
			visited[controllerName] = true

			local controllerData = Module._controllers[controllerName]
			if controllerData then
				-- Add dependencies first
				local dependencies = controllerData._module:getDependencies()
				for _, depName in dependencies do
					if Module._controllers[depName] then
						addControllerAndDependencies(depName, visited)
					else
						warn(`Controller '{controllerName}' depends on '{depName}' which doesn't exist`)
					end
				end
				table.insert(sortedControllers, controllerName)
			end
		end

		local visited = {}
		for controllerName, _ in Module._controllers do
			addControllerAndDependencies(controllerName, visited)
		end

		-- Initialize controllers in dependency order
		for _, controllerName in sortedControllers do
			local controller = Module._controllers[controllerName]
			local start = tick()
			if not controller._init then
				controller._module:_callInit()
				controller._init = true
				if Config.VERBOSE_LOGGING then
					local elapsed = tick() - start
					bootTimes[controllerName] = tostring(elapsed)
					print(`Controller '{controllerName}' initialized!`)
				end
			end
		end

		if Config.VERBOSE_LOGGING then
			print("All controllers initialized:", bootTimes)
		end

		Module._isInitializing = false -- Clear flag when done
		Module._clientInit = true
	end
end

function Module.start()
	if RunContext == "Server" then
		local bootTimes = {}
		if not Module._services then
			warn("No services found to start.")
			return
		end
		for name, service in Module._services do
			local start = tick()
			if not service._start then
				service._module:_callStart()
				service._start = true
				if Config.VERBOSE_LOGGING then
					local elapsed = tick() - start
					bootTimes[name] = tostring(elapsed)
					print(`Service '{name}' started!`)
				end
			end
		end
		if Config.VERBOSE_LOGGING then
			print("All services started:", bootTimes)
		end
		Module._serverStart = true
	elseif RunContext == "Client" then
		local bootTimes = {}
		if not Module._controllers then
			warn("No controllers found to start.")
			return
		end

		for name, controller in Module._controllers do
			local start = tick()
			if not controller._start then
				controller._module:_callStart()
				controller._start = true
				if Config.VERBOSE_LOGGING then
					local elapsed = tick() - start
					bootTimes[name] = tostring(elapsed)
					print(`Controller '{name}' started!`)
				end
			end
		end

		if Config.VERBOSE_LOGGING then
			print("All controllers started:", bootTimes)
		end

		Module._clientStart = true
	end
end

--[=[
    Creates a global RemoteEvent that can be accessed by any service/controller
    @param name -- The name of the RemoteEvent
    @param callback -- Optional callback function
    @return RemoteEvent -- The wrapped RemoteEvent instance
]=]
function Module.createRemoteEvent(name: string, callback: any?)
	return SimpleNet:remoteEvent("Global_" .. name, callback)
end

--[=[
    Creates a global RemoteFunction that can be accessed by any service/controller
    @param name -- The name of the RemoteFunction
    @param callback -- Optional callback function
    @return RemoteFunction -- The wrapped RemoteFunction instance
]=]
function Module.createRemoteFunction(name: string, callback: any?)
	return SimpleNet:remoteFunction("Global_" .. name, callback)
end

--[=[
    Creates a global BindableEvent that can be accessed by any service/controller
    @param name -- The name of the BindableEvent
    @param callback -- Optional callback function
    @return BindableEvent -- The wrapped BindableEvent instance
]=]
function Module.createBindableEvent(name: string, callback: any?)
	return SimpleNet:bindableEvent("Global_" .. name, callback)
end

--[=[
    Creates a global BindableFunction that can be accessed by any service/controller
    @param name -- The name of the BindableFunction
    @param callback -- Optional callback function
    @return BindableFunction -- The wrapped BindableFunction instance
]=]
function Module.createBindableFunction(name: string, callback: any?)
	return SimpleNet:bindableFunction("Global_" .. name, callback)
end

--[=[
    Gets all registered services (server only)
    @return table -- Table of all services
]=]
function Module.getAllServices()
	if RunContext == "Server" then
		local services = {}
		for name, service in Module._services do
			services[name] = service._module
		end
		return services
	end
	warn("getAllServices can only be called on the server")
	return {}
end

--[=[
    Gets all registered controllers (client only)
    @return table -- Table of all controllers
]=]
function Module.getAllControllers()
	if RunContext == "Client" then
		local controllers = {}
		for name, controller in Module._controllers do
			controllers[name] = controller._module
		end
		return controllers
	end
	warn("getAllControllers can only be called on the client")
	return {}
end

--[=[
    Checks if a service/controller exists
    @param name -- The name to check
    @return boolean -- Whether the service/controller exists
]=]
function Module.exists(name: string)
	if RunContext == "Server" then
		return Module._services[name] ~= nil
	elseif RunContext == "Client" then
		return Module._controllers[name] ~= nil
	end
	return false
end

--[=[
    Gets services/controllers by tag
    @param tag -- The tag to search for
    @return table -- Array of services/controllers with the tag
]=]
function Module.getByTag(tag: string)
	local results = {}
	if RunContext == "Server" then
		for name, service in Module._services do
			if service._module:hasTag(tag) then
				table.insert(results, { name = name, module = service._module })
			end
		end
	elseif RunContext == "Client" then
		for name, controller in Module._controllers do
			if controller._module:hasTag(tag) then
				table.insert(results, { name = name, module = controller._module })
			end
		end
	end
	return results
end

--[=[
    Gets the dependency graph
    @return table -- Dependency information
]=]
function Module.getDependencyGraph()
	local graph = {}
	if RunContext == "Server" then
		for name, service in Module._services do
			graph[name] = service._module:getDependencies()
		end
	elseif RunContext == "Client" then
		for name, controller in Module._controllers do
			graph[name] = controller._module:getDependencies()
		end
	end
	return graph
end

--[=[
    Waits for a service/controller to be available
    @param name -- The name to wait for
    @param timeout -- Optional timeout in seconds
    @return module -- The service/controller module, or nil if timeout
]=]
function Module.waitFor(name: string, timeout: number?)
	local startTime = tick()
	timeout = timeout or 30 -- Default 30 second timeout

	while not Module.exists(name) do
		if tick() - startTime > timeout then
			warn(`Timed out waiting for {name}`)
			return nil
		end
		task.wait(0.1)
	end

	return Module.get(name)
end

--[=[
    Gets metrics from all services/controllers
    @return table -- Aggregated metrics data
]=]
function Module.getAllMetrics()
	local allMetrics = {}

	if RunContext == "Server" then
		for name, service in Module._services do
			if service._module.getMetrics then
				allMetrics[name] = service._module:getMetrics()
			end
		end
	elseif RunContext == "Client" then
		for name, controller in Module._controllers do
			if controller._module.getMetrics then
				allMetrics[name] = controller._module:getMetrics()
			end
		end
	end

	return allMetrics
end

--[=[
    Runs health checks on all services/controllers
    @return table -- Aggregated health check results
]=]
function Module.runAllHealthChecks()
	local allHealth = {
		timestamp = tick(),
		overall = true,
		services = {},
	}

	if RunContext == "Server" then
		for name, service in Module._services do
			if service._module.runHealthChecks then
				local health = service._module:runHealthChecks()
				allHealth.services[name] = health
				if health.enabled and not health.healthy then
					allHealth.overall = false
				end
			end
		end
	elseif RunContext == "Client" then
		for name, controller in Module._controllers do
			if controller._module.runHealthChecks then
				local health = controller._module:runHealthChecks()
				allHealth.services[name] = health
				if health.enabled and not health.healthy then
					allHealth.overall = false
				end
			end
		end
	end

	return allHealth
end

--[=[
    Gets framework performance statistics
    @return table -- Framework performance data
]=]
function Module.getFrameworkStats()
	local stats = {
		context = RunContext,
		initialized = if RunContext == "Server" then Module._serverInit else Module._clientInit,
		started = if RunContext == "Server" then Module._serverStart else Module._clientStart,
		serviceCount = 0,
		controllerCount = 0,
		memoryUsage = collectgarbage("count"),
		uptime = if Module._serverInit or Module._clientInit then tick() else 0,
	}

	if Module._services then
		stats.serviceCount = 0
		for _ in Module._services do
			stats.serviceCount += 1
		end
	end

	if Module._controllers then
		stats.controllerCount = 0
		for _ in Module._controllers do
			stats.controllerCount += 1
		end
	end

	return stats
end

--[=[
    Sets up automatic health monitoring for all services/controllers
    @param interval -- Check interval in seconds (default: 60)
]=]
function Module.startHealthMonitoring(interval: number?)
	interval = interval or 60

	local globalLog = Log.global()
	globalLog:info(`Starting health monitoring with {interval}s interval`)

	task.spawn(function()
		while true do
			task.wait(interval)

			local health = Module.runAllHealthChecks()
			if not health.overall then
				globalLog:warn("Framework health check failed", health.services)
			else
				globalLog:debug("Framework health check passed")
			end
		end
	end)
end

return Module
