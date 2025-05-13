local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RunContext = RunService:IsClient() and "Client" or "Server"

local GetModule = {}
GetModule.__index = GetModule

local GetModuleSingleton = setmetatable({}, GetModule)
GetModuleSingleton._modules = {
	Client = {},
	Server = {},
}

GetModule.Debug = false

function GetModule:Add(module, name)
	if not GetModuleSingleton._modules[RunContext] then
		GetModuleSingleton._modules[RunContext] = {}
	end
	GetModuleSingleton._modules[RunContext][name] = module
end

function GetModule:Remove(name)
	if not GetModuleSingleton._modules[RunContext] then
		GetModuleSingleton._modules[RunContext] = {}
	end
	GetModuleSingleton._modules[RunContext][name] = nil
end

local function attemptModuleLoad(source: Instance, moduleName: string)
	local foundModule = source:FindFirstChild(moduleName, true)
	if not foundModule then return nil end

	if GetModule.Debug then
		print(`📦 Attempting to load {moduleName} from {source:GetFullName()}...`)
	end

	local success, result = pcall(require, foundModule)

	if not success then
		warn(`🚫 Failed to require {moduleName}: {result}`)
		return nil
	end

	if GetModule.Debug then
		print(`📦 Successfully loaded {moduleName} from {source:GetFullName()}`)
	end

	GetModuleSingleton._modules[RunContext][foundModule.Name] = result
	return result
end

function GetModule:Resolve(moduleName: string)
	if GetModule.Debug then
		print(`📦 Resolving {moduleName}...`)
	end

	local cached = GetModuleSingleton._modules[RunContext][moduleName]
	if cached then
		return cached
	end

	local result =
		attemptModuleLoad(ReplicatedStorage, moduleName)
		or (RunContext == "Server" and attemptModuleLoad(ServerScriptService, moduleName))

	if not result then
		warn(`🚫 {moduleName} not found`)
	end

	return result
end

return setmetatable(GetModule, {
	__index = GetModuleSingleton,
	__call = function(_, moduleName: string)
		local cached = GetModuleSingleton._modules[RunContext][moduleName]
		if cached then
			return cached
		end

		if GetModule.Debug then
			print(`📦 {moduleName} not found in cache, attempting fallback search...`)
		end

		return GetModule:Resolve(moduleName)
	end,
})
