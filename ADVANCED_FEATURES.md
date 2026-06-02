# Shard Framework - Advanced Features

The Shard framework now includes powerful advanced features for configuration management, feature flags, performance monitoring, health checks, and structured logging.

## New Features Overview

### 🔧 Configuration Management (`withConfig`)
Manage service/controller settings with runtime configuration:

```lua
local MyService = Shard.new("MyService")
    :withConfig({
        timeout = 10,
        maxRetries = 3,
        debugEnabled = true
    })

-- Access configuration
local timeout = MyService:getConfig("timeout", 5) -- Default: 5
MyService:setConfig("debugEnabled", false) -- Update at runtime
```

### 🚩 Feature Flags (`withFeatureFlags`)
Toggle features on/off without code changes:

```lua
local MyService = Shard.new("MyService")
    :withFeatureFlags({
        useNewAPI = true,
        enableCaching = false,
        debugMode = true
    })

-- Check feature flags
if MyService:isFeatureEnabled("useNewAPI") then
    -- Use new API
else
    -- Use legacy API
end
```

### 📊 Performance Monitoring (`withProfiling`)
Track execution times and performance metrics:

```lua
local MyService = Shard.new("MyService")
    :withProfiling({
        enabled = true,
        trackMemory = true,
        trackExecution = true
    })

-- Time operations
MyService:startTimer("dataProcess")
-- ... do work ...
MyService:endTimer("dataProcess")

-- Get metrics
local metrics = MyService:getMetrics()
-- Returns: { enabled, metrics: { dataProcess: { count, total, average, min, max } } }
```

### 🏥 Health Monitoring (`withHealthCheck`)
Monitor service health with custom checks:

```lua
local MyService = Shard.new("MyService")
    :withHealthCheck({
        databaseConnection = function()
            return database:isConnected()
        end,
        memoryUsage = function()
            return collectgarbage("count") < 100000 -- Under 100MB
        end,
        responseTime = function()
            local start = tick()
            -- Test operation
            return (tick() - start) < 0.1 -- Under 100ms
        end
    }, 30) -- Check every 30 seconds

-- Run health checks
local health = MyService:runHealthChecks()
-- Returns: { enabled, timestamp, checks: {...}, healthy: boolean }
```

### 📝 Enhanced Logging (`Shard.log`)
Structured logging with levels, formatting, and history:

```lua
-- Configure global logging
Shard.log.configure({
    level = Shard.log.Level.DEBUG,
    includeTimestamp = true,
    includeLevel = true,
    includeService = true
})

-- Each service gets its own logger
MyService.log:info("Service started")
MyService.log:debug("Processing data", { count = 100, time = 0.5 })
MyService.log:warn("High memory usage", { usage = "85%" })
MyService.log:error("Operation failed", { error = "timeout" })

-- Global logging
local globalLog = Shard.log.global()
globalLog:info("Framework initialized")

-- Get log history
local history = Shard.log.getHistory(Shard.log.Level.INFO)
```

## Complete Example

```lua
local PlayerService = Shard.new("PlayerService")
    -- Configuration for runtime settings
    :withConfig({
        saveInterval = 30,
        maxPlayers = 50,
        timeout = 10
    })
    
    -- Feature flags for A/B testing and gradual rollouts
    :withFeatureFlags({
        useNewSaveFormat = true,
        enableCompression = false,
        debugMode = true
    })
    
    -- Performance monitoring
    :withProfiling({
        enabled = true,
        trackMemory = true,
        trackExecution = true
    })
    
    -- Health monitoring
    :withHealthCheck({
        playerCount = function()
            return #game.Players:GetPlayers() < 50
        end,
        saveSystem = function()
            return true -- Check if save system is working
        end
    }, 60) -- Check every minute
    
    -- Standard Shard features
    :withRemoteEvents({ "PlayerJoined", "PlayerLeft" })
    :withDependencies({ "DataService" })
    :withSignals({ "PlayerDataLoaded" })
    :withTags({ "core", "players" })
    
    :withLifecycle({
        init = function(self)
            self.log:info("Initializing PlayerService")
            
            -- Use configuration
            local maxPlayers = self:getConfig("maxPlayers", 20)
            self.log:debug("Max players set to", { max = maxPlayers })
            
            -- Check feature flags
            if self:isFeatureEnabled("debugMode") then
                self.log:debug("Debug mode enabled")
            end
            
            -- Start timing initialization
            self:startTimer("init")
        end,
        
        start = function(self)
            self:endTimer("init")
            self.log:info("PlayerService started")
            
            -- Show initialization metrics
            local metrics = self:getMetrics()
            if metrics.metrics.init then
                self.log:info("Init time", metrics.metrics.init)
            end
        end
    })
```

## Framework-Level Monitoring

```lua
-- Initialize framework
Shard.init()
Shard.start()

-- Start automatic health monitoring
Shard.startHealthMonitoring(120) -- Check every 2 minutes

-- Get framework-wide metrics
local allMetrics = Shard.getAllMetrics()
local allHealth = Shard.runAllHealthChecks()
local frameworkStats = Shard.getFrameworkStats()

print("Framework healthy:", allHealth.overall)
print("Memory usage:", frameworkStats.memoryUsage, "KB")
```

## Log Levels

- `TRACE` (1): Very detailed debug information
- `DEBUG` (2): Debug information for development
- `INFO` (3): General information about program execution
- `WARN` (4): Warning messages about potential issues
- `ERROR` (5): Error conditions that should be addressed
- `FATAL` (6): Critical errors that may cause program termination

## Method Chaining

All new methods support method chaining and can be combined with existing Shard features:

```lua
local MyService = Shard.new("MyService")
    :withConfig({ ... })
    :withFeatureFlags({ ... })
    :withProfiling({ ... })
    :withHealthCheck({ ... })
    :withRemoteEvents({ ... })
    :withDependencies({ ... })
    :withSignals({ ... })
    :withTags({ ... })
    :withLifecycle({ ... })
    :withCleanup({ ... })
```

## Best Practices

1. **Configuration**: Use config for settings that might change between environments
2. **Feature Flags**: Use for gradual rollouts, A/B testing, and emergency shutoffs
3. **Profiling**: Enable in development, use selectively in production
4. **Health Checks**: Monitor critical dependencies and resource usage
5. **Logging**: Use appropriate log levels and include contextual data

## Migration from Basic Shard

Existing services continue to work unchanged. Add advanced features incrementally:

```lua
-- Before
local MyService = Shard.new("MyService")
    :withRemoteEvents({ "Test" })

-- After - add advanced features gradually
local MyService = Shard.new("MyService")
    :withRemoteEvents({ "Test" })
    :withConfig({ enabled = true })  -- Add config
    :withProfiling()                 -- Add profiling
```

The framework is backward compatible and new features are opt-in.
