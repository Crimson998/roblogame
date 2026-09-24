-- Builds a gas station's parts in code. Every position here is relative to the plot:
-- X runs left/right, the road is along +Z, the store is at the back (-Z), and y = 0 is the ground.
local StationBuilder = {}

StationBuilder.PUMP_X = { -21, -7, 7, 21 } -- where cars park for each pump
StationBuilder.PUMP_Z = 17
StationBuilder.ROAD_Z = 38
StationBuilder.BACK_LANE_Z = 4
StationBuilder.EXIT_X = 36
StationBuilder.DELIVERY_PAD = Vector3.new(42, 0, -8) -- boxes for the store show up here
StationBuilder.REBIRTH_SPOT = Vector3.new(-22, 0, -12)
StationBuilder.TRASH_AREA = { minX = -28, maxX = 28, minZ = -6, maxZ = 30 }

local COLORS = {
	Concrete = Color3.fromRGB(190, 190, 185),
	Asphalt = Color3.fromRGB(45, 45, 50),
	Yellow = Color3.fromRGB(245, 200, 40),
	White = Color3.fromRGB(240, 240, 240),
	Red = Color3.fromRGB(210, 40, 40),
	Blue = Color3.fromRGB(40, 110, 220),
	Cyan = Color3.fromRGB(60, 230, 255),
	Green = Color3.fromRGB(60, 200, 90),
	Beige = Color3.fromRGB(225, 205, 170),
	Gray = Color3.fromRGB(110, 110, 120),
	Dark = Color3.fromRGB(30, 30, 35),
}

