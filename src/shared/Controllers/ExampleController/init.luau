local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shard = require(ReplicatedStorage.Packages.Shard)
local ExampleController = Shard.new("ExampleController")

function ExampleController:init()
	print(`ExampleController initialized`)
end

function ExampleController:start()
	print(`ExampleController started`)
end

return ExampleController
