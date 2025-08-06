local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shard = require(ReplicatedStorage.Packages.Shard)
local TestController = Shard.new("TestController")

function TestController:init() end

function TestController:start()
	local ExampleController = Shard.get("ExampleController")

	print(ExampleController)
end

return TestController
