-- Entry point: builds the course and wires up checkpoints, coins, hazards and the finish line.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CourseBuilder = require(script.Parent.CourseBuilder)
local PlayerData = require(script.Parent.PlayerData)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local notify = Instance.new("RemoteEvent")
notify.Name = "Notify" -- server -> client toast messages
notify.Parent = remotes
remotes.Parent = ReplicatedStorage

local course = CourseBuilder.build()

-- Returns the player whose living character touched `hit`, if any
local function playerFromHit(hit: BasePart): (Player?, Humanoid?)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if player and humanoid and humanoid.Health > 0 then
		return player, humanoid
	end
	return nil, nil
end

-- Checkpoints: touching a later stage saves your progress
for stage, platform in course.checkpoints do
	if stage == 0 then
		continue
	end
	platform.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		local stat = player and PlayerData.getStat(player, "Stage")
		if stat and stage > stat.Value then
			stat.Value = stage
			if stage % Config.MilestoneEvery == 0 then
				notify:FireClient(player, `Checkpoint! Stage {stage} of {Config.StageCount}`)
			end
		end
	end)
end

-- Hazards
for _, part in course.killParts do
	part.Touched:Connect(function(hit)
		local _, humanoid = playerFromHit(hit)
		if humanoid then
			humanoid.Health = 0
		end
	end)
end

-- Coins disappear when collected and come back after a while
for _, coin in course.coins do
	local available = true
	coin.Touched:Connect(function(hit)
		if not available then
			return
		end
		local player = playerFromHit(hit)
		local stat = player and PlayerData.getStat(player, "Coins")
		if not stat then
			return
		end
		available = false
		stat.Value += Config.CoinValue
		coin.Transparency = 1
		coin.CanTouch = false
		task.delay(Config.CoinRespawnTime, function()
			coin.Transparency = 0
			coin.CanTouch = true
			available = true
		end)
	end)
end

-- Finish line: reward the player, then send them back to the start for another run
local finishing: { [Player]: boolean } = {}
course.finish.Touched:Connect(function(hit)
	local player = playerFromHit(hit)
	if not player or finishing[player] then
		return
	end
	local stage = PlayerData.getStat(player, "Stage")
	-- Must have reached the last stage, so nobody can skip straight to the end
	if not stage or stage.Value < Config.StageCount then
		return
	end
	finishing[player] = true

	local wins = PlayerData.getStat(player, "Wins") :: IntValue
	local coins = PlayerData.getStat(player, "Coins") :: IntValue
	wins.Value += 1
	coins.Value += Config.FinishCoinReward
	stage.Value = 0
	notify:FireClient(player, `You win! +{Config.FinishCoinReward} coins. Total wins: {wins.Value}`)
	task.spawn(PlayerData.save, player)

	task.wait(3)
	if player.Parent then
		player:LoadCharacter()
	end
	finishing[player] = nil
end)

-- Respawn at the last checkpoint reached
local function onCharacterAdded(player: Player, character: Model)
	local stage = PlayerData.getStat(player, "Stage")
	local checkpoint = stage and stage.Value > 0 and course.checkpoints[stage.Value]
	if not checkpoint then
		return -- stage 0 uses the normal SpawnLocation
	end
	if not character:WaitForChild("HumanoidRootPart", 5) then
		return
	end
	task.wait() -- let Roblox finish placing the character before we move it
	character:PivotTo(checkpoint.CFrame + Vector3.new(0, 4, 0))
end

local function onPlayerAdded(player: Player)
	PlayerData.load(player)

	-- Saved progress may point past the end if the course was made shorter
	local stage = PlayerData.getStat(player, "Stage") :: IntValue
	stage.Value = math.clamp(stage.Value, 0, Config.StageCount)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	finishing[player] = nil
	PlayerData.release(player)
end)

game:BindToClose(function()
	local pending = 0
	for _, player in Players:GetPlayers() do
		pending += 1
		task.spawn(function()
			PlayerData.release(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
