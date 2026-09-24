-- Creates each player's leaderstats and saves/loads them with DataStoreService.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local STATS = { "Stage", "Coins", "Wins" } -- leaderboard shows them in this order

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

function PlayerData.getStat(player: Player, name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(name) :: IntValue?
end

function PlayerData.load(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in STATS do
		local stat = Instance.new("IntValue")
		stat.Name = name
		stat.Parent = leaderstats
	end

	if store then
		local ok, saved = pcall(store.GetAsync, store, keyFor(player))
		if ok then
			loaded[player] = true
			if type(saved) == "table" then
				for _, name in STATS do
					if type(saved[name]) == "number" then
						(leaderstats:FindFirstChild(name) :: IntValue).Value = saved[name]
					end
				end
			end
		else
			warn("[PlayerData] Failed to load", player.Name, saved)
		end
	end

	leaderstats.Parent = player
end

function PlayerData.save(player: Player)
	if not (store and loaded[player]) then
		return
	end
	local data = {}
	for _, name in STATS do
		local stat = PlayerData.getStat(player, name)
		data[name] = stat and stat.Value or 0
	end
	local ok, err = pcall(store.SetAsync, store, keyFor(player), data)
	if not ok then
		warn("[PlayerData] Failed to save", player.Name, err)
	end
end

function PlayerData.release(player: Player)
	PlayerData.save(player)
	loaded[player] = nil
end

return PlayerData
