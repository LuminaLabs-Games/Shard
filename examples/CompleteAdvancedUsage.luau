--[=[
    Complete Advanced Features Usage Example
    
    This example shows how to properly use all the new advanced features:
    - withFeatureFlags: Toggle features on/off at runtime
    - withConfig: Service configuration management  
    - withProfiling: Performance monitoring and metrics
    - withHealthCheck: Service health monitoring
    - Enhanced logging with structured data
    
    To use this example:
    1. Place this file in your game
    2. Update the require path to point to your Shard installation
    3. Run Shard.init() and Shard.start() in your game's initialization
]=]

local Shard = require(script.Parent.Parent.src.shared.Packages.Shard)

-- Configure global logging to show debug information
Shard.log.configure({
	level = Shard.log.Level.DEBUG,
	includeTimestamp = true,
	includeLevel = true,
	includeService = true,
})

local globalLog = Shard.log.global()
globalLog:info("=== Advanced Shard Framework Example ===")

--[=[
    Example: Player Data Management Service
    Demonstrates all advanced features working together
]=]
local PlayerDataService = Shard
	.new("PlayerDataService")
	-- Configuration: Runtime settings for the service
	:withConfig({
		saveInterval = 30, -- Save player data every 30 seconds
		autosaveEnabled = true, -- Enable automatic saving
		maxRetries = 3, -- Retry failed saves up to 3 times
		timeout = 10, -- 10 second timeout for operations
		backupEnabled = true, -- Enable data backups
		compressionLevel = 1, -- Light compression for data
	})
	-- Feature Flags: Enable/disable features without code changes
	:withFeatureFlags({
		useNewSaveFormat = true, -- Use optimized save format
		enableCompression = false, -- Disable compression for now
		debugMode = true, -- Enable debug logging
		betaFeatures = false, -- Disable experimental features
		enableBackups = true, -- Enable backup system
		validateData = true, -- Validate data before saving
	})
	-- Profiling: Monitor performance and track metrics
	:withProfiling({
		enabled = true, -- Enable performance tracking
		trackMemory = true, -- Monitor memory usage
		trackExecution = true, -- Time method execution
	})
	-- Health Checks: Monitor service health
	:withHealthCheck({
		-- Database connectivity check
		databaseConnection = function()
			-- In real implementation, check actual database
			return math.random() > 0.05 -- 95% success rate
		end,

		-- Memory usage check
		memoryUsage = function()
			local memoryKB = collectgarbage("count")
			return memoryKB < 100000 -- Under 100MB
		end,

		-- Data integrity check
		dataIntegrity = function()
			-- Check if critical data structures are intact
			return true
		end,

		-- Performance check
		responseTime = function()
			local start = tick()
			-- Simulate operation
			task.wait(0.001)
			return (tick() - start) < 0.1 -- Under 100ms
		end,
	}, 30) -- Run health checks every 30 seconds
	-- Standard Shard features
	:withRemoteEvents({
		"PlayerDataChanged",
		"SaveCompleted",
		{
			GetPlayerData = function(player)
				local service = Shard.get("PlayerDataService")
				return service:getPlayerData(player)
			end,
		},
	})
	:withDependencies({ "DatabaseService" })
	:withSignals({ "DataLoaded", "DataSaved", "BackupCreated" })
	:withTags({ "core", "data", "persistence", "critical" })
	-- Lifecycle with advanced features
	:withLifecycle({
		init = function(self)
			self.log:info("Initializing PlayerDataService with advanced features")

			-- Log current configuration
			self.log:debug("Service configuration", {
				saveInterval = self:getConfig("saveInterval"),
				autosave = self:getConfig("autosaveEnabled"),
				maxRetries = self:getConfig("maxRetries"),
				backup = self:getConfig("backupEnabled"),
			})

			-- Log active feature flags
			self.log:debug("Feature flags", {
				newFormat = self:isFeatureEnabled("useNewSaveFormat"),
				compression = self:isFeatureEnabled("enableCompression"),
				debug = self:isFeatureEnabled("debugMode"),
				backups = self:isFeatureEnabled("enableBackups"),
			})

			-- Start initialization timer
			self:startTimer("initialization")

			-- Initialize data structures
			self.playerData = {}
			self.saveQueue = {}
			self.backupQueue = {}

			-- Initialize based on feature flags
			if self:isFeatureEnabled("enableBackups") then
				self.log:info("Backup system enabled")
				self.backupInterval = self:getConfig("backupInterval", 300) -- 5 minutes
			end
		end,

		start = function(self)
			self:endTimer("initialization")
			self.log:info("PlayerDataService started successfully")

			-- Show initialization metrics
			local metrics = self:getMetrics()
			if metrics.metrics.initialization then
				self.log:info("Initialization completed", {
					time = metrics.metrics.initialization.average,
					count = metrics.metrics.initialization.count,
				})
			end

			-- Start autosave if enabled
			if self:getConfig("autosaveEnabled") then
				self:startAutosave()
			end

			-- Start backup system if enabled
			if self:isFeatureEnabled("enableBackups") then
				self:startBackupSystem()
			end

			-- Run initial health check
			local health = self:runHealthChecks()
			self.log:info("Initial health check", {
				healthy = health.healthy,
				checks = health.checks,
			})
		end,
	})
	-- Cleanup resources when service is destroyed
	:withCleanup(function()
		local self = Shard.get("PlayerDataService")
		self.log:info("Shutting down PlayerDataService")

		-- Save any pending data
		if #self.saveQueue > 0 then
			self.log:warn(`Saving {#self.saveQueue} pending items before shutdown`)
		end

		-- Clear resources
		table.clear(self.playerData)
		table.clear(self.saveQueue)
	end)

