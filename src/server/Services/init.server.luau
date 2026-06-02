local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(script.Parent.Data)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Shard = require(ReplicatedStorage.Packages.Shard)

for _, service in script:GetChildren() do
	if service:IsA("ModuleScript") then
		require(service)
	end
end
local start = workspace:GetServerTimeNow()

Promise.new(function(resolve)
	Data:initialize()
	Shard.init()
	resolve()
end)
	:andThen(function()
		Shard.start()
	end)
	:andThen(function()
		print("[SHARD]", workspace:GetServerTimeNow() - start, "ms to init and start services")
		-- print("All services initialized and started successfully.")
		workspace:SetAttribute("ShardServerStarted", true)
	end)
	:catch(function(err)
		warn("Error starting services:", err)
	end)
