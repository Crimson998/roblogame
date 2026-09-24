-- On-screen cash counter, streak/stock/rebirth info, next goal, and pop-up messages.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))

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

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 12)
panel.Size = UDim2.fromOffset(220, 50)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
panel.BackgroundTransparency = 0.3
panel.Parent = gui
corner(panel, 12)

local cashLabel = text({
	Position = UDim2.fromOffset(12, 6),
	Size = UDim2.new(1, -24, 1, -12),
	TextColor3 = Color3.fromRGB(90, 255, 120),
}, panel)

local infoLabel = text({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 70),
	Size = UDim2.fromOffset(420, 24),
	TextStrokeTransparency = 0.3,
	RichText = true,
}, gui)

local goalLabel = text({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 96),
	Size = UDim2.fromOffset(420, 22),
	TextColor3 = Color3.fromRGB(255, 220, 120),
	TextStrokeTransparency = 0.3,
}, gui)

local toast = text({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.25),
	Size = UDim2.new(0.8, 0, 0, 44),
	TextTransparency = 1,
	TextStrokeTransparency = 1,
}, gui)

-- Cash counter that pops when it changes
local leaderstats = player:WaitForChild("leaderstats")
local cash = leaderstats:WaitForChild("Cash") :: IntValue
local rebirths = leaderstats:WaitForChild("Rebirths") :: IntValue

local function refresh()
	cashLabel.Text = Format.money(cash.Value)
	panel.Size = UDim2.fromOffset(240, 56)
	TweenService:Create(panel, TweenInfo.new(0.2), { Size = UDim2.fromOffset(220, 50) }):Play()
end
cash.Changed:Connect(refresh)
refresh()

-- Streak, store stock and rebirth boost, shown only when they matter
local function refreshInfo()
	local parts = {}
	local streak = player:GetAttribute("Streak") or 0
	if streak > 0 then
		local bonus = math.min(streak * Config.StreakBonus, Config.MaxStreakBonus) * 100
		table.insert(parts, `<font color="#ffb347">Streak {streak} (+{math.floor(bonus)}%)</font>`)
	end
	local stock = player:GetAttribute("Stock")
	if stock ~= nil then
		local color = if stock > 0 then "#9fe8ff" else "#ff6b6b"
		local message = if stock > 0 then `Store stock: {stock}` else "Store empty! Restock it"
		table.insert(parts, `<font color="{color}">{message}</font>`)
	end
	if rebirths.Value > 0 then
		local multiplier = 1 + rebirths.Value * Config.RebirthBonus
		table.insert(parts, `<font color="#d49bff">Rebirth x{multiplier}</font>`)
	end
	infoLabel.Text = table.concat(parts, "   ")
	goalLabel.Text = player:GetAttribute("Goal") or ""
end
player:GetAttributeChangedSignal("Streak"):Connect(refreshInfo)
player:GetAttributeChangedSignal("Stock"):Connect(refreshInfo)
player:GetAttributeChangedSignal("Goal"):Connect(refreshInfo)
rebirths.Changed:Connect(refreshInfo)
refreshInfo()

-- Pop-up messages from the server
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
