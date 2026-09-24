-- Side jobs around the station: carrying supply boxes to the store, and picking up trash.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(script.Parent.Remotes)
local StationBuilder = require(script.Parent.StationBuilder)

local BOX_NAME = "SupplyBox"
local TRASH_COLORS = {
	Color3.fromRGB(200, 200, 200),
	Color3.fromRGB(120, 90, 60),
	Color3.fromRGB(220, 60, 60),
	Color3.fromRGB(60, 120, 220),
}

local Chores = {}

local function prompt(parent: Instance, action: string, object: string): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0.2
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function pickUp(box: BasePart, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or character:FindFirstChild(BOX_NAME) then
		return false
	end
	box.Anchored = false
	box.CanCollide = false
	box.Massless = true
	box.CFrame = root.CFrame * CFrame.new(0, 0, -2)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = box
	weld.Parent = box
	box.Parent = character
	return true
end

-- Spawns supply boxes on the delivery pad and lets the owner stock the shelves with them
function Chores.setupStore(tycoon, session: number)
	local door = tycoon.itemsFolder:FindFirstChild("StoreDoor", true)
	if door then
		local stockPrompt = prompt(door, "Stock Shelves", "Quick Mart")
		stockPrompt.Triggered:Connect(function(player)
			local box = player.Character and player.Character:FindFirstChild(BOX_NAME)
			if player ~= tycoon.owner or not box then
				return
			end
			box:Destroy()
			tycoon:setStock(tycoon.stock + Config.StockPerBox)
			local earned = tycoon:reward(Config.DeliveryReward)
			Remotes.Notify:FireClient(player, `Shelves stocked! +{Format.money(earned)}`)
		end)
	end

	task.spawn(function()
		local slots: { [number]: BasePart? } = {}
		while tycoon.session == session do
			for slot = 1, Config.MaxBoxes do
				local box = slots[slot]
				if not box or box.Parent ~= tycoon.choresFolder then
					slots[slot] = nil
				end
			end
			for slot = 1, Config.MaxBoxes do
				if not slots[slot] and tycoon.stock < Config.MaxStock then
					local offset = Vector3.new((slot - 2) * 2.8, 1.2, 0)
					local box = Instance.new("Part")
					box.Name = BOX_NAME
					box.Anchored = true
					box.Size = Vector3.new(2, 2, 2)
					box.CFrame = tycoon.origin * CFrame.new(StationBuilder.DELIVERY_PAD + offset)
					box.Color = Color3.fromRGB(190, 140, 80)
					box.Material = Enum.Material.Cardboard
					local pickUpPrompt = prompt(box, "Pick Up", "Supply Box")
					pickUpPrompt.Triggered:Connect(function(player)
						if player == tycoon.owner and player.Character and pickUp(box, player.Character) then
							pickUpPrompt:Destroy()
						end
					end)
					box.Parent = tycoon.choresFolder
					slots[slot] = box
					break -- one new box per interval
				end
			end
			task.wait(Config.DeliveryInterval)
		end
	end)
end

-- Litter appears around the forecourt; the owner walks over it for a little cash
function Chores.runTrash(tycoon, session: number)
	local area = StationBuilder.TRASH_AREA
	local count = 0
	while tycoon.session == session do
		task.wait(Config.TrashInterval)
		if tycoon.session ~= session or count >= Config.MaxTrash then
			continue
		end
		local trash = Instance.new("Part")
		trash.Name = "Trash"
		trash.Anchored = true
		trash.CanCollide = false
		trash.Size = Vector3.new(1.4, 0.8, 1.1)
		trash.Color = TRASH_COLORS[math.random(#TRASH_COLORS)]
		trash.Material = Enum.Material.Plastic
		local x = math.random(area.minX, area.maxX)
		local z = math.random(area.minZ, area.maxZ)
		trash.CFrame = tycoon.origin * CFrame.new(x, 0.4, z) * CFrame.Angles(0, math.random() * math.pi, 0.3)
		StationBuilder.billboard(trash, "Trash!", 1.5)

		local collected = false
		trash.Touched:Connect(function(hit)
			if collected or tycoon.playerFromHit(hit) ~= tycoon.owner then
				return
			end
			collected = true
			count -= 1
			local earned = tycoon:reward(Config.TrashReward)
			trash:Destroy()
			if tycoon.owner then
				Remotes.Notify:FireClient(tycoon.owner, `Cleaned up! +{Format.money(earned)}`)
			end
		end)
		trash.Parent = tycoon.choresFolder
		count += 1
	end
end

return Chores
