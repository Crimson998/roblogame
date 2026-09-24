-- Everything a player can buy, in button order. A button appears once every item in
-- `requires` is owned. Once everything is bought, the player can rebirth.
--
-- Effects:
--   pump = n        adds pump number n, so one more car can fill up at a time
--   bonus = n       every car pays n extra dollars
--   multiplier = n  every car's payment is multiplied by n
--   spawnRate = n   time between customers is multiplied by n (lower = busier)
--   autoServe = 1   cars fill themselves up if you don't get to them first
--   fuelTime = n    how long self-service takes is multiplied by n (lower = faster)
--   walkSpeed = n   the owner runs at this speed
--
-- needsStock = true means the bonus only counts while the store has stock.

export type Item = {
	id: string,
	name: string,
	price: number,
	requires: { string },
	effects: { [string]: number },
	needsStock: boolean?,
}

local Items: { Item } = {
	{ id = "pump1", name = "Gas Pump #1", price = 0, requires = {}, effects = { pump = 1 } },
	{ id = "pump2", name = "Gas Pump #2", price = 50, requires = { "pump1" }, effects = { pump = 2 } },
	{ id = "skates", name = "Roller Skates", price = 100, requires = { "pump1" }, effects = { walkSpeed = 28 } },
	{ id = "sign", name = "Price Sign", price = 150, requires = { "pump1" }, effects = { spawnRate = 0.85 } },
	{ id = "canopy", name = "Canopy", price = 250, requires = { "pump2" }, effects = { bonus = 5 } },
	{ id = "pump3", name = "Gas Pump #3", price = 400, requires = { "pump2" }, effects = { pump = 3 } },
	{
		id = "store",
		name = "Convenience Store",
		price = 600,
		requires = { "canopy" },
		effects = { bonus = 10 },
		needsStock = true,
	},
	{ id = "pump4", name = "Gas Pump #4", price = 900, requires = { "pump3" }, effects = { pump = 4 } },
	{
		id = "selfserve",
		name = "Card Readers",
		price = 1300,
		requires = { "pump2" },
		effects = { autoServe = 1 },
	},
	{ id = "lights", name = "Neon Lights", price = 1600, requires = { "canopy" }, effects = { bonus = 6 } },
	{
		id = "snacks",
		name = "Snack Machine",
		price = 2000,
		requires = { "store" },
		effects = { bonus = 8 },
		needsStock = true,
	},
	{ id = "turbo", name = "Turbo Nozzles", price = 2800, requires = { "selfserve" }, effects = { fuelTime = 0.5 } },
	{
		id = "billboard",
		name = "Highway Billboard",
		price = 3500,
		requires = { "sign", "store" },
		effects = { spawnRate = 0.75 },
	},
	{ id = "carwash", name = "Car Wash", price = 5000, requires = { "store" }, effects = { bonus = 20 } },
	{ id = "premium", name = "Premium Fuel", price = 7500, requires = { "pump4" }, effects = { multiplier = 1.5 } },
	{ id = "garage", name = "Repair Garage", price = 10000, requires = { "carwash" }, effects = { bonus = 35 } },
}

return Items
