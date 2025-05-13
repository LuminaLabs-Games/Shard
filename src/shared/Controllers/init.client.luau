while workspace:GetAttribute("ServerLoaded") ~= true do
	print("Waiting for server to load...")
	task.wait()
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages")

local Framework = require(ReplicatedStorage.Configs.Framework)
local ReplicaClient = require(ReplicatedStorage.Libraries.Replica.ReplicaClient)
local GetModule = require(ReplicatedStorage.Packages.GetModule)
local Promise = require(Packages:WaitForChild("Promise"))
local start = tick()

GetModule.Debug = Framework.GET_MODULE_DEBUG

local totalModules = #script:GetChildren()
local loaded = 0
local initialized = {}

local function loadModule(module)
	if Framework.DEV_MODE and RunService:IsStudio() then
		task.spawn(function()
			local success, err = pcall(function()
				local required = require(module)

				if required.new then
					required = required.new({}) -- You can pass any arguments you want to the constructor here as DI
				end

				if required.initialize then
					required:initialize()
				end

				initialized[module.Name] = required
				GetModule:Add(required, module.Name)
			end)

			if not success then
				warn(`🚫 {err}`)
			end

			loaded += 1
		end)
	else
		local required = require(module)

		if required.new then
			required = required:new({}) -- You can pass any arguments you want to the constructor here as DI
		end

		if required.initialize then
			required:initialize()
		end

		initialized[module.Name] = required
		GetModule:Add(required, module.Name)
	end
end

Promise.new(function(resolve, reject)
	for _, module in script:GetChildren() do
		loadModule(module)
	end

	if Framework.DEV_MODE and RunService:IsStudio() then
		while loaded < totalModules do
			task.wait()
		end
	end

	for name, module in initialized do
		if module.start then
			module:start()
		end
		print(`🚀 Loaded {name}`)
	end

	resolve()
end)
	:andThen(function()
		print(`✅ Client Loaded Successfully in {tick() - start}s`)
		ReplicaClient.RequestData()
	end)
	:catch(function(err)
		warn(err)
	end)
