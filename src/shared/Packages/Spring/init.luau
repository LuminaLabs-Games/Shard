local RunService = game:GetService("RunService")

local Trove = require(script.Parent.Trove)
local Spring = {}
Spring.__index = Spring

local SpringTypes = require(script.Types.SpringTypes) 


local function udim2_add(a, b)
	return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
end

local function udim2_sub(a, b)
	return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
end

local function udim2_scale(a, scalar)
	return UDim2.new(a.X.Scale * scalar, a.X.Offset * scalar, a.Y.Scale * scalar, a.Y.Offset * scalar)
end

function Spring.new(instance, dampingRatio, frequency)
	local self = setmetatable({}, Spring)

	self.Instance = instance
	self.SpringType = SpringTypes[typeof(instance)]
	if not self.SpringType then
		error("Spring type not supported for " .. typeof(instance))
	end

	self.DampingRatio = dampingRatio
	self.Frequency = frequency

	self.Current = instance.Position
	self.Goal = instance.Position
	self.Velocity = UDim2.new(0, 0, 0, 0)
	self._trove = Trove.new()

	self._trove:Add(RunService.RenderStepped:Connect(function(deltaTime)
		self:Update(deltaTime)
	end))

	return self
end

function Spring:SetGoal(goal)
	self.Goal = goal
end

function Spring:Update(deltaTime)
	local f = self.Frequency * 2 * math.pi

	local delta = udim2_sub(self.Goal, self.Current)

	local acceleration = udim2_sub(udim2_scale(delta, f * f), udim2_scale(self.Velocity, 2 * self.DampingRatio * f))

	self.Velocity = udim2_add(self.Velocity, udim2_scale(acceleration, deltaTime))
	self.Current = udim2_add(self.Current, udim2_scale(self.Velocity, deltaTime))

	if self.Instance then
		self.Instance.Position = self.Current
	end
end

local function compareUDim2CurrentToGoal(current, goal) end

function Spring:Completed()
	while not compareUDim2CurrentToGoal(self.Current, self.Goal) do
		RunService.RenderStepped:Wait()
	end

	return true
end

return setmetatable(Spring, {
	__call = function(_, instance: Instance, dampingRatio: number, frequency: number)
		return Spring.new(instance, dampingRatio, frequency)
	end,
})
