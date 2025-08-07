local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shard = require(ReplicatedStorage.Packages.Shard)
local Some = Shard.new("SomeService")
	:withProfiling({
		enabled = true,
		trackExecution = true,
		trackMemory = true,
	})
	:withDependencies({ "Test" })
	:withLifecycle({
		init = function(self)
			Shard.log:debug("This is a debug message.")
		end,

		start = function(self)
			print(self)
			print(Shard.getFrameworkStats())
		end,
	})
	:withTags({ "core" })

function Some:someMethod() end

return Some
