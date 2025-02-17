local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Libraries = ReplicatedStorage.Libraries
local Packages = ReplicatedStorage.Packages

local observePlayer = require(Packages.Observers.observePlayer)
local PlayerProfile = require(script.Components.PlayerProfile)
local ProfileStore = require(Libraries.ProfileStore)
local Replica = require(Libraries.Replica.ReplicaServer)
local Settings = require(script.Components.Settings)

local Data = {}
Data.__index = Data

local DataSingleton = setmetatable({}, Data)

function DataSingleton:initialize()
	self._playerToken = Replica.Token("PlayerData")
	self._playerStore = ProfileStore.New("PlayerStore", Settings.TEMPLATE)
	if RunService:IsStudio() and Settings.DEBUG_MOCK then
		print("I'm mocking you")
		self._playerStore = self._playerStore.Mock
	end

	self._profiles = {} :: { [Player]: typeof(self._playerStore:StartSessionAsync()) }
	self:_observePlayers()
end

function DataSingleton:GetProfileAsync(player: Player)
	while not self._profiles[player] and player.Parent == Players do
		task.wait()
	end
	return self._profiles[player]
end

function DataSingleton:_playerAdded(player: Player)
	local profile = nil
	while player.Parent == Players and not ProfileStore.IsClosing do
		profile = self._playerStore:StartSessionAsync(`{player.UserId}{Settings.SUFFIX}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
		if profile then
			break
		end
	end

	if not profile then
		player:Kick(Settings.LOAD_FAILED_MESSAGE)
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		self._profiles[player] = nil
		player:Kick(Settings.SEESION_END_MESSAGE)
	end)

	if player.Parent ~= Players then
		profile:EndSession()
	end

	local replica = Replica.New({
		Token = self._playerToken,
		Data = profile.Data,
		Tags = { Player = player },
	})
	replica:Replicate()

	self._profiles[player] = PlayerProfile.new(player, profile, replica)
end

function DataSingleton:_observePlayers()
	observePlayer(function(player)
		self:_playerAdded(player)
		return function()
			local profile = self._profiles[player] and self._profiles[player]:GetProfile()
			if profile then
				profile:EndSession()
			end
		end
	end)
end

return DataSingleton
