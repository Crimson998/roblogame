-- Builds the obby out of parts at runtime, so the whole map lives in code.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

local COLORS = {
	Start = Color3.fromRGB(90, 200, 120),
	Platform = Color3.fromRGB(70, 140, 230),
	Milestone = Color3.fromRGB(160, 90, 230),
	Kill = Color3.fromRGB(230, 50, 50),
	Coin = Color3.fromRGB(255, 205, 40),
	Finish = Color3.fromRGB(255, 215, 0),
	Lava = Color3.fromRGB(255, 90, 20),
}

local CourseBuilder = {}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function newPart(className: string, props: { [string]: any }, parent: Instance): BasePart
	local part = Instance.new(className) :: BasePart
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(part :: any)[key] = value
	end
	part.Parent = parent
	return part
end

local function addLabel(part: BasePart, text: string)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.MaxDistance = 120
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = billboard
end

export type Course = {
	checkpoints: { [number]: BasePart }, -- stage number -> platform (0 is the spawn)
	killParts: { BasePart },
	coins: { BasePart },
	finish: BasePart,
}

function CourseBuilder.build(): Course
	local existing = Workspace:FindFirstChild("Course")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "Course"

	local rng = Random.new(Config.Seed)
	local checkpoints: { [number]: BasePart } = {}
	local killParts: { BasePart } = {}
	local coins: { BasePart } = {}

	local start = newPart("SpawnLocation", {
		Name = "Stage0",
		Size = Vector3.new(16, 1, 16),
		Position = Config.StartPosition,
		Color = COLORS.Start,
		Neutral = true,
		Duration = 0,
	}, folder)
	addLabel(start, "Coin Rush Obby")
	checkpoints[0] = start

	local previous = start
	local heading = 0
	local minX, maxX = start.Position.X, start.Position.X
	local minZ, maxZ = start.Position.Z, start.Position.Z
	local lowestY = start.Position.Y

	local function placeNext(width: number, length: number, gap: number, rise: number): CFrame
		heading = math.clamp(heading + rng:NextNumber(-0.6, 0.6), -1.2, 1.2)
		local direction = Vector3.new(math.cos(heading), 0, math.sin(heading))
		local center = previous.Position
			+ direction * (previous.Size.Z / 2 + gap + length / 2)
			+ Vector3.new(0, rise, 0)
		minX, maxX = math.min(minX, center.X), math.max(maxX, center.X)
		minZ, maxZ = math.min(minZ, center.Z), math.max(maxZ, center.Z)
		lowestY = math.min(lowestY, center.Y)
		-- lookAt points the platform's length (Z axis) along the direction of travel
		return CFrame.lookAt(center, center + direction)
	end

	for stage = 1, Config.StageCount do
		local difficulty = (stage - 1) / math.max(Config.StageCount - 1, 1)
		local width = lerp(Config.PlatformMaxWidth, Config.PlatformMinWidth, difficulty)
		local hasKillBar = stage >= Config.KillBarsStartAt and rng:NextNumber() < Config.KillBarChance
		local length = if hasKillBar then width + 8 else width
		local gap = rng:NextNumber(Config.MinGap, lerp(Config.MinGap, Config.MaxGap, difficulty))
		local rise = rng:NextNumber(-1, Config.MaxRise)
		local isMilestone = stage % Config.MilestoneEvery == 0

		local platform = newPart("Part", {
			Name = "Stage" .. stage,
			Size = Vector3.new(width, 1, length),
			CFrame = placeNext(width, length, gap, rise),
			Color = if isMilestone then COLORS.Milestone else COLORS.Platform,
		}, folder)
		platform:SetAttribute("Stage", stage)
		checkpoints[stage] = platform
		if isMilestone then
			addLabel(platform, "Stage " .. stage)
		end

		if hasKillBar then
			local bar = newPart("Part", {
				Name = "KillBar",
				Size = Vector3.new(width, 1.2, 1),
				CFrame = platform.CFrame * CFrame.new(0, 1.1, 0),
				Color = COLORS.Kill,
				Material = Enum.Material.Neon,
			}, folder)
			table.insert(killParts, bar)
		elseif rng:NextNumber() < Config.CoinChance then
			local coin = newPart("Part", {
				Name = "Coin",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.4, 2.5, 2.5),
				Position = platform.Position + Vector3.new(0, 3, 0),
				Color = COLORS.Coin,
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, folder)
			CollectionService:AddTag(coin, "Coin")
			table.insert(coins, coin)
		end

		previous = platform
	end

	local finish = newPart("Part", {
		Name = "Finish",
		Size = Vector3.new(16, 1, 16),
		CFrame = placeNext(16, 16, Config.MinGap, 0),
		Color = COLORS.Finish,
		Material = Enum.Material.Neon,
	}, folder)
	addLabel(finish, "FINISH!")

	-- A lava floor under the whole course, so a missed jump respawns you quickly
	local lava = newPart("Part", {
		Name = "Lava",
		Size = Vector3.new(maxX - minX + 200, 1, maxZ - minZ + 200),
		Position = Vector3.new((minX + maxX) / 2, lowestY - 30, (minZ + maxZ) / 2),
		Color = COLORS.Lava,
		Material = Enum.Material.CrackedLava,
	}, folder)
	table.insert(killParts, lava)

	folder.Parent = Workspace

	return {
		checkpoints = checkpoints,
		killParts = killParts,
		coins = coins,
		finish = finish,
	}
end

return CourseBuilder
