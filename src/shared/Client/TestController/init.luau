local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cache = require(ReplicatedStorage.Packages.Cache)
local GetModule = require(ReplicatedStorage.Packages.GetModule)
local Queue = require(ReplicatedStorage.Packages.Queue)
local TestController = {}
TestController.__index = TestController

function TestController.new()
	local self = setmetatable({}, TestController)

	return self
end

function TestController:initialize()
	print("Running test controller")
end

function TestController:start()
	local queue = Queue.new()
	for i = 1, 10 do
		queue:push(i)
	end

	queue:setInterval(1, 2, function(item)
		print(`Processing item: {item}`)
	end)

	queue:startProcessing()
end

return TestController
