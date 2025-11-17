# GitHub Copilot Instructions for Shard Framework

## Project Overview

Shard is a powerful, feature-rich Roblox game development framework that provides service/controller architecture with advanced features including networking, dependency injection, lifecycle management, feature flags, configuration management, performance monitoring, and health checks.

## Framework Architecture

### Core Concepts

1. **Services (Server-side)**: Business logic modules that run on the server
2. **Controllers (Client-side)**: UI and client logic modules that run on the client
3. **Lifecycle Management**: Two-phase initialization (init → start) with dependency resolution
4. **Method Chaining**: Fluent API design pattern for clean service configuration
5. **Dependency Injection**: Automatic resolution and initialization ordering

### File Structure

```
src/shared/Packages/Shard/
├── init.luau              # Main framework module
├── ShardService.luau      # Server-side service class
├── ShardController.luau   # Client-side controller class
├── Log.luau               # Logging system
├── Config.luau            # Framework configuration
└── ...
```

## Coding Standards

### Service/Controller Creation Pattern

Always use method chaining when creating services or controllers:

```lua
local MyService = Shard.new("MyService")
    :withConfig({
        setting1 = value1,
        setting2 = value2
    })
    :withFeatureFlags({
        featureName = true
    })
    :withProfiling({ enabled = true })
    :withHealthCheck({
        checkName = function()
            return true -- health check logic
        end
    })
    :withRemoteEvents({ "EventName" })
    :withDependencies({ "OtherService" })
    :withSignals({ "SignalName" })
    :withTags({ "tag1", "tag2" })
    :withLifecycle({
        init = function(self)
            -- Initialize resources, dependencies available
        end,
        start = function(self)
            -- Start operations, all services initialized
        end
    })
    :withCleanup(function()
        -- Cleanup resources
    end)
```

### Naming Conventions

- **Services**: Use `PascalCase` with "Service" suffix (e.g., `PlayerDataService`)
- **Controllers**: Use `PascalCase` with "Controller" suffix (e.g., `UIController`)
- **Remote Events**: Use `PascalCase` (e.g., `PlayerJoined`, `DataUpdated`)
- **Signals**: Use `PascalCase` (e.g., `DataLoaded`, `StateChanged`)
- **Feature Flags**: Use `camelCase` (e.g., `useNewAPI`, `enableCaching`)
- **Config Keys**: Use `camelCase` (e.g., `maxRetries`, `timeout`)

### Modern Luau Syntax

- **DO NOT use `ipairs()` or `pairs()`** - Use modern Luau generalized iteration instead:
  ```lua
  -- ❌ AVOID (deprecated)
  for i, v in ipairs(myArray) do end
  for k, v in pairs(myTable) do end
  
  -- ✅ CORRECT (modern Luau)
  for i, v in myArray do end
  for k, v in myTable do end
  ```

### Method Chaining Order (Recommended)

1. `withConfig()` - Configuration first
2. `withFeatureFlags()` - Feature flags second
3. `withProfiling()` - Profiling setup
4. `withHealthCheck()` - Health monitoring
5. `withRemoteEvents()` - Networking
6. `withRemoteFunctions()` - Networking functions
7. `withBindableEvents()` - Internal events
8. `withBindableFunctions()` - Internal functions
9. `withDependencies()` - Dependencies declaration
10. `withSignals()` - Signal setup
11. `withTags()` - Categorization
12. `withLifecycle()` - Lifecycle callbacks
13. `withCleanup()` - Cleanup logic (always last)

## Advanced Features Usage

### Configuration Management

```lua
-- Set configuration during creation
:withConfig({
    timeout = 10,
    maxRetries = 3,
    enabled = true
})

-- Access in lifecycle
init = function(self)
    local timeout = self:getConfig("timeout", 5) -- With default
    self:setConfig("enabled", false) -- Update at runtime
end
```

### Feature Flags

