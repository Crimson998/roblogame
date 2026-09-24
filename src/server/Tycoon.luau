-- One gas station plot: its owner, what they've bought, the buy buttons, and the customers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Car = require(script.Parent.Car)
local Chores = require(script.Parent.Chores)
local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(script.Parent.Remotes)
local StationBuilder = require(script.Parent.StationBuilder)

local itemsById = {}
local buttonIndex = {}
for index, item in Items do
	itemsById[item.id] = item
	buttonIndex[item.id] = index
end

local AFFORDABLE = Color3.fromRGB(60, 200, 90)
local TOO_EXPENSIVE = Color3.fromRGB(200, 60, 60)
local ANGRY = Color3.fromRGB(255, 90, 90)
local DEFAULT_WALK_SPEED = 16

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

local function getStat(player: Player, name: string): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild(name) :: IntValue?
end

local Tycoon = {}
Tycoon.__index = Tycoon
Tycoon.playerFromHit = playerFromHit

function Tycoon.new(index: number, origin: CFrame, parent: Instance)
	local self = setmetatable({}, Tycoon)
	self.origin = origin
	self.owner = nil :: Player?
	self.purchased = {} :: { [string]: boolean }
	self.pumps = {} :: { [number]: { busy: boolean } }
	self.buttons = {} :: { [string]: BasePart }
	self.registerCash = 0
	self.stock = 0
	self.streak = 0
	-- Bumped on every claim/reset, so cars and loops from a previous owner stop
	self.session = 0
	self.cashConnection = nil :: RBXScriptConnection?

	self.model = Instance.new("Model")
	self.model.Name = "Station" .. index
	self.base = StationBuilder.buildBase(self.model, origin)

	local function folder(name: string): Folder
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = self.model
		return f
	end
	self.itemsFolder = folder("Items")
	self.buttonsFolder = folder("Buttons")
	self.carsFolder = folder("Cars")
	self.choresFolder = folder("Chores")

	self.model.Parent = parent

	self.base.registerPad.Touched:Connect(function(hit)
		if self.owner and playerFromHit(hit) == self.owner then
			self:collect()
		end
	end)

	return self
end

function Tycoon:spawnCFrame(): CFrame
	return self.origin * CFrame.new(-12, 4, -8)
end

function Tycoon:rebirthMultiplier(): number
	local rebirths = self.owner and getStat(self.owner, "Rebirths")
	return 1 + (if rebirths then rebirths.Value else 0) * Config.RebirthBonus
end

-- Pays the owner directly, with the rebirth boost applied
function Tycoon:reward(amount: number): number
	local cash = self.owner and getStat(self.owner, "Cash")
	local total = math.floor(amount * self:rebirthMultiplier())
	if cash then
		cash.Value += total
	end
	return total
end

-- Adds up the effects of everything the owner has bought
function Tycoon:getStats()
	local stats = {
		bonus = 0,
		stockBonus = 0,
		multiplier = 1,
		spawnRate = 1,
		fuelTime = 1,
		autoServe = false,
		walkSpeed = DEFAULT_WALK_SPEED,
	}
	for _, item in Items do
		if self.purchased[item.id] then
			local effects = item.effects
			if item.needsStock then
				stats.stockBonus += effects.bonus or 0
			else
				stats.bonus += effects.bonus or 0
			end
			stats.multiplier *= effects.multiplier or 1
			stats.spawnRate *= effects.spawnRate or 1
			stats.fuelTime *= effects.fuelTime or 1
			stats.autoServe = stats.autoServe or effects.autoServe ~= nil
			stats.walkSpeed = math.max(stats.walkSpeed, effects.walkSpeed or 0)
		end
	end
	return stats
end

-- What a car pays. Uses up one stock if the store has any.
function Tycoon:takePayment(): number
	local stats = self:getStats()
	local bonus = stats.bonus
	if self.stock > 0 and stats.stockBonus > 0 then
		bonus += stats.stockBonus
		self:setStock(self.stock - 1)
	end
	return math.floor((Config.FuelPrice + bonus) * stats.multiplier * self:rebirthMultiplier())
