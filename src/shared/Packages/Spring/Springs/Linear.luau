local CONSTANTS = require(script.Parent.Parent.Constants)

local LinearSpring = {}

type TypeMetadata<T> = {
	springType: (dampingRatio: number, frequency: number, pos: number, typedat: TypeMetadata<T>, rawTarget: T) -> LinearSpring<T>,
	toIntermediate: (T) -> {number},
	fromIntermediate: ({number}) -> T,
}

type LinearSpring<T> = typeof(setmetatable({} :: {
	d: number,
	f: number,
	g: {number},
	p: {number},
	v: {number},
	typedat: TypeMetadata<T>,
	rawTarget: T,
}, LinearSpring))

LinearSpring.__index = LinearSpring

local function magnitudeSq(vec: {number})
	local out = 0
	for _, v in vec do
		out += v^2
	end
	return out
end

local function distanceSq(vec0: {number}, vec1: {number})
	local out = 0
	for i0, v0 in vec0 do
		out += (vec1[i0] - v0)^2
	end
	return out
end


function LinearSpring.new<T>(dampingRatio: number, frequency: number, pos: T, rawGoal: T, typedat)
	local linearPos = typedat.toIntermediate(pos)
	return setmetatable(
		{
			d = dampingRatio,
			f = frequency,
			g = linearPos,
			p = linearPos,
			v = table.create(#linearPos, 0),
			typedat = typedat,
			rawGoal = rawGoal
		},
		LinearSpring
	)
end

function LinearSpring.setGoal<T>(self, goal: T)
	self.rawGoal = goal
	self.g = self.typedat.toIntermediate(goal)
end

function LinearSpring.setDampingRatio<T>(self: LinearSpring<T>, dampingRatio: number)
	self.d = dampingRatio
end

function LinearSpring.setFrequency<T>(self: LinearSpring<T>, frequency: number)
	self.f = frequency
end

function LinearSpring.canSleep<T>(self)
	if magnitudeSq(self.v) > CONSTANTS.SLEEP_VELOCITY_SQ_LIMIT then
		return false
	end

	if distanceSq(self.p, self.g) > CONSTANTS.SLEEP_OFFSET_SQ_LIMIT then
		return false
	end

	return true
end

function LinearSpring.step<T>(self: LinearSpring<T>, dt: number)
	-- Advance the spring simulation by dt seconds.
	-- Take the damped harmonic oscillator ODE:
	--    f^2*(X[t] - g) + 2*d*f*X'[t] + X''[t] = 0
	-- Where X[t] is position at time t, g is target position,
	-- f is undamped angular frequency, and d is damping ratio.
	-- Apply constant initial conditions:
	--    X[0] = p0
	--    X'[0] = v0
	-- Solve the IVP to get analytic expressions for X[t] and X'[t].
	-- The solution takes one of three forms for 0<=d<1, d=1, and d>1

	local d = self.d
	local f = self.f*(2*math.pi) -- Hz -> Rad/s
	local g = self.g
	local p = self.p
	local v = self.v

	if d == 1 then -- critically damped
		local q = math.exp(-f*dt)
		local w = dt*q

		local c0 = q + w*f
		local c2 = q - w*f
		local c3 = w*f*f

		for idx = 1, #p do
			local o = p[idx] - g[idx]
			p[idx] = o*c0 + v[idx]*w + g[idx]
			v[idx] = v[idx]*c2 - o*c3
		end

	elseif d < 1 then -- underdamped
		local q = math.exp(-d*f*dt)
		local c = math.sqrt(1 - d*d)

		local i = math.cos(dt*f*c)
		local j = math.sin(dt*f*c)

		-- Damping ratios approaching 1 can cause division by very small numbers.
		-- To mitigate that, group terms around z=j/c and find an approximation for z.
		-- Start with the definition of z:
		--    z = math.sin(dt*f*c)/c
		-- Substitute a=dt*f:
		--    z = math.sin(a*c)/c
		-- Take the Maclaurin expansion of z with respect to c:
		--    z = a - (a^3*c^2)/6 + (a^5*c^4)/120 + O(c^6)
		--    z ≈ a - (a^3*c^2)/6 + (a^5*c^4)/120
		-- Rewrite in Horner form:
		--    z ≈ a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6

		local z
		if c > CONSTANTS.EPS then
			z = j/c
		else
			local a = dt*f
			z = a + ((a*a)*(c*c)*(c*c)/20 - c*c)*(a*a*a)/6
		end

		-- Frequencies approaching 0 present a similar problem.
		-- We want an approximation for y as f approaches 0, where:
		--    y = math.sin(dt*f*c)/(f*c)
		-- Substitute b=dt*c:
		--    y = math.sin(b*c)/b
		-- Now reapply the process from z.

		local y
		if f*c > CONSTANTS.EPS then
			y = j/(f*c)
		else
			local b = f*c
			y = dt + ((dt*dt)*(b*b)*(b*b)/20 - b*b)*(dt*dt*dt)/6
		end

		for idx = 1, #p do
			local o = p[idx] - g[idx]
			p[idx] = (o*(i + z*d) + v[idx]*y)*q + g[idx]
			v[idx] = (v[idx]*(i - z*d) - o*(z*f))*q
		end

	else -- overdamped
		local c = math.sqrt(d*d - 1)

		local r1 = -f*(d + c)
		local r2 = -f*(d - c)

		local ec1 = math.exp(r1*dt)
		local ec2 = math.exp(r2*dt)

		for idx = 1, #p do
			local o = p[idx] - g[idx]
			local co2 = (v[idx] - o*r1)/(2*f*c)
			local co1 = ec1*(o - co2)

			p[idx] = co1 + co2*ec2 + g[idx]
			v[idx] = co1*r1 + co2*ec2*r2
		end
	end

	return self.typedat.fromIntermediate(self.p)
end

return LinearSpring