-- Example methods that use the advanced features
function PlayerDataService:startAutosave()
	local interval = self:getConfig("saveInterval", 60)
	self.log:info(`Starting autosave with {interval}s interval`)

	task.spawn(function()
		while true do
			task.wait(interval)

			if self:isFeatureEnabled("debugMode") then
				self.log:trace("Running autosave cycle")
			end

			self:startTimer("autosave")
			local success = self:saveAllPlayerData()
			self:endTimer("autosave")

			if not success then
				self.log:error("Autosave failed")
			end

			-- Run health checks if due
			if self:shouldRunHealthChecks() then
				local health = self:runHealthChecks()
				if not health.healthy then
					self.log:warn("Health check failed during autosave", health)
				end
			end
		end
	end)
end

function PlayerDataService:saveAllPlayerData()
	local useNewFormat = self:isFeatureEnabled("useNewSaveFormat")
	local enableCompression = self:isFeatureEnabled("enableCompression")
	local validateData = self:isFeatureEnabled("validateData")
	local maxRetries = self:getConfig("maxRetries", 1)

	self.log:debug("Saving all player data", {
		playerCount = self:getPlayerCount(),
		newFormat = useNewFormat,
		compression = enableCompression,
		validation = validateData,
	})

	local saveCount = 0
	local errorCount = 0

	for playerId, data in self.playerData do
		local success = false
		local attempts = 0

		while not success and attempts < maxRetries do
			attempts += 1
			self:startTimer("playerSave")

			-- Validate data if enabled
			if validateData and not self:validatePlayerData(data) then
				self.log:warn(`Invalid data for player {playerId}`)
				break
			end

			-- Use different format based on feature flag
			local processedData = data
			if useNewFormat then
				processedData = self:convertToNewFormat(data)
			end

			-- Compress if enabled
			if enableCompression then
				processedData = self:compressData(processedData)
			end

			-- Simulate save operation
			task.wait(0.01)
			success = math.random() > 0.1 -- 90% success rate

			self:endTimer("playerSave")

			if success then
				saveCount += 1
			else
				errorCount += 1
				if attempts >= maxRetries then
					self.log:error(`Failed to save data for player {playerId} after {maxRetries} attempts`)
				end
			end
		end
	end

	self.log:info("Save operation completed", {
		saved = saveCount,
		errors = errorCount,
		total = saveCount + errorCount,
	})

	return errorCount == 0
end

function PlayerDataService:getPlayerData(player)
	if self:isFeatureEnabled("debugMode") then
		self.log:debug(`Retrieving data for {player.Name}`)
	end

	self:startTimer("dataRetrieval")

	-- Simulate data loading
	local data = self.playerData[player.UserId] or {
		level = 1,
		coins = 100,
		items = {},
		settings = {},
	}

	self:endTimer("dataRetrieval")

	return data
