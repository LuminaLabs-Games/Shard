local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shard = require(ReplicatedStorage.Packages.Shard)
local Test = Shard.new("Test")
	:withDependencies({ "Other" })
	:withLifecycle({
		init = function(self) end,

		start = function(self) end,
	})
	:withRemoteEvents({
		{
			TestEvent = function(data)
				print("Test event received:", data)
			end,
		},
	})

return Test
