local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cache = require(ReplicatedStorage.Packages.Cache)
local GetModule = require(ReplicatedStorage.Packages.GetModule)
local Queue = require(ReplicatedStorage.Packages.Queue)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Value = require(ReplicatedStorage.Packages.Value)
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
	-- local queue = Queue.new()
	-- for i = 1, 10 do
	-- 	queue:push(i)
	-- end

	-- queue:setInterval(1, 2, function(item)
	-- 	print(`Processing item: {item}`)
	-- end)

	-- queue:startProcessing()

	task.spawn(function()
		local UI = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("Frame")
		local spr = Spring(UI, 0.8, 1)

		task.wait(2)
		spr:SetGoal(UDim2.new(0.5, 0, 0.2, 0))
	end)

	-- task.spawn(function()
	-- 	local val = Value("Cash")
	-- 	val.Changed:Connect(function(value)
	-- 		print(`Value changed to: {value}`)
	-- 	end)

	-- 	task.wait(1)
	-- 	val:set("Cash2")
	-- 	task.wait(1)
	-- 	val:set("Cash3")
	-- 	task.wait(1)
	-- 	val:set("Cash3")

	-- 	print(val:get())
	-- end)
end

return TestController
