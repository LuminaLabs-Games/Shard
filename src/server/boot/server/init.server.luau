local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local Framework = require(ReplicatedStorage.Configs.Framework)
local GetModule = require(ReplicatedStorage.Packages.GetModule)
local Data = require(Packages.Data)
local Promise = require(Packages.Promise)
local start = tick()

local totalModules = #script:GetChildren()
local loaded = 0
local initalized = {}

local function loadModule(module, Data)
	if Framework.DEV_MODE and RunService:IsStudio() then
		task.spawn(function()
			local success, err = pcall(function()
				local required = require(module).new({
					-- data = Data,
				})

				if required.initialize then
					required:initialize()
				end

				initalized[module.Name] = required
				GetModule:Add(required, module.Name)
			end)

			if not success then
				warn(`🚫 {err}`)
			end
			loaded += 1
		end)
	else
		local required = require(module).new({
			-- data = Data,
		})

		if required.initialize then
			required:initialize()
		end

		initalized[module.Name] = required
		GetModule:Add(required, module.Name)
	end
end

Promise.new(function(resolve, reject)
	-- local Data = Data.new()

	Data:initialize()

	for _, module in script:GetChildren() do
		loadModule(module, Data)
	end

	if Framework.DEV_MODE and RunService:IsStudio() then
		while loaded < totalModules do
			task.wait()
		end
	end
	for name, module in initalized do
		if module.start then
			module:start()
		end
		print(`🚀 Loaded {name}`)
	end

	resolve()
end)
	:andThen(function()
		print(`✅ Server Loaded Successfully in {tick() - start}s`)
		workspace:SetAttribute("ServerLoaded", true)
	end)
	:catch(function(err)
		warn(err)
	end)