end

function Tycoon:setStock(amount: number)
	self.stock = math.clamp(amount, 0, Config.MaxStock)
	if self.owner then
		self.owner:SetAttribute("Stock", if self.purchased.store then self.stock else nil)
	end
end

function Tycoon:setStreak(amount: number)
	self.streak = amount
	if self.owner then
		self.owner:SetAttribute("Streak", amount)
	end
end

function Tycoon:getPurchasedList(): { string }
	local list = {}
	for _, item in Items do
		if self.purchased[item.id] then
			table.insert(list, item.id)
		end
	end
	return list
end

function Tycoon:canBuy(item): boolean
	if self.purchased[item.id] then
		return false
	end
	for _, required in item.requires do
		if not self.purchased[required] then
			return false
		end
	end
	return true
end

function Tycoon:ownsEverything(): boolean
	for _, item in Items do
		if not self.purchased[item.id] then
			return false
		end
	end
	return true
end

function Tycoon:applyWalkSpeed()
	local character = self.owner and self.owner.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = self:getStats().walkSpeed
	end
end

-- Builds an item's parts and applies its effects (no payment; used for loading saves too)
function Tycoon:unlock(id: string)
	local item = itemsById[id]
	if not item or self.purchased[id] then
		return
	end
	self.purchased[id] = true
	local build = StationBuilder.items[id]
	if build then
		build(self.itemsFolder, self.origin)
	end
	if item.effects.pump then
		self.pumps[item.effects.pump] = { busy = false }
	end
	if item.effects.walkSpeed then
		self:applyWalkSpeed()
	end
	if id == "store" then
		Chores.setupStore(self, self.session)
		self:setStock(Config.StockPerBox * 2) -- a little stock to start with
	end
end

function Tycoon:purchase(id: string)
	local owner = self.owner
	local item = itemsById[id]
	local cash = owner and getStat(owner, "Cash")
	if not (owner and item and cash and self:canBuy(item)) then
		return
	end
	if cash.Value < item.price then
		return -- the button is red; nothing to do
	end
	cash.Value -= item.price
	self:unlock(id)
	self:refreshButtons()

	local message = `Bought {item.name}!`
	if id == "store" then
		message ..= " Carry boxes from the yellow pad to the store door to keep it stocked."
	elseif id == "selfserve" then
		message ..= " Cars now fill up by themselves if you're busy."
	end
	Remotes.Notify:FireClient(owner, message)
end

function Tycoon:rebirth()
	local owner = self.owner
	if not owner or not self:ownsEverything() then
		return
	end
	local rebirths = getStat(owner, "Rebirths") :: IntValue
	local cash = getStat(owner, "Cash") :: IntValue
	rebirths.Value += 1
	cash.Value = 0
	self:reset()
	self:claim(owner, {})
	Remotes.Notify:FireClient(
		owner,
		`Rebirth #{rebirths.Value}! You now earn x{self:rebirthMultiplier()} on everything.`
	)
end

-- Tells the HUD what to aim for next
function Tycoon:updateGoal()
	if not self.owner then
		return
	end
	local cheapest
	for _, item in Items do
		if self:canBuy(item) and (not cheapest or item.price < cheapest.price) then
			cheapest = item
		end
	end
	local goal = if cheapest
		then `Next: {cheapest.name} ({Format.money(cheapest.price)})`
		else "Station complete! Rebirth at the purple pillar."
	self.owner:SetAttribute("Goal", goal)
end

function Tycoon:recolorButtons()
	local cash = self.owner and getStat(self.owner, "Cash")
	for id, button in self.buttons do
		local affordable = cash ~= nil and cash.Value >= itemsById[id].price
		button.Color = if affordable then AFFORDABLE else TOO_EXPENSIVE
	end
end