end

function PlayerDataService:validatePlayerData(data)
	-- Basic validation - ensure required fields exist
	return data and data.level and data.coins and data.items
end

function PlayerDataService:convertToNewFormat(data)
	-- Convert to optimized format
	return {
		v = 2, -- version
		l = data.level,
		c = data.coins,
		i = data.items,
		s = data.settings,
	}
end

function PlayerDataService:compressData(data)
	-- Mock compression - in real implementation use actual compression
	local compressed = tostring(data)
	return compressed
end

function PlayerDataService:getPlayerCount()
	local count = 0
	for _ in self.playerData do
		count += 1
	end
	return count
end

function PlayerDataService:startBackupSystem()
	local interval = self:getConfig("backupInterval", 300) -- 5 minutes
	self.log:info(`Starting backup system with {interval}s interval`)

	task.spawn(function()
		while true do
			task.wait(interval)

			if self:isFeatureEnabled("enableBackups") then
				self:startTimer("backup")
				self:createBackup()
				self:endTimer("backup")
			end
		end
	end)
end

function PlayerDataService:createBackup()
	self.log:info("Creating data backup")

	-- Simulate backup creation
	task.wait(0.1)

	self:getSignal("BackupCreated"):Fire({
		timestamp = tick(),
		playerCount = self:getPlayerCount(),
	})

	self.log:info("Backup created successfully")
end

-- Example method to get comprehensive service status
function PlayerDataService:getStatus()
	return {
		-- Performance metrics
		metrics = self:getMetrics(),

		-- Health status
		health = self:runHealthChecks(),

		-- Configuration
		config = {
			saveInterval = self:getConfig("saveInterval"),
			autosave = self:getConfig("autosaveEnabled"),
			maxRetries = self:getConfig("maxRetries"),
			backup = self:getConfig("backupEnabled"),
		},

		-- Feature flags
		features = {
			newFormat = self:isFeatureEnabled("useNewSaveFormat"),
			compression = self:isFeatureEnabled("enableCompression"),
			debug = self:isFeatureEnabled("debugMode"),
			backups = self:isFeatureEnabled("enableBackups"),
			validation = self:isFeatureEnabled("validateData"),
		},

		-- Runtime stats
		runtime = {
			playerCount = self:getPlayerCount(),
			queueSize = #self.saveQueue,
			uptime = tick(),
		},
	}
end

--[=[
    Example Client Controller
]=]
local UIController = Shard.new("UIController")
	:withConfig({
		refreshRate = 60, -- 60 FPS
		enableAnimations = true,
		theme = "dark",
	})
	:withFeatureFlags({
		showFPS = false,
		enableParticles = true,
		debugOverlay = false,
	})
	:withProfiling({ enabled = true })
	:withHealthCheck({
		frameRate = function()
			-- Check if frame rate is acceptable
			return true
		end,
	})
	:withTags({ "client", "ui" })

-- Example usage function
local function demonstrateFeatures()
	globalLog:info("=== Demonstrating Advanced Features ===")

	-- Wait for services to initialize
	task.wait(1)

	-- Get service status
	local playerService = Shard.get("PlayerDataService")
	if playerService then
		local status = playerService:getStatus()

		globalLog:info("PlayerDataService Status:")
		globalLog:info("- Health:", status.health)
		globalLog:info("- Performance:", status.metrics)
		globalLog:info("- Configuration:", status.config)
		globalLog:info("- Features:", status.features)
	end

	-- Demonstrate framework-wide monitoring
	local allMetrics = Shard.getAllMetrics()
	globalLog:info("Framework Metrics:", allMetrics)

	local allHealth = Shard.runAllHealthChecks()
	globalLog:info("Framework Health:", { overall = allHealth.overall })

	local stats = Shard.getFrameworkStats()
	globalLog:info("Framework Stats:", stats)
end

-- Initialize and start the framework
globalLog:info("Initializing Shard framework...")
Shard.init()
Shard.start()

-- Start framework health monitoring
Shard.startHealthMonitoring(120) -- Check every 2 minutes

-- Run demonstration
demonstrateFeatures()

return {
	PlayerDataService = PlayerDataService,
	UIController = UIController,
}
