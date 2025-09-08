local RunService = game:GetService("RunService")

local Log = require(script.Parent.Log)

return {
	VERBOSE_LOGGING = RunService:IsStudio() and false,
	Logger = {
		level = RunService:IsStudio() and Log.Level.TRACE or Log.Level.ERROR,
		includeTimestamp = true,
		includeLevel = true,
		includeService = true,
		dateFormat = "%H:%M:%S",
	},
}
