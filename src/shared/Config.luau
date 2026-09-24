-- Game-wide settings. Tweak these to change how the course is generated and rewarded.
local Config = {
	-- Course generation
	Seed = 12345, -- same seed = same course every server; change it for a new layout
	StageCount = 30,
	MilestoneEvery = 5, -- every Nth stage gets a label and a toast message
	StartPosition = Vector3.new(0, 20, 0),

	-- Platform sizes shrink from max to min as the course gets harder
	PlatformMaxWidth = 10,
	PlatformMinWidth = 4,

	-- Gaps are measured edge to edge. A default Roblox character can clear about 8 studs on flat ground.
	MinGap = 3,
	MaxGap = 6.5,
	MaxRise = 2, -- how much higher the next platform can be

	-- Obstacles and pickups
	KillBarChance = 0.3, -- chance a platform gets a red bar you must jump over
	KillBarsStartAt = 4, -- first stage that can have a kill bar
	CoinChance = 0.6,
	CoinValue = 1,
	CoinRespawnTime = 15,

	-- Finishing the course
	FinishCoinReward = 25,

	-- Saving
	DataStoreName = "CoinRushObby_v1",
}

return Config
