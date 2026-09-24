-- Creates each player's Cash leaderstat and saves/loads it (plus what they've bought) with DataStores.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PlayerData = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStores unavailable, progress will not save:", result)
	end
end

-- Only save players whose data loaded, so a failed load never overwrites real progress
local loaded: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

-- Creates leaderstats and returns the list of item ids the player had bought
function PlayerData.load(player: Player): { string }
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats

	local purchased = {}
	if store then
		local ok, saved = pcall(store.GetAsync, store, keyFor(player))
		if ok then
			loaded[player] = true
			if type(saved) == "table" then
				if type(saved.Cash) == "number" then
					cash.Value = saved.Cash
				end
				if type(saved.Purchased) == "table" then
					for _, id in saved.Purchased do
						if type(id) == "string" then
							table.insert(purchased, id)
						end
					end
				end
			end
		else
			warn("[PlayerData] Failed to load", player.Name, saved)
		end
	end

	leaderstats.Parent = player
	return purchased
end

function PlayerData.save(player: Player, purchased: { string })
	if not (store and loaded[player]) then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash") :: IntValue?
	local data = {
		Cash = if cash then cash.Value else 0,
		Purchased = purchased,
	}
	local ok, err = pcall(store.SetAsync, store, keyFor(player), data)
	if not ok then
		warn("[PlayerData] Failed to save", player.Name, err)
	end
end

function PlayerData.forget(player: Player)
	loaded[player] = nil
end

return PlayerData
