--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IS_CLIENT = RunService:IsClient()

type Callback = (character: Model) -> (() -> ())?

--[=[
	@within Observers
	@client

	Creates an observer that captures the local character in the game. This
	can only be called from client-side code.

	```lua
	-- In a LocalScript or Client-context script
	observeLocalCharacter(function(character)
		print("Local character spawned")

		return function()
			-- Cleanup
			print("Local character removed")
		end
	end)
	```
]=]
local function observeLocalCharacter(callback: Callback): () -> ()
	assert(IS_CLIENT, "observeLocalCharacter can only be called from the client")

	local cleanup: (() -> ())? = nil
	local subscribed = true

	local function onCharacterAdded(character: Model)
		local cleanupFn: (() -> ())? = nil

		local ancestryChangedConn: RBXScriptConnection
		ancestryChangedConn = character.AncestryChanged:Connect(function(_, parent)
			if parent == nil and ancestryChangedConn.Connected then
				ancestryChangedConn:Disconnect()
				if typeof(cleanupFn) == "function" and subscribed then
					task.spawn(cleanupFn)
					if cleanup == cleanupFn then
						cleanup = nil
					end
				end
			end
		end)

		cleanupFn = callback(character)
		if typeof(cleanupFn) == "function" then
			if ancestryChangedConn.Connected then
				cleanup = cleanupFn
			else
				task.spawn(cleanupFn)
			end
		end
	end

	local characterAddedConn = Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	if Players.LocalPlayer.Character ~= nil then
		task.spawn(onCharacterAdded, Players.LocalPlayer.Character)
	end

	return function()
		subscribed = false
		characterAddedConn:Disconnect()
		if typeof(cleanup) == "function" then
			task.spawn(cleanup)
			cleanup = nil
		end
	end
end

return observeLocalCharacter