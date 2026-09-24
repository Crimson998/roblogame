# Coin Rush Obby

A Roblox obstacle course (obby) whose whole map is generated from code. It has 30 stages that get harder as you go, spinning coins, red kill bars, a lava floor, checkpoints and a finish line. Progress saves between sessions.

## What's in it

| File | What it does |
| --- | --- |
| `src/shared/Config.luau` | All the settings: number of stages, gap sizes, coin rewards, random seed |
| `src/server/CourseBuilder.luau` | Builds the platforms, kill bars, coins, finish pad and lava floor |
| `src/server/PlayerData.luau` | Leaderboard stats (Stage, Coins, Wins) and saving with DataStores |
| `src/server/Main.server.luau` | Game rules: checkpoints, collecting coins, hazards, finishing, respawning |
| `src/client/HUD.client.luau` | On-screen progress bar, coin counter, pop-up messages, spinning coins |

## Getting it into Roblox Studio

This project uses [Rojo](https://rojo.space) to sync code files into Studio.

1. Install [Roblox Studio](https://create.roblox.com/).
2. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this folder to get Rojo.
3. In Studio, install the Rojo plugin: run `rojo plugin install`, or get it from the Creator Store.

Then pick one:

- **Live sync (recommended while developing):** run `rojo serve`, open a new Baseplate in Studio, and click **Connect** in the Rojo plugin. Saving a file here updates Studio immediately.
- **One-off build:** run `rojo build -o CoinRush.rbxlx`, then open `CoinRush.rbxlx` in Studio.

Press **Play** to test.

### Saving progress in Studio

DataStores only work in Studio after you publish the place and turn on
**Game Settings → Security → Enable Studio Access to API Services**. Without that, the game still runs; progress just isn't saved.

## Tweaking the game

Everything is in `src/shared/Config.luau`. For example:

- `Seed`: change it to get a completely different course layout.
- `StageCount`: make the course longer or shorter.
- `MaxGap` / `MaxRise`: make jumps harder. A default character can clear about 8 studs on flat ground, so stay under that.
- `KillBarChance` / `CoinChance`: more obstacles or more coins.

## Ideas for what to add next

- A shop that spends coins on speed boosts, trails or gravity coils
- Moving or disappearing platforms
- A "skip stage" button
- A global leaderboard of fastest completion times
- Themed sections (ice, lava, space) with different materials and colors
