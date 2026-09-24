-- A simple customer car that drives between points.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local PAINT = {
	Color3.fromRGB(200, 40, 40),
	Color3.fromRGB(40, 90, 200),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(30, 30, 30),
	Color3.fromRGB(60, 170, 80),
	Color3.fromRGB(250, 190, 40),
	Color3.fromRGB(150, 60, 190),
}

local Car = {}
Car.__index = Car

Car.HEIGHT = 1.6 -- height of the body's center above the ground

export type Car = typeof(setmetatable({} :: { model: Model, body: Part }, Car))

function Car.new(parent: Instance, cframe: CFrame): Car
	local model = Instance.new("Model")
	model.Name = "Car"

	-- The body is anchored and moved by tweens; everything else is welded to it
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.Size = Vector3.new(5, 1.6, 10)
	body.CFrame = cframe
	body.Color = PAINT[math.random(#PAINT)]
	body.Parent = model
	model.PrimaryPart = body

	local function attach(size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): Part
		local part = Instance.new("Part")
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.Massless = true
		part.Size = size
		part.CFrame = body.CFrame * offset
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
		return part
	end

	attach(Vector3.new(4.4, 1.5, 5.5), CFrame.new(0, 1.55, 0.5), Color3.fromRGB(40, 50, 60), Enum.Material.Glass)
	for _, x in { -2.4, 2.4 } do
		for _, z in { -3.2, 3.2 } do
			local wheel = attach(Vector3.new(1, 2, 2), CFrame.new(x, -0.6, z), Color3.fromRGB(20, 20, 20))
			wheel.Shape = Enum.PartType.Cylinder
		end
		-- The front of the car is -Z, which is the way CFrame.lookAt faces
		attach(Vector3.new(1, 0.5, 0.1), CFrame.new(x * 0.65, 0.2, -5.05), Color3.fromRGB(255, 250, 200), Enum.Material.Neon)
	end

	model.Parent = parent
	return setmetatable({ model = model, body = body }, Car)
end

-- Turns toward `target` and drives there. Returns false if the car was removed on the way.
function Car.driveTo(self: Car, target: Vector3): boolean
	if not self.body.Parent then
		return false
	end
	local from = self.body.Position
	local distance = (target - from).Magnitude
	if distance < 0.05 then
		return true
	end
	self.body.CFrame = CFrame.lookAt(from, target)
	local duration = distance / Config.CarSpeed
	TweenService:Create(self.body, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(target, target + (target - from)),
	}):Play()
	task.wait(duration)
	return self.body.Parent ~= nil
end

function Car.popup(self: Car, text: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 40)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(90, 255, 120)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	gui.Parent = self.body
end

function Car.destroy(self: Car)
	self.model:Destroy()
end

return Car