local function makeButton(self, item)
	local position = StationBuilder.buttonPosition(buttonIndex[item.id])
	local pad = Instance.new("Part")
	pad.Name = item.id .. "Button"
	pad.Anchored = true
	pad.Size = Vector3.new(5, 0.4, 5)
	pad.CFrame = self.origin * CFrame.new(position)
	pad.Material = Enum.Material.Neon
	pad.TopSurface = Enum.SurfaceType.Smooth
	local price = if item.price == 0 then "FREE" else Format.money(item.price)
	StationBuilder.billboard(pad, `{item.name}\n{price}`, 3)
	pad.Parent = self.buttonsFolder

	pad.Touched:Connect(function(hit)
		if playerFromHit(hit) == self.owner then
			self:purchase(item.id)
		end
	end)
	return pad
end

local function makeRebirthPillar(self)
	local pillar = Instance.new("Part")
	pillar.Name = "RebirthButton"
	pillar.Anchored = true
	pillar.Size = Vector3.new(3, 8, 3)
	pillar.CFrame = self.origin * CFrame.new(StationBuilder.REBIRTH_SPOT + Vector3.new(0, 4, 0))
	pillar.Color = Color3.fromRGB(170, 80, 255)
	pillar.Material = Enum.Material.Neon
	StationBuilder.billboard(pillar, "REBIRTH", 6)

	local nextMultiplier = self:rebirthMultiplier() + Config.RebirthBonus
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = `Rebirth (x{nextMultiplier} income)`
	prompt.ObjectText = "Resets your station and cash"
	prompt.HoldDuration = 2
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player)
		if player == self.owner then
			self:rebirth()
		end
	end)
	prompt.Parent = pillar
	pillar.Parent = self.buttonsFolder
	return pillar
end

-- Shows a button for each item the owner can buy next, and removes the rest
function Tycoon:refreshButtons()
	for _, item in Items do
		local shouldShow = self.owner ~= nil and self:canBuy(item)
		local button = self.buttons[item.id]
		if shouldShow and not button then
			self.buttons[item.id] = makeButton(self, item)
		elseif not shouldShow and button then
			button:Destroy()
			self.buttons[item.id] = nil
		end
	end
	if self.owner and self:ownsEverything() and not self.rebirthPillar then
		self.rebirthPillar = makeRebirthPillar(self)
	end
	self:recolorButtons()
	self:updateGoal()
end

function Tycoon:setRegister(amount: number)
	self.registerCash = amount
	self.base.registerLabel.Text = "Register: " .. Format.money(amount)
end

-- Moves the register's money into the owner's Cash
function Tycoon:collect()
	local cash = self.owner and getStat(self.owner, "Cash")
	if not cash or self.registerCash <= 0 then
		return
	end
	cash.Value += self.registerCash
	self:setRegister(0)
end

function Tycoon:findFreePump(): number?
	for number, pump in self.pumps do
		if not pump.busy then
			return number
		end
	end
	return nil
end

-- Waits at the pump until the owner serves the car, self-service kicks in, or the customer gives up.
-- Returns "served", "auto" or "angry", plus how much patience was left.
local function waitForService(self, session: number, car): (string, number)
	local stats = self:getStats()
	local autoTime = if stats.autoServe then Config.AutoFuelTime * stats.fuelTime else math.huge
	local servedBy: Player? = nil

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Fill Up"
	prompt.ObjectText = "Customer"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player)
		if player == self.owner then
			servedBy = player
		end
	end)
	prompt.Parent = car.body
	car:showPatience()

	local started = os.clock()
	local outcome = "angry"
	while self.session == session and car.body.Parent do
		local waited = os.clock() - started
		if servedBy then
			outcome = "served"
			break
		elseif waited >= autoTime then
			outcome = "auto"
			break
		elseif waited >= Config.Patience then
			break
		end
		car:setPatience(1 - waited / Config.Patience)
		task.wait(0.1)
	end

	prompt:Destroy()
	car:hidePatience()
	return outcome, math.max(0, 1 - (os.clock() - started) / Config.Patience)
end

