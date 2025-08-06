repeat
	task.wait()
until workspace:GetAttribute("ShardServerStarted") ~= nil and workspace:GetAttribute("ShardServerStarted") == true

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Libraries.Replica.ReplicaClient)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Shard = require(ReplicatedStorage.Packages.Shard)

for _, controller in script:GetChildren() do
	if controller:IsA("ModuleScript") then
		require(controller)
	end
end

local start = workspace:GetServerTimeNow()

Promise.new(function(resolve)
	Shard.init()
	resolve()
end)
	:andThen(function()
		Shard.start()
	end)
	:andThen(function()
		print("[SHARD]", workspace:GetServerTimeNow() - start, "ms to init and start controllers")
		-- print("All controllers initialized and started successfully.")
		workspace:SetAttribute("ShardClientStarted", true)
		ReplicaClient.RequestData()
	end)
	:catch(function(err)
		warn("Error starting services:", err)
	end)
