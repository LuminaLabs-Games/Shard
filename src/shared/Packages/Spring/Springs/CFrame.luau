local CFrameSpring = {}
CFrameSpring.__index = CFrameSpring

function CFrameSpring.new(
	dampingRatio: number,
	frequency: number,
	valueCurrent: CFrame,
	valueGoal: CFrame,
	_: any
)
	return setmetatable(
		{
			rawGoal = valueGoal,
			_position = LinearSpring.new(dampingRatio, frequency, valueCurrent.Position, valueGoal.Position, typeMetadata_Vector3),
			_rotation = RotationSpring.new(dampingRatio, frequency, valueCurrent.Rotation, valueGoal.Rotation)
		},
		CFrameSpring
	)
end

function CFrameSpring:setGoal(value: CFrame)
	self.rawGoal = value
	self._position:setGoal(value.Position)
	self._rotation:setGoal(value.Rotation)
end

function CFrameSpring:setDampingRatio(value: number)
	self._position.d = value
	self._rotation.d = value
end

function CFrameSpring:setFrequency(value: number)
	self._position.f = value
	self._rotation.f = value
end

function CFrameSpring:canSleep()
	return self._position:canSleep() and self._rotation:canSleep()
end

function CFrameSpring:step(dt): CFrame
	local p: Vector3 = self._position:step(dt)
	local r: CFrame = self._rotation:step(dt)
	return r + p
end
