-- Game-wide settings. Tweak these to change the pace of the game.
local Config = {
	-- World
	PlotCount = 6, -- one gas station per player; set the server's max players to match
	PlotRadius = 140, -- distance from the center spawn to each station

	-- Customers
	FuelPrice = 15, -- what each car pays before upgrades
	CarSpawnInterval = 2, -- seconds between customers (upgrades make this shorter)
	CarSpeed = 40, -- studs per second
	Patience = 15, -- seconds a car waits for you before driving off without paying
	AutoFuelTime = 5, -- with Card Readers, cars fill themselves after this many seconds

	-- Serving customers yourself
	MaxTip = 0.5, -- serving instantly adds up to +50%; the tip shrinks as the car waits
	StreakBonus = 0.1, -- each customer served in a row adds +10%...
	MaxStreakBonus = 1, -- ...up to +100%. A customer leaving unserved resets the streak.

	-- Store deliveries (after buying the Convenience Store)
	DeliveryInterval = 8, -- seconds between new boxes at the delivery pad
	MaxBoxes = 3,
	StockPerBox = 5, -- each car uses 1 stock to pay the store and snack bonuses
	MaxStock = 30,
	DeliveryReward = 25, -- paid when you stock the shelves

	-- Litter
	TrashInterval = 5,
	MaxTrash = 6,
	TrashReward = 8,

	-- Rebirth: reset everything once the station is complete, for a permanent income boost
	RebirthBonus = 0.5, -- +50% on everything per rebirth

	-- Saving
	AutosaveInterval = 120,
	DataStoreName = "GasStationTycoon_v1",
}

return Config
