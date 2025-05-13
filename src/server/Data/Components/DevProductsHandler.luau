local Players = game:GetService("Players")

local Types = require(script.Parent.Types)

local PURCHASE_ID_CACHE_SIZE = 100
local DevProductsHandler = {}
local ProductFunctions = {}

-- Define Developer Product Rewards
ProductFunctions[1234566] = function(profile: Types.PlayerProfile, data: Types.Data)
	-- Example for a cash pack:
	-- profile:Increment("Cash", 100000)

	-- local priceCheckSuccess, priceInRobux = pcall(function()
	-- 	return MarketplaceService:GetProductInfo(1234566, Enum.InfoType.Product).PriceInRobux
	-- end)
	-- if priceCheckSuccess then
	-- 	profile:Increment("RobuxSpent", priceInRobux)
	-- end
end


-- Internal:
function DevProductsHandler:ProcessReceipt(receiptInfo, data: Types.Data)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	local profile = data:GetProfileAsync(player)
	if profile then
		return self:PurchaseIdCheckAsync(profile:GetProfile(), receiptInfo.PurchaseId, function()
			if ProductFunctions[receiptInfo.ProductId] then
				ProductFunctions[receiptInfo.ProductId](profile, data)
			else
				warn("No product function defined for ProductId:", receiptInfo.ProductId)
			end
		end)
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function DevProductsHandler:PurchaseIdCheckAsync(profile, purchase_id, grant_product): Enum.ProductPurchaseDecision
	if profile:IsActive() == true then
		local purchase_id_cache = profile.Data.PurchaseIdCache

		if purchase_id_cache == nil then
			purchase_id_cache = {}
			profile.Data.PurchaseIdCache = purchase_id_cache
		end

		if table.find(purchase_id_cache, purchase_id) == nil then
			local success, result = pcall(grant_product)
			if success ~= true then
				warn(`Failed to process receipt:`, profile.Key, purchase_id, result)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			while #purchase_id_cache >= PURCHASE_ID_CACHE_SIZE do
				table.remove(purchase_id_cache, 1)
			end

			table.insert(purchase_id_cache, purchase_id)
		end

		local function is_purchase_saved()
			local saved_cache = profile.LastSavedData.PurchaseIdCache
			return if saved_cache ~= nil then table.find(saved_cache, purchase_id) ~= nil else false
		end

		if is_purchase_saved() == true then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		while profile:IsActive() == true do
			local last_saved_data = profile.LastSavedData

			profile:Save()

			if profile.LastSavedData == last_saved_data then
				profile.OnAfterSave:Wait()
			end

			if is_purchase_saved() == true then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			if profile:IsActive() == true then
				task.wait(10)
			end
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

return DevProductsHandler
