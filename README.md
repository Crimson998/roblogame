# Gas Station Tycoon

A Roblox tycoon where every player runs their own gas station. The whole map is built from code, so there's nothing to place by hand in Studio. Cash, rebirths and everything you've built save between sessions.

## How to play

- **Serve customers.** Cars pull up to your pumps with a "Needs gas!" patience bar. Walk up and hold **E** to fill them up. The faster you serve, the bigger the tip, up to +50%.
- **Keep your streak.** Every car you serve in a row adds +10%, up to +100%. If a car waits too long it drives off without paying, and your streak resets.
- **Stock the store.** Once you own the Convenience Store, supply boxes show up on the yellow pad. Carry them to the store door. The store and snack bonuses only pay while there's stock.
- **Pick up trash.** Litter appears around the lot; walk over it for quick cash.
- **Buy upgrades.** Step on the glowing buttons. Green means you can afford it. The line under your cash shows what to buy next.
- **Automate.** Card Readers make cars fill themselves if you're busy. That money goes into the cash register, so step on the green pad by the register to collect it.
- **Rebirth.** Once everything is bought, hold E at the purple pillar. Your station and cash reset, and you permanently earn +50% more on everything.

## What's in it

| File | What it does |
| --- | --- |
| `src/shared/Config.luau` | Game pace: prices, customer timing, patience, tips, streaks, deliveries, trash, rebirth bonus |
| `src/shared/Items.luau` | Everything you can buy: name, price, what it requires, and what it does |
| `src/server/StationBuilder.luau` | Builds the parts for the station and each item |
| `src/server/Tycoon.luau` | One station: owner, buttons, buying, serving customers, register, rebirths |
| `src/server/Chores.luau` | Supply box deliveries and trash pickup |
| `src/server/Car.luau` | Customer cars: driving, patience bar, pop-ups |
| `src/server/PlayerData.luau` | Saves and loads Cash, Rebirths and purchases with DataStores |
| `src/server/Main.server.luau` | Builds the world, gives each player a station, saves when they leave |
| `src/client/HUD.client.luau` | Cash counter, streak/stock/rebirth info, next-goal hint, pop-up messages |

## The upgrade path

| Item | Price | Effect |
| --- | --- | --- |
| Gas Pump #1 | Free | First pump |
| Gas Pump #2 | $50 | One more car at a time |
| Roller Skates | $100 | You run much faster |
| Price Sign | $150 | Customers come 15% more often |
| Canopy | $250 | +$5 per car |
| Gas Pump #3 | $400 | One more car at a time |
| Convenience Store | $600 | +$10 per car while stocked; unlocks deliveries |
| Gas Pump #4 | $900 | One more car at a time |
| Card Readers | $1,300 | Cars fill themselves after 5 seconds if you're busy |
| Neon Lights | $1,600 | +$6 per car |
| Snack Machine | $2,000 | +$8 per car while stocked |
| Turbo Nozzles | $2,800 | Self-service is twice as fast |
| Highway Billboard | $3,500 | Customers come 25% more often |
| Car Wash | $5,000 | +$20 per car |
| Premium Fuel | $7,500 | Every car pays 1.5x |
| Repair Garage | $10,000 | +$35 per car |

In a rough simulation of an active player, the first seven upgrades take about a minute, and the whole station takes around 11 minutes. To add an item, give it an entry in `Items.luau`. If it should appear in the world, also add a build function with the same id in `StationBuilder.items`.

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

- Hire an attendant who collects the register automatically
- Special customers: a limo that tips 5x, or a police car that needs serving first
- Fuel deliveries: a tanker truck you have to unload before the pumps run dry
- Day/night cycle, with the neon lights and signs glowing at night
- A second floor or a second lot you can expand into
