local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GetModule = require(ReplicatedStorage.Packages.GetModule)
local Spr = require(ReplicatedStorage.Packages.Spr)
local TestController = {}
TestController.__index = TestController

function TestController.new()
	local self = setmetatable({}, TestController)

	self._hello = "Hello World"

	return self
end

function TestController:initialize()
	local UI = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("Frame1")
	Spr.target(UI, 0.8, 1, {
		Position = UDim2.fromScale(0.5, 0.2),
	})
end

return TestController
