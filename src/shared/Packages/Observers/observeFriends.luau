local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Trove = require(ReplicatedStorage.Packages.Trove)

local FriendUtils = {}

function observeFriendsInServer(player, callback)
	local newTrove = Trove.new()
	local friends = {}

	local function handleFriendState(otherPlayer, isFriendsWith)
		if otherPlayer == player then
			return
		end
		if isFriendsWith then
			if not friends[otherPlayer] then
				friends[otherPlayer] = true
			end
		else
			friends[otherPlayer] = nil
		end

		task.defer(function()
			callback(friends)
		end)
		-- callback(friends)
	end

	local function handleNewPlayerAsync(otherPlayer)
		if otherPlayer ~= player then
			local success, isFriendsWith = pcall(function()
				return player:IsFriendsWith(otherPlayer.UserId)
			end)

			if not success then
				handleFriendState(otherPlayer, false)
				return
			end

			handleFriendState(otherPlayer, isFriendsWith)
		end

		-- callback(friends)
	end

	newTrove:Add(Players.PlayerRemoving:Connect(function(otherPlayer)
		newTrove[otherPlayer] = nil
		handleFriendState(otherPlayer, false)
	end))

	newTrove:Add(Players.PlayerAdded:Connect(function(otherPlayer)
		handleNewPlayerAsync(otherPlayer)
	end))

	for _, otherPlayer in Players:GetPlayers() do
		task.spawn(handleNewPlayerAsync, otherPlayer)
	end

	if player == Players.LocalPlayer and RunService:IsRunning() then
		task.spawn(function() -- So just incase these connections throw, use a new thread so we don't error out
			newTrove:Add(StarterGui:GetCore("PlayerFriendedEvent").Event:Connect(function(otherPlayer)
				handleFriendState(otherPlayer, true)
			end))

			newTrove:Add(StarterGui:GetCore("PlayerUnfriendedEvent").Event:Connect(function(otherPlayer)
				handleFriendState(otherPlayer, false)
			end))
		end)
	end

	return function()
		newTrove:Clean()
	end
end

return observeFriendsInServer
