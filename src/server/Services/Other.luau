local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shard = require(ReplicatedStorage.Packages.Shard)
local Other = Shard.new("Other")
	:withFeatureFlags({
		otherFeatureEnabled = true,
		betaTester = true,
	})
	:withLifecycle({
		init = function(self)
			if self:isFeatureEnabled("otherFeatureEnabled") then
				Shard.log:info("Other feature is enabled!")
			else
				Shard.log:info("Other feature is disabled.")
			end
		end,

		start = function(self)
			Shard.log:info("Other service started.")
		end,
	})

return Other
