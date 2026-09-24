-- Entry point: builds the world, gives each player a gas station, and saves progress.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)
local Tycoon = require(script.Parent.Tycoon)

-- Studio's Baseplate template comes with its own floor and spawn; we build our own
for _, name in { "Baseplate", "SpawnLocation" } do
	local existing = Workspace:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

local grass = Instance.new("Part")
grass.Name = "Grass"
grass.Anchored = true
grass.Size = Vector3.new(460, 2, 460)
grass.Position = Vector3.new(0, -1.1, 0) -- just under the stations' ground so they don't flicker
grass.Color = Color3.fromRGB(90, 160, 70)
grass.Material = Enum.Material.Grass
grass.Parent = Workspace

local spawn = Instance.new("SpawnLocation")
spawn.Name = "CenterSpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.Position = Vector3.new(0, 0.5, 0)
spawn.Neutral = true
spawn.Duration = 0
spawn.Parent = Workspace

-- Stations in a ring around the spawn, each with its road facing the middle
local stationsFolder = Instance.new("Folder")
stationsFolder.Name = "Stations"
stationsFolder.Parent = Workspace

local tycoons = {}
for index = 1, Config.PlotCount do
	local angle = (index - 1) / Config.PlotCount * math.pi * 2
	local center = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.PlotRadius
	-- Looking away from the middle puts the plot's +Z side (the road) toward it
	local origin = CFrame.lookAt(center, center * 2)
	table.insert(tycoons, Tycoon.new(index, origin, stationsFolder))
end

local tycoonOf: { [Player]: any } = {}

local function saveAndLeave(player: Player)
	local tycoon = tycoonOf[player]
	if not tycoon then
		return
	end
	tycoon:collect() -- don't lose money left in the register
	PlayerData.save(player, tycoon:getPurchasedList())
end

local function sendHome(player: Player, character: Model)
	local tycoon = tycoonOf[player]
	if not tycoon or not character:WaitForChild("HumanoidRootPart", 5) then
		return
	end
	task.wait() -- let Roblox finish placing the character before we move it
	character:PivotTo(tycoon:spawnCFrame())
end

local function onPlayerAdded(player: Player)
	local purchased = PlayerData.load(player)
	if not player.Parent then
		return -- left while loading
	end

	local free
	for _, tycoon in tycoons do
		if not tycoon.owner then
			free = tycoon
			break
		end
	end
	if not free then
		task.delay(3, function()
			Remotes.Notify:FireClient(player, "All gas stations are taken. Try another server!")
		end)
		return
	end

	tycoonOf[player] = free
	free:claim(player, purchased)

	player.CharacterAdded:Connect(function(character)
		sendHome(player, character)
	end)
	if player.Character then
		task.spawn(sendHome, player, player.Character)
	end
	task.delay(3, function()
		local message = if #purchased > 0
			then "Welcome back! Your gas station is ready."
			else "Welcome! Step on the green button to build your first pump."
		Remotes.Notify:FireClient(player, message)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	saveAndLeave(player)
	PlayerData.forget(player)
	local tycoon = tycoonOf[player]
	if tycoon then
		tycoon:release()
		tycoonOf[player] = nil
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.AutosaveInterval)
		for player, tycoon in tycoonOf do
			task.spawn(PlayerData.save, player, tycoon:getPurchasedList())
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in tycoonOf do
		pending += 1
		task.spawn(function()
			saveAndLeave(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end)