```lua
-- Define feature flags
:withFeatureFlags({
    useNewAPI = true,
    enableCaching = false,
    debugMode = true
})

-- Use in code
if self:isFeatureEnabled("useNewAPI") then
    -- Use new implementation
else
    -- Use legacy implementation
end
```

### Performance Profiling

```lua
-- Enable profiling
:withProfiling({
    enabled = true,
    trackMemory = true,
    trackExecution = true
})

-- Time operations
function MyService:processData()
    self:startTimer("dataProcess")
    -- Do work
    self:endTimer("dataProcess")
    
    -- Get metrics
    local metrics = self:getMetrics()
    -- metrics.metrics.dataProcess = { count, total, average, min, max }
end
```

### Health Monitoring

```lua
-- Define health checks
:withHealthCheck({
    databaseConnection = function()
        return database:isConnected()
    end,
    memoryUsage = function()
        return collectgarbage("count") < 100000
    end
}, 30) -- Check every 30 seconds

-- Run checks manually
local health = self:runHealthChecks()
if not health.healthy then
    self.log:warn("Service unhealthy", health.checks)
end
```

### Logging

```lua
-- Each service/controller has a logger
init = function(self)
    self.log:info("Service initializing")
    self.log:debug("Debug info", { key = "value" })
    self.log:warn("Warning message", { count = 10 })
    self.log:error("Error occurred", { error = "details" })
end

-- Configure global logging
Shard.log.configure({
    level = Shard.log.Level.DEBUG,
    includeTimestamp = true,
    includeLevel = true,
    includeService = true
})

-- Log levels: TRACE, DEBUG, INFO, WARN, ERROR, FATAL
```

## Dependency Management

### Declaring Dependencies

```lua
:withDependencies({ "DatabaseService", "ConfigService" })
```

### Accessing Dependencies

```lua
init = function(self)
    -- Dependencies are available in init phase
    local dbService = Shard.get("DatabaseService")
    local config = Shard.get("ConfigService")
end
```

### Dependency Rules

- Services can only depend on other services
- Controllers can only depend on other controllers
- Dependencies are automatically initialized in correct order
- Circular dependencies are not allowed

## Networking Patterns

### Remote Events (Client → Server or Server → Client)

```lua
:withRemoteEvents({
    "PlayerJoined",  -- Simple event
    { RequestData = function(player, dataType)  -- Event with callback
        return { data = "value" }
    end }
})

-- Fire from server
self:getRemoteEvent("PlayerJoined"):fireClient(player, data)

-- Fire from client
self:getRemoteEvent("RequestData"):fireServer("inventory")
```

### Remote Functions (Request/Response)

```lua
:withRemoteFunctions({
    { GetPlayerData = function(player, userId)
        return playerData[userId]
    end }
})

-- Invoke from client
local data = self:getRemoteFunction("GetPlayerData"):invokeServer(12345)
```

### Signals (Internal Communication)

```lua
:withSignals({ "DataUpdated", "StateChanged" })

-- Fire signal
self:getSignal("DataUpdated"):Fire(newData)

-- Connect to signal
self:getSignal("DataUpdated"):Connect(function(data)
    print("Data updated:", data)
end)
```

## Lifecycle Best Practices

### Init Phase

- Initialize data structures
- Set up dependencies
- Configure resources
- Do NOT start async operations
- Do NOT fire events
- Dependencies are available via `Shard.get()`

```lua
init = function(self)
    self.log:info("Initializing")
    self.players = {}
    self.config = self:getConfig("settings")
    
    -- Access dependencies
    local dbService = Shard.get("DatabaseService")
    self.database = dbService:getConnection()
end
```

### Start Phase

- Start async operations
- Begin monitoring loops
- Fire initialization complete signals
- All services/controllers are initialized

```lua
start = function(self)
    self.log:info("Starting")
    
    -- Start async work
    self:startAutoSave()
    self:monitorHealth()
    
    -- Notify ready
    self:getSignal("Ready"):Fire()
end
```

## Error Handling

Always use pcall for risky operations and log errors:

