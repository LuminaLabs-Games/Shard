-- Check the Controllers folder inside of Shared to set up any client controllers

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local client = ReplicatedStorage:WaitForChild("Controllers")
client.Parent = script.Parent
script:Destroy()
