# Gas Station Tycoon

A Roblox tycoon where every player runs their own gas station. Step on buttons to buy pumps, a canopy, a store, a car wash and more. Cars drive in, fill up and pay into your cash register, and you step on the green pad to collect the money. Your cash and everything you've built save between sessions.

The whole map is built from code, so there's nothing to place by hand in Studio.

## What's in it

| File | What it does |
| --- | --- |
| `src/shared/Config.luau` | Game pace: fuel price, how often cars come, fueling time, car speed, number of plots |
| `src/shared/Items.luau` | Everything you can buy: name, price, what it requires, and what it does |
| `src/server/StationBuilder.luau` | Builds the parts for the station and each item |
| `src/server/Tycoon.luau` | One station: owner, buttons, buying, cash register, and the customer cars |
| `src/server/Car.luau` | The customer cars and how they drive |
| `src/server/PlayerData.luau` | Saves and loads Cash and purchases with DataStores |
| `src/server/Main.server.luau` | Builds the world, gives each player a station, saves when they leave |
| `src/client/HUD.client.luau` | On-screen cash counter and pop-up messages |

## The upgrade path

| Item | Price | Effect |
| --- | --- | --- |
| Gas Pump #1 | Free | First pump |
| Gas Pump #2 | $60 | One more car at a time |
| Price Sign | $120 | Customers come 15% more often |
| Canopy | $250 | +$3 per car |
| Gas Pump #3 | $350 | One more car at a time |
| Convenience Store | $800 | +$8 per car |
| Gas Pump #4 | $1,200 | One more car at a time |
| Neon Lights | $1,500 | +$5 per car |
| Snack Machine | $2,000 | +$6 per car |
| Turbo Nozzles | $3,000 | Cars fill up twice as fast |
| Highway Billboard | $4,000 | Customers come 25% more often |
| Car Wash | $6,000 | +$20 per car |
| Premium Fuel | $10,000 | Every car pays 1.5x |
| Repair Garage | $20,000 | +$40 per car |

Buttons are green when you can afford them and red when you can't. To add an item, give it an entry in `Items.luau`. If it should appear in the world, also add a build function with the same id in `StationBuilder.items`.

## Getting it into Roblox Studio

This project uses [Rojo](https://rojo.space) to sync code files into Studio.

1. Install [Roblox Studio](https://create.roblox.com/).
2. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder to get Rojo.
3. In Studio, install the Rojo plugin: run `rojo plugin install`, or get it from the Creator Store.

Then pick one:

- **Live sync (recommended while developing):** run `rojo serve`, open a new Baseplate in Studio, and click **Connect** in the Rojo plugin. Saving a file here updates Studio immediately.
- **One-off build:** run `rojo build -o GasStationTycoon.rbxlx`, then open that file in Studio.

Press **Play** to test. The Baseplate template's floor and spawn are replaced automatically.

### Before publishing

- Set **Game Settings → Places → Max Players** to 6 (or whatever `PlotCount` is), so everyone gets a station.
- DataStores only work in Studio after you publish and turn on **Game Settings → Security → Enable Studio Access to API Services**. Without that, the game still runs; progress just isn't saved.

## Ideas for what to add next

- Rebirths: reset your station for a permanent income multiplier
- Hire an attendant who collects the register automatically
- Fuel deliveries: a tanker truck you have to unload before the pumps run dry
- Day/night cycle, with the neon lights and signs glowing at night
- A second floor or a second lot you can expand into
