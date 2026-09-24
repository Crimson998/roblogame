-- On-screen progress bar, coin counter, toast messages, and spinning coins.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local notify = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function text(props: { [string]: any }, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	for key, value in props do
		(label :: any)[key] = value
	end
	label.Parent = parent
	return label
end

-- Build the HUD
local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 12)
panel.Size = UDim2.fromOffset(280, 64)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
panel.BackgroundTransparency = 0.3
panel.Parent = gui
corner(panel, 12)

local stageLabel = text({
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(0.6, -12, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local coinLabel = text({
	Position = UDim2.new(0.6, 0, 0, 6),
	Size = UDim2.new(0.4, -12, 0, 26),
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(255, 205, 40),
}, panel)

local barBack = Instance.new("Frame")
barBack.Position = UDim2.new(0, 12, 1, -22)
barBack.Size = UDim2.new(1, -24, 0, 12)
barBack.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
barBack.Parent = panel
corner(barBack, 6)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.fromScale(0, 1)
barFill.BackgroundColor3 = Color3.fromRGB(90, 200, 120)
barFill.Parent = barBack
corner(barFill, 6)

local toast = text({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.new(0.8, 0, 0, 48),
	TextTransparency = 1,
	TextStrokeTransparency = 1,
}, gui)

-- Keep the HUD in sync with leaderstats
local leaderstats = player:WaitForChild("leaderstats")
local stage = leaderstats:WaitForChild("Stage") :: IntValue
local coins = leaderstats:WaitForChild("Coins") :: IntValue

local function refresh()
	stageLabel.Text = `Stage {stage.Value} / {Config.StageCount}`
	coinLabel.Text = `Coins: {coins.Value}`
	TweenService:Create(barFill, TweenInfo.new(0.3), {
		Size = UDim2.fromScale(stage.Value / Config.StageCount, 1),
	}):Play()
end
stage.Changed:Connect(refresh)
coins.Changed:Connect(refresh)
refresh()

-- Toast messages from the server
local toastId = 0
notify.OnClientEvent:Connect(function(message: string)
	toastId += 1
	local myId = toastId
	toast.Text = message
	toast.TextTransparency = 0
	toast.TextStrokeTransparency = 0.3
	task.wait(3)
	if myId == toastId then
		TweenService:Create(toast, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()
	end
end)

-- Spin and bob coins locally (smoother than doing it on the server)
local coinBases: { [BasePart]: Vector3 } = {}
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, coin in CollectionService:GetTagged("Coin") do
		local base = coinBases[coin]
		if not base then
			base = coin.Position
			coinBases[coin] = base
			coin.Destroying:Once(function()
				coinBases[coin] = nil
			end)
		end
		coin.CFrame = CFrame.new(base + Vector3.new(0, math.sin(t * 2) * 0.3, 0)) * CFrame.Angles(0, t * 2, 0)
	end
end)
