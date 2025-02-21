local RotationSpring = {} 

type RotationSpring = typeof(setmetatable({} :: {
	d: number,
	f: number,
	g: CFrame,
	p: CFrame,
	v: Vector3,
}, RotationSpring))

RotationSpring.__index = RotationSpring

function RotationSpring.new(d: number, f: number, p: CFrame, g: CFrame)
	return setmetatable(
		{
			d = d,
			f = f,
			g = g:Orthonormalize(),
			p = p:Orthonormalize(),
			v = Vector3.zero
		},
		RotationSpring
	)
end

function RotationSpring.setGoal(self: RotationSpring, value: CFrame)
	self.g = value:Orthonormalize()
end

function RotationSpring.setDampingRatio(self: RotationSpring, dampingRatio: number)
	self.d = dampingRatio
end

function RotationSpring.setFrequency(self: RotationSpring, frequency: number)
	self.f = frequency
end

-- evaluate dot products in high precision
local function dot(v0: Vector3, v1: Vector3)
	return v0.X*v1.X + v0.Y*v1.Y + v0.Z*v1.Z
end

local function areRotationsClose(c0: CFrame, c1: CFrame)
	local rx = dot(c0.XVector, c1.XVector)
	local ry = dot(c0.YVector, c1.YVector)
	local rz = dot(c0.ZVector, c1.ZVector)
	local trace = rx + ry + rz
	return trace > 1 + 2*cos(SLEEP_ROTATION_DIFF)
end

local function angleDiff(c0: CFrame, c1: CFrame)
	local x = dot(c0.XVector, c1.XVector)
	local y = dot(c0.YVector, c1.YVector)
	local z = dot(c0.ZVector, c1.ZVector)
	local w = x + y + z - 1
	return atan2(sqrt(max(0, 1 - w*w*0.25)), w*0.5)
end

-- gives approx. 21% accuracy improvement over CFrame.fromAxisAngle near poles
local function fromAxisAngle(axis: Vector3, angle: number)
	local c = cos(angle)
	local s = sin(angle)
	local x, y, z = axis.X, axis.Y, axis.Z

	local mxy = x*y*(1 - c)
	local myz = y*z*(1 - c)
	local mzx = z*x*(1 - c)

	local rx = Vector3.new(x*x*(1 - c) + c, mxy + z*s, mzx - y*s)
	local ry = Vector3.new(mxy - z*s, y*y*(1 - c) + c, myz + x*s)
	local rz = Vector3.new(mzx + y*s, myz - x*s, z*z*(1 - c) + c)

	return CFrame.fromMatrix(Vector3.zero, rx, ry, rz):Orthonormalize()
end

local function rotateAxis(r0: Vector3, c1: CFrame)
	local c0 = CFrame.identity
	local mag = r0.Magnitude
	if mag > 1e-6 then
		c0 = fromAxisAngle(r0.Unit, mag)
	end
	return c0 * c1
end

-- axis*angle difference between two cframes
local function axisAngleDiff(c0: CFrame, c1: CFrame)
	-- use native axis (stable enough)
	local axis = (c0*c1:Inverse()):ToAxisAngle()
	
	-- use full-precision angle calculation to minimize truncation
	local angle = angleDiff(c0, c1)
	return axis.Unit*angle
end

function RotationSpring.canSleep(self: RotationSpring)
	local sleepP = areRotationsClose(self.p, self.g)
	local sleepV = self.v.Magnitude < SLEEP_ROTATION_VELOCITY
	return sleepP and sleepV
end

function RotationSpring.step(self: RotationSpring, dt: number): CFrame
	local d = self.d
	local f = self.f*(2*pi)
	local g = self.g
	local p0 = self.p
	local v0 = self.v

	local offset = axisAngleDiff(p0, g)
	local decay = exp(-d*f*dt)

	local pt: CFrame
	local vt: Vector3

	if d == 1 then -- critically damped
		pt = rotateAxis((offset*(1 + f*dt) + v0*dt)*decay, g)
		vt = (v0*(1 - dt*f) - offset*(dt*f*f))*decay

	elseif d < 1 then -- underdamped
		local c = sqrt(1 - d*d)

		local i = cos(dt*f*c)
		local j = sin(dt*f*c)

		local y = j/(f*c)
		local z = j/c

		pt = rotateAxis((offset*(i + z*d) + v0*y)*decay, g)
		vt = (v0*(i - z*d) - offset*(z*f))*decay

	else -- overdamped
		local c = sqrt(d*d - 1)

		local r1 = -f*(d + c)
		local r2 = -f*(d - c)

		local co2 = (v0 - offset*r1)/(2*f*c)
		local co1 = offset - co2

		local e1 = co1*exp(r1*dt)
		local e2 = co2*exp(r2*dt)

		pt = rotateAxis(e1 + e2, g)
		vt = e1*r1 + e2*r2
	end

	self.p = pt
	self.v = vt

	return pt
end

