-- Game-wide settings. Tweak these to change the pace of the game.
local Config = {
	-- World
	PlotCount = 6, -- one gas station per player; set the server's max players to match
	PlotRadius = 140, -- distance from the center spawn to each station

	-- Customers
	FuelPrice = 10, -- what each car pays before upgrades
	CarSpawnInterval = 3, -- seconds between customers (upgrades make this shorter)
	FuelTime = 6, -- seconds a car sits at the pump (upgrades make this shorter)
	CarSpeed = 24, -- studs per second

	-- Saving
	AutosaveInterval = 120,
	DataStoreName = "GasStationTycoon_v1",
}

return Config
