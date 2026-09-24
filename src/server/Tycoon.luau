-- One gas station plot: its owner, what they've bought, the buy buttons, and the customers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Car = require(script.Parent.Car)
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

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

local function getCash(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Cash") :: IntValue?
end

local Tycoon = {}
Tycoon.__index = Tycoon

function Tycoon.new(index: number, origin: CFrame, parent: Instance)
	local self = setmetatable({}, Tycoon)
	self.origin = origin
	self.owner = nil :: Player?
	self.purchased = {} :: { [string]: boolean }
	self.pumps = {} :: { [number]: { busy: boolean } }
	self.buttons = {} :: { [string]: BasePart }
	self.registerCash = 0
	-- Bumped on every claim/release, so cars and loops from a previous owner stop
	self.session = 0
	self.cashConnection = nil :: RBXScriptConnection?

	self.model = Instance.new("Model")
	self.model.Name = "Station" .. index
	self.base = StationBuilder.buildBase(self.model, origin)

	self.itemsFolder = Instance.new("Folder")
	self.itemsFolder.Name = "Items"
	self.itemsFolder.Parent = self.model
	self.buttonsFolder = Instance.new("Folder")
	self.buttonsFolder.Name = "Buttons"
	self.buttonsFolder.Parent = self.model
	self.carsFolder = Instance.new("Folder")
	self.carsFolder.Name = "Cars"
	self.carsFolder.Parent = self.model

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

-- Adds up the effects of everything the owner has bought
function Tycoon:getStats()
	local stats = { bonus = 0, multiplier = 1, spawnRate = 1, fuelTime = 1 }
	for _, item in Items do
		if self.purchased[item.id] then
			local effects = item.effects
			stats.bonus += effects.bonus or 0
			stats.multiplier *= effects.multiplier or 1
			stats.spawnRate *= effects.spawnRate or 1
			stats.fuelTime *= effects.fuelTime or 1
		end
	end
	return stats
end

function Tycoon:carPayment(): number
	local stats = self:getStats()
	return math.floor((Config.FuelPrice + stats.bonus) * stats.multiplier)
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
end

function Tycoon:purchase(id: string)
	local owner = self.owner
	local item = itemsById[id]
	local cash = owner and getCash(owner)
	if not (owner and item and cash and self:canBuy(item)) then
		return
	end
	if cash.Value < item.price then
		return -- the button is red; nothing to do
	end
	cash.Value -= item.price
	self:unlock(id)
	self:refreshButtons()
	Remotes.Notify:FireClient(owner, `Bought {item.name}! Cars now pay {Format.money(self:carPayment())}`)
end

function Tycoon:recolorButtons()
	local cash = self.owner and getCash(self.owner)
	for id, button in self.buttons do
		local affordable = cash ~= nil and cash.Value >= itemsById[id].price
		button.Color = if affordable then AFFORDABLE else TOO_EXPENSIVE
	end
end

-- Shows a button for each item the owner can buy next, and removes the rest
function Tycoon:refreshButtons()
	for _, item in Items do
		local shouldShow = self.owner ~= nil and self:canBuy(item)
		local button = self.buttons[item.id]
		if shouldShow and not button then
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

			local busy = false
			pad.Touched:Connect(function(hit)
				if busy or playerFromHit(hit) ~= self.owner then
					return
				end
				busy = true
				self:purchase(item.id)
				busy = false
			end)
			self.buttons[item.id] = pad
		elseif not shouldShow and button then
			button:Destroy()
			self.buttons[item.id] = nil
		end
	end
	self:recolorButtons()
end

function Tycoon:setRegister(amount: number)
	self.registerCash = amount
	self.base.registerLabel.Text = "Register: " .. Format.money(amount)
end

-- Moves the register's money into the owner's Cash
function Tycoon:collect()
	local cash = self.owner and getCash(self.owner)
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

-- One customer: road -> pump -> pay -> back lane -> exit
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
	if arrived then
		task.wait(Config.FuelTime * self:getStats().fuelTime)
	end
	pump.busy = false
	if not arrived or self.session ~= session then
		car:destroy()
		return
	end

	local payment = self:carPayment()
	self:setRegister(self.registerCash + payment)
	car:popup("+" .. Format.money(payment))

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
	for _, id in savedPurchases do
		self:unlock(id)
	end
	self:refreshButtons()

	local cash = getCash(player)
	if cash then
		self.cashConnection = cash.Changed:Connect(function()
			self:recolorButtons()
		end)
	end

	task.spawn(self.runCustomers, self, self.session)
end

-- Clears the plot so another player can take it
function Tycoon:release()
	self.session += 1
	self.owner = nil
	self.purchased = {}
	self.pumps = {}
	self.buttons = {}
	if self.cashConnection then
		self.cashConnection:Disconnect()
		self.cashConnection = nil
	end
	self.itemsFolder:ClearAllChildren()
	self.buttonsFolder:ClearAllChildren()
	self.carsFolder:ClearAllChildren()
	self:setRegister(0)
	self.base.ownerLabel.Text = "Available"
end

return Tycoon