-- One customer: road -> pump -> wait for service -> pay -> back lane -> exit
function Tycoon:serveCar(session: number, pumpNumber: number)
	local pump = self.pumps[pumpNumber]
	local function at(x: number, z: number): Vector3
		return self.origin * Vector3.new(x, Car.HEIGHT, z)
	end
	local x = StationBuilder.PUMP_X[pumpNumber]
	local roadZ = StationBuilder.ROAD_Z
	local backZ = StationBuilder.BACK_LANE_Z
	local exitX = StationBuilder.EXIT_X

	local start = at(-48, roadZ)
	local car = Car.new(self.carsFolder, CFrame.lookAt(start, at(0, roadZ)))

	local arrived = car:driveTo(at(x, roadZ)) and car:driveTo(at(x, StationBuilder.PUMP_Z))
	local outcome, patienceLeft = "angry", 0
	if arrived and self.session == session then
		outcome, patienceLeft = waitForService(self, session, car)
	end
	pump.busy = false
	if not arrived or self.session ~= session then
		car:destroy()
		return
	end

	if outcome == "served" then
		-- Serving it yourself pays straight into your pocket, with a tip and streak bonus
		self:setStreak(self.streak + 1)
		local tip = Config.MaxTip * patienceLeft
		local streakBonus = math.min(self.streak * Config.StreakBonus, Config.MaxStreakBonus)
		local total = math.floor(self:takePayment() * (1 + tip) * (1 + streakBonus))
		local cash = self.owner and getStat(self.owner, "Cash")
		if cash then
			cash.Value += total
		end
		car:popup(`+{Format.money(total)}`)
	elseif outcome == "auto" then
		local payment = self:takePayment()
		self:setRegister(self.registerCash + payment)
		car:popup(`+{Format.money(payment)}`)
	else
		if self.streak >= 3 and self.owner then
			Remotes.Notify:FireClient(self.owner, `A customer left! Streak of {self.streak} lost.`)
		end
		self:setStreak(0)
		car:popup("Too slow!", ANGRY)
	end

	local _ = car:driveTo(at(x, backZ))
		and car:driveTo(at(exitX, backZ))
		and car:driveTo(at(exitX, roadZ))
		and car:driveTo(at(52, roadZ))
	car:destroy()
end

function Tycoon:runCustomers(session: number)
	while self.session == session do
		task.wait(Config.CarSpawnInterval * self:getStats().spawnRate)
		if self.session ~= session then
			break
		end
		local pumpNumber = self:findFreePump()
		if pumpNumber then
			self.pumps[pumpNumber].busy = true
			task.spawn(self.serveCar, self, session, pumpNumber)
		end
	end
end

function Tycoon:claim(player: Player, savedPurchases: { string })
	self.session += 1
	self.owner = player
	self.base.ownerLabel.Text = `{player.DisplayName}'s Gas Station`
	self:setStreak(0)
	for _, id in savedPurchases do
		self:unlock(id)
	end
	self:setStock(self.stock)
	self:refreshButtons()
	self:applyWalkSpeed()

	local cash = getStat(player, "Cash")
	if cash then
		self.cashConnection = cash.Changed:Connect(function()
			self:recolorButtons()
		end)
	end

	task.spawn(self.runCustomers, self, self.session)
	task.spawn(Chores.runTrash, self, self.session)
end

-- Clears everything built on the plot (the owner stays, if any)
function Tycoon:reset()
	self.session += 1
	self.purchased = {}
	self.pumps = {}
	self.buttons = {}
	self.rebirthPillar = nil
	self.stock = 0
	if self.cashConnection then
		self.cashConnection:Disconnect()
		self.cashConnection = nil
	end
	self.itemsFolder:ClearAllChildren()
	self.buttonsFolder:ClearAllChildren()
	self.carsFolder:ClearAllChildren()
	self.choresFolder:ClearAllChildren()
	self:setRegister(0)
	if self.owner then
		self.owner:SetAttribute("Stock", nil)
		self:applyWalkSpeed()
	end
end

-- Frees the plot so another player can take it
function Tycoon:release()
	self:reset()
	self.owner = nil
	self.base.ownerLabel.Text = "Available"
end

return Tycoon
