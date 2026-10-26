-- Server entry point. Loads every ModuleScript in Services/ and calls its init().
-- To add a system: create src/server/Services/<Name>Service.luau that returns a table with init().

local servicesFolder = script.Parent:WaitForChild("Services")

for _, module in servicesFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		local ok, service = pcall(require, module)
		if not ok then
			warn(`[Server] Failed to load {module.Name}: {service}`)
		elseif type(service) == "table" and type(service.init) == "function" then
			service.init()
			print(`[Server] Loaded {module.Name}`)
		end
	end
end
