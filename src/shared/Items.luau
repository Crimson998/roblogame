-- Everything a player can buy, in button order. A button appears once every item in
-- `requires` is owned.
--
-- Effects:
--   pump = n        adds pump number n, so one more car can fill up at a time
--   bonus = n       every car pays n extra dollars
--   multiplier = n  every car's payment is multiplied by n
--   spawnRate = n   time between customers is multiplied by n (lower = busier)
--   fuelTime = n    time at the pump is multiplied by n (lower = faster)

export type Item = {
	id: string,
	name: string,
	price: number,
	requires: { string },
	effects: { [string]: number },
}

local Items: { Item } = {
	{ id = "pump1", name = "Gas Pump #1", price = 0, requires = {}, effects = { pump = 1 } },
	{ id = "pump2", name = "Gas Pump #2", price = 60, requires = { "pump1" }, effects = { pump = 2 } },
	{ id = "sign", name = "Price Sign", price = 120, requires = { "pump1" }, effects = { spawnRate = 0.85 } },
	{ id = "canopy", name = "Canopy", price = 250, requires = { "pump2" }, effects = { bonus = 3 } },
	{ id = "pump3", name = "Gas Pump #3", price = 350, requires = { "pump2" }, effects = { pump = 3 } },
	{ id = "store", name = "Convenience Store", price = 800, requires = { "canopy" }, effects = { bonus = 8 } },
	{ id = "pump4", name = "Gas Pump #4", price = 1200, requires = { "pump3" }, effects = { pump = 4 } },
	{ id = "lights", name = "Neon Lights", price = 1500, requires = { "canopy" }, effects = { bonus = 5 } },
	{ id = "snacks", name = "Snack Machine", price = 2000, requires = { "store" }, effects = { bonus = 6 } },
	{ id = "turbo", name = "Turbo Nozzles", price = 3000, requires = { "pump4" }, effects = { fuelTime = 0.5 } },
	{
		id = "billboard",
		name = "Highway Billboard",
		price = 4000,
		requires = { "sign", "store" },
		effects = { spawnRate = 0.75 },
	},
	{ id = "carwash", name = "Car Wash", price = 6000, requires = { "store" }, effects = { bonus = 20 } },
	{ id = "premium", name = "Premium Fuel", price = 10000, requires = { "turbo" }, effects = { multiplier = 1.5 } },
	{ id = "garage", name = "Repair Garage", price = 20000, requires = { "carwash" }, effects = { bonus = 40 } },
}

return Items