local function block(
	parent: Instance,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Writes text on the side of a part that faces the road (+Z)
local function signText(part: BasePart, text: string, color: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
	return label
end

-- Floating text above a part
function StationBuilder.billboard(part: BasePart, text: string, height: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 80
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	return label
end

export type Base = {
	registerPad: BasePart,
	registerLabel: TextLabel,
	ownerLabel: TextLabel,
}

-- The parts every station has, owned or not
function StationBuilder.buildBase(parent: Instance, origin: CFrame): Base
	local function at(x, y, z)
		return origin * CFrame.new(x, y, z)
	end

	block(parent, at(0, -0.5, 0), Vector3.new(90, 1, 90), COLORS.Concrete, Enum.Material.Concrete).Name = "Ground"
	block(parent, at(0, 0.1, 38), Vector3.new(100, 0.2, 12), COLORS.Asphalt, Enum.Material.Asphalt).Name = "Road"
	block(parent, at(0, 0.22, 38), Vector3.new(100, 0.05, 0.4), COLORS.Yellow)

	-- Owner sign out front
	for _, x in { -11, 11 } do
		block(parent, at(x, 4, 47), Vector3.new(0.8, 8, 0.8), COLORS.Gray, Enum.Material.Metal)
	end
	local ownerBoard = block(parent, at(0, 8.5, 47), Vector3.new(24, 5, 0.6), COLORS.Dark)
	local ownerLabel = signText(ownerBoard, "Available", COLORS.Yellow)

	-- Cash register: cars pay into it, the owner steps on the pad to collect
	local booth = block(parent, at(0, 1.75, -15), Vector3.new(4, 3.5, 2.5), COLORS.Red)
	booth.Name = "Register"
	local registerLabel = StationBuilder.billboard(booth, "Register: $0", 4)
	local registerPad = block(parent, at(0, 0.15, -10), Vector3.new(6, 0.3, 6), COLORS.Green, Enum.Material.Neon)
	registerPad.Name = "CollectPad"

	return {
		registerPad = registerPad,
		registerLabel = registerLabel,
		ownerLabel = ownerLabel,
	}
end

local function buildPump(number: number)
	return function(parent: Instance, origin: CFrame)
		local x = StationBuilder.PUMP_X[number] + 4.5
		local z = StationBuilder.PUMP_Z
		block(parent, origin * CFrame.new(x, 0.25, z), Vector3.new(2.5, 0.5, 10), COLORS.Concrete, Enum.Material.Concrete)
		local pump = block(parent, origin * CFrame.new(x, 2.75, z), Vector3.new(1.8, 4.5, 2.4), COLORS.White)
		pump.Name = "Pump" .. number
		block(parent, origin * CFrame.new(x, 4.6, z), Vector3.new(1.9, 0.8, 2.5), COLORS.Red)
		block(parent, origin * CFrame.new(x - 0.95, 3.4, z), Vector3.new(0.1, 1, 1.4), COLORS.Cyan, Enum.Material.Neon)
		block(parent, origin * CFrame.new(x - 1, 2.2, z + 0.8), Vector3.new(0.3, 1.4, 0.3), COLORS.Dark)
		StationBuilder.billboard(pump, "#" .. number, 3.5)
	end
end

-- Keyed by item id from Items.luau. Items without an entry (upgrades) have no parts.
StationBuilder.items = {
	pump1 = buildPump(1),
	pump2 = buildPump(2),
	pump3 = buildPump(3),
	pump4 = buildPump(4),

	canopy = function(parent: Instance, origin: CFrame)
		block(parent, origin * CFrame.new(0, 14, 17), Vector3.new(60, 1.2, 18), COLORS.White)
		block(parent, origin * CFrame.new(0, 13.2, 17), Vector3.new(60.2, 0.6, 18.2), COLORS.Red)
		for _, x in { -28, 28 } do
			for _, z in { 10, 24 } do
				block(parent, origin * CFrame.new(x, 6.7, z), Vector3.new(1.5, 13.4, 1.5), COLORS.White)
			end
		end
	end,

	lights = function(parent: Instance, origin: CFrame)
		for _, z in { 7.8, 26.2 } do
			block(parent, origin * CFrame.new(0, 13.2, z), Vector3.new(60.4, 0.5, 0.5), COLORS.Cyan, Enum.Material.Neon)
		end
		for _, x in { -30.1, 30.1 } do
			block(parent, origin * CFrame.new(x, 13.2, 17), Vector3.new(0.5, 0.5, 18.4), COLORS.Cyan, Enum.Material.Neon)
		end
	end,

	sign = function(parent: Instance, origin: CFrame)
		block(parent, origin * CFrame.new(-42, 11, 31), Vector3.new(1, 22, 1), COLORS.Gray, Enum.Material.Metal)
		local board = block(parent, origin * CFrame.new(-42, 20, 31.2), Vector3.new(10, 7, 0.8), COLORS.Red)
		signText(board, "GAS\n$3.99", COLORS.White)
	end,

	store = function(parent: Instance, origin: CFrame)
		block(parent, origin * CFrame.new(0, 6, -30), Vector3.new(36, 12, 20), COLORS.Beige, Enum.Material.Brick)
		block(parent, origin * CFrame.new(0, 12.5, -30), Vector3.new(37, 1, 21), COLORS.Red)
		local window = block(parent, origin * CFrame.new(-4, 4, -19.9), Vector3.new(20, 6, 0.2), COLORS.Blue, Enum.Material.Glass)
		window.Transparency = 0.4
		block(parent, origin * CFrame.new(12, 4, -19.9), Vector3.new(5, 8, 0.2), COLORS.Dark).Name = "StoreDoor"
		local sign = block(parent, origin * CFrame.new(0, 10, -19.7), Vector3.new(16, 3, 0.4), COLORS.White)
		signText(sign, "QUICK MART", COLORS.Red)

		local pad = StationBuilder.DELIVERY_PAD
		local deliveryPad =
			block(parent, origin * CFrame.new(pad + Vector3.new(0, 0.1, 0)), Vector3.new(9, 0.2, 5), COLORS.Yellow)
		StationBuilder.billboard(deliveryPad, "Deliveries", 5)
	end,

	snacks = function(parent: Instance, origin: CFrame)
		block(parent, origin * CFrame.new(22, 3, -21.5), Vector3.new(3, 6, 2.4), COLORS.Blue)
		block(parent, origin * CFrame.new(22, 3.5, -20.25), Vector3.new(2.4, 4, 0.1), COLORS.Yellow, Enum.Material.Neon)
	end,

	billboard = function(parent: Instance, origin: CFrame)
		for _, x in { 39.5, 44.5 } do
			block(parent, origin * CFrame.new(x, 7, 18), Vector3.new(1, 14, 1), COLORS.Gray, Enum.Material.Metal)
		end
		local board = block(parent, origin * CFrame.new(42, 17, 18), Vector3.new(10, 6, 0.6), COLORS.Yellow)
		signText(board, "FUEL • FOOD • WASH", COLORS.Dark)
	end,

	carwash = function(parent: Instance, origin: CFrame)
		for _, x in { -43.5, -28.5 } do
			block(parent, origin * CFrame.new(x, 4.5, -30), Vector3.new(0.8, 9, 16), COLORS.White)
		end
		block(parent, origin * CFrame.new(-36, 9.5, -30), Vector3.new(16, 1, 16), COLORS.Blue)
		for _, x in { -39, -33 } do
			local brush = block(
				parent,
				origin * CFrame.new(x, 4, -30) * CFrame.Angles(0, 0, math.rad(90)),
				Vector3.new(7, 2.5, 2.5),
				COLORS.Cyan,
				Enum.Material.Fabric
			)
			brush.Shape = Enum.PartType.Cylinder
		end
		local sign = block(parent, origin * CFrame.new(-36, 11.2, -22), Vector3.new(14, 2.5, 0.4), COLORS.White)
		signText(sign, "CAR WASH", COLORS.Blue)
	end,

	garage = function(parent: Instance, origin: CFrame)
		block(parent, origin * CFrame.new(36, 6, -30), Vector3.new(16, 12, 20), COLORS.Gray, Enum.Material.Concrete)
		block(parent, origin * CFrame.new(36, 4, -19.9), Vector3.new(10, 8, 0.2), COLORS.Dark, Enum.Material.DiamondPlate)
		local sign = block(parent, origin * CFrame.new(36, 10.5, -19.7), Vector3.new(12, 2, 0.4), COLORS.Yellow)
		signText(sign, "REPAIRS", COLORS.Dark)
	end,
}

-- Where each item's buy button goes: a grid down the left side of the lot
function StationBuilder.buttonPosition(index: number): Vector3
	local column = (index - 1) % 2
	local row = math.floor((index - 1) / 2)
	return Vector3.new(-40 + column * 7, 0.2, 27 - row * 6)
end

return StationBuilder
