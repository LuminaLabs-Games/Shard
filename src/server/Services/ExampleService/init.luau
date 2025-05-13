local ExampleService = {}
ExampleService.__index = ExampleService

type self = {
	new: () -> ExampleService,
	initialize: () -> (),
	start: () -> ()
}

export type ExampleService = typeof(setmetatable({} :: self, ExampleService))

function ExampleService.new(): ExampleService
	local self = setmetatable({} :: self, ExampleService)

	return self
end

function ExampleService:initialize()

end

function ExampleService:start()
	
end

return ExampleService