```lua
local success, result = pcall(function()
    return self:riskyOperation()
end)

if not success then
    self.log:error("Operation failed", { error = result })
    return nil
end
```

## Framework Initialization

In your game's main server/client script:

```lua
local Shard = require(path.to.Shard)

-- Configure logging
Shard.log.configure({
    level = Shard.log.Level.INFO
})

-- Initialize all services/controllers
Shard.init()

-- Start all services/controllers
Shard.start()

-- Optional: Start health monitoring
Shard.startHealthMonitoring(120) -- Check every 2 minutes
```

## Testing and Debugging

### Enable Debug Mode

```lua
:withFeatureFlags({ debugMode = true })
:withConfig({ verboseLogging = true })

if self:isFeatureEnabled("debugMode") then
    self.log:debug("Detailed debug info", data)
end
```

### Monitor Service Health

```lua
-- Get all metrics
local allMetrics = Shard.getAllMetrics()

-- Get all health status
local allHealth = Shard.runAllHealthChecks()

-- Get framework stats
local stats = Shard.getFrameworkStats()
```

### Service Status

```lua
function MyService:getStatus()
    return {
        metrics = self:getMetrics(),
        health = self:runHealthChecks(),
        config = {
            timeout = self:getConfig("timeout"),
            enabled = self:getConfig("enabled")
        },
        features = {
            newAPI = self:isFeatureEnabled("useNewAPI")
        }
    }
end
```

## Common Patterns

### Rate Limiting Pattern

```lua
function MyService:onRequest(player)
    if self:isRateLimited(player) then
        self.log:warn("Rate limit exceeded", { player = player.Name })
        return
    end
    
    self:startTimer("request")
    self:processRequest(player)
    self:endTimer("request")
end
```

### Feature Migration Pattern

```lua
function MyService:processData(data)
    if self:isFeatureEnabled("useNewProcessor") then
        return self:processDataV2(data)
    else
        return self:processDataV1(data)
    end
end
```

## Anti-Patterns to Avoid

❌ **Don't start async work in init phase**
```lua
init = function(self)
    task.spawn(function() -- WRONG!
        -- Async work
    end)
end
```

✅ **Do start async work in start phase**
```lua
start = function(self)
    task.spawn(function() -- CORRECT
        -- Async work
    end)
end
```

❌ **Don't create circular dependencies**
```lua
ServiceA:withDependencies({ "ServiceB" })
ServiceB:withDependencies({ "ServiceA" }) -- WRONG!
```

❌ **Don't access services before init**
```lua
local MyService = Shard.new("MyService")
local other = Shard.get("OtherService") -- WRONG! Too early
```

✅ **Do access services in lifecycle**
```lua
init = function(self)
    local other = Shard.get("OtherService") -- CORRECT
end
```

## Code Generation Guidelines

When generating Shard framework code:

1. Always use method chaining for clean, readable service definitions
2. Include appropriate logging statements at INFO level for major operations
3. Use feature flags for experimental or toggleable features
4. Add profiling timers for performance-critical operations
5. Include health checks for critical dependencies
6. Use configuration for environment-specific settings
7. Follow the lifecycle pattern strictly (init → start)
8. Include cleanup logic for resource management
9. Use descriptive names for services, events, and signals
10. Add error handling with proper logging

## Performance Considerations

- Disable profiling in production unless needed
- Use appropriate log levels (avoid TRACE/DEBUG in production)
- Health check intervals should be reasonable (30-120 seconds)
- Cache frequently accessed dependencies
- Use feature flags to disable expensive features
- Clean up resources in cleanup callbacks

## Documentation Standards

```lua
--[=[
    Processes player data with optional validation
    @param player -- The player instance
    @param data -- Data to process
    @param validate -- Whether to validate data (default: true)
    @return boolean -- Success status
]=]
function MyService:processPlayerData(player, data, validate)
    -- Implementation
end
```

---

For more information, see:
- `/ADVANCED_FEATURES.md` - Detailed feature documentation
- `/examples/` - Usage examples
- `/src/shared/Packages/Shard/` - Framework source code