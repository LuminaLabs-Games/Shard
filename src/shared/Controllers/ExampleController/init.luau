local ExampleController = {}
ExampleController.__index = ExampleController

type self = {
	new: () -> ExampleController,
	initialize: () -> (),
}

export type ExampleController = typeof(setmetatable({} :: self, ExampleController))

function ExampleController.new(): ExampleController
	local self = setmetatable({} :: self, ExampleController)

	return self
end

function ExampleController:initialize()
	
end


return ExampleController