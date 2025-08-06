--[=[
    Shard Framework Logging System
    Provides structured logging with levels, formatting, and filtering
]=]

local Log = {}
Log.__index = Log

-- Log levels
Log.Level = {
	TRACE = 1,
	DEBUG = 2,
	INFO = 3,
	WARN = 4,
	ERROR = 5,
	FATAL = 6,
}

Log.LevelNames = {
	[1] = "TRACE",
	[2] = "DEBUG",
	[3] = "INFO",
	[4] = "WARN",
	[5] = "ERROR",
	[6] = "FATAL",
}

-- Default configuration
local defaultConfig = {
	level = Log.Level.INFO,
	includeTimestamp = true,
	includeLevel = true,
	includeService = true,
	dateFormat = "%H:%M:%S",
	colors = {
		[Log.Level.TRACE] = "🔍",
		[Log.Level.DEBUG] = "🐛",
		[Log.Level.INFO] = "ℹ️",
		[Log.Level.WARN] = "⚠️",
		[Log.Level.ERROR] = "❌",
		[Log.Level.FATAL] = "💀",
	},
}

local logConfig = table.clone(defaultConfig)
local logHistory = {}
local maxHistorySize = 1000

--[=[
    Creates a new logger instance for a service/controller
    @param serviceName -- Name of the service/controller
    @return Logger -- Logger instance
]=]
function Log.new(serviceName: string)
	local self = setmetatable({}, Log)
	self.serviceName = serviceName
	return self
end

--[=[
    Configures global logging settings
    @param config -- Configuration table
]=]
function Log.configure(config: {
	level: number?,
	includeTimestamp: boolean?,
	includeLevel: boolean?,
	includeService: boolean?,
	dateFormat: string?,
	colors: { [number]: string }?,
})
	for key, value in config do
		logConfig[key] = value
	end
end

--[=[
    Gets current log configuration
    @return table -- Current configuration
]=]
function Log.getConfig()
	return table.clone(logConfig)
end

--[=[
    Formats a log message
    @param level -- Log level
    @param serviceName -- Service name
    @param message -- Log message
    @param data -- Optional additional data
    @return string -- Formatted message
]=]
local function formatMessage(level: number, serviceName: string, message: string, data: any?)
	local parts: { string } = {}

	-- Timestamp
	if logConfig.includeTimestamp then
		table.insert(parts, tostring(os.date(logConfig.dateFormat)))
	end

	-- Level with emoji
	if logConfig.includeLevel then
		local emoji = logConfig.colors[level] or ""
		local levelName = Log.LevelNames[level] or "UNKNOWN"
		table.insert(parts, `{emoji} [{levelName}]`)
	end

	-- Service name
	if logConfig.includeService and serviceName then
		table.insert(parts, `[{serviceName}]`)
	end

	-- Message
	table.insert(parts, message)

	-- Additional data
	if data ~= nil then
		if type(data) == "table" then
			local dataStr = "{"
			for k, v in data do
				dataStr = dataStr .. ` {k}={tostring(v)}`
			end
			dataStr = dataStr .. " }"
			table.insert(parts, dataStr)
		else
			table.insert(parts, tostring(data))
		end
	end

	return table.concat(parts, " ")
end

--[=[
    Logs a message at the specified level
    @param level -- Log level
    @param message -- Log message
    @param data -- Optional additional data
]=]
function Log:log(level: number, message: string, data: any?)
	if level < logConfig.level then
		return
	end

	local formatted = formatMessage(level, self.serviceName, message, data)

	-- Store in history
	table.insert(logHistory, {
		timestamp = tick(),
		level = level,
		service = self.serviceName,
		message = message,
		data = data,
		formatted = formatted,
	})

	-- Trim history if too large
	if #logHistory > maxHistorySize then
		table.remove(logHistory, 1)
	end

	-- Output based on level
	if level >= Log.Level.ERROR then
		warn(formatted)
	else
		print(formatted)
	end
end

--[=[
    Trace level logging
    @param message -- Log message
    @param data -- Optional additional data
]=]
function Log:trace(message: string, data: any?)
	self:log(Log.Level.TRACE, message, data)
end

--[=[
    Debug level logging
    @param message -- Log message
    @param data -- Optional additional data
]=]
function Log:debug(message: string, data: any?)
	self:log(Log.Level.DEBUG, message, data)
end

--[=[
    Info level logging
    @param message -- Log message
    @param data -- Optional additional data
]=]
function Log:info(message: string, data: any?)
	self:log(Log.Level.INFO, message, data)
end

--[=[
    Warning level logging
    @param message -- Log message
    @param data -- Optional additional data
]=]
function Log:warn(message: string, data: any?)
	self:log(Log.Level.WARN, message, data)
end

--[=[
    Error level logging
    @param message -- Log message
    @param data -- Optional additional data
]=]
function Log:error(message: string, data: any?)
	self:log(Log.Level.ERROR, message, data)
end

--[=[
    Fatal level logging
    @param message -- Log message
    @param data -- Optional additional data
]=]
function Log:fatal(message: string, data: any?)
	self:log(Log.Level.FATAL, message, data)
end

--[=[
    Gets log history
    @param filterLevel -- Optional minimum level to filter by
    @param filterService -- Optional service name to filter by
    @return table -- Array of log entries
]=]
function Log.getHistory(filterLevel: number?, filterService: string?)
	local filtered = {}

	for _, entry in logHistory do
		local includeLevel = not filterLevel or entry.level >= filterLevel
		local includeService = not filterService or entry.service == filterService

		if includeLevel and includeService then
			table.insert(filtered, entry)
		end
	end

	return filtered
end

--[=[
    Clears log history
]=]
function Log.clearHistory()
	logHistory = {}
end

--[=[
    Creates a global logger (not tied to a service)
    @return Logger -- Global logger instance
]=]
function Log.global()
	return Log.new("Global")
end

return Log
