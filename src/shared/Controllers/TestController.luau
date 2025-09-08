local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shard = require(ReplicatedStorage.Packages.Shard)

local TestController = Shard.new("TestController"):withLifecycle({
	init = function(self)
		Shard.log:info("TestController initialized.")
	end,

	start = function(self)
		Shard.log:info("TestController started.")
	end,
})

return TestController