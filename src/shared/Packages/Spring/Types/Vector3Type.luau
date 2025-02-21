local LinearSpring = require(script.Parent.Parent.Springs.Linear)

return {
	springType = LinearSpring.new,

	toIntermediate = function(value)
		return {value.X, value.Y, value.Z}
	end,

	fromIntermediate = function(value: {number})
		return Vector3.new(value[1], value[2], value[3])
	end,
}

