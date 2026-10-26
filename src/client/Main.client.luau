-- Client entry point. Loads every ModuleScript in Controllers/ and calls its init().
-- To add a system: create src/client/Controllers/<Name>Controller.luau that returns a table with init().

local controllersFolder = script.Parent:WaitForChild("Controllers")

for _, module in controllersFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		local ok, controller = pcall(require, module)
		if not ok then
			warn(`[Client] Failed to load {module.Name}: {controller}`)
		elseif type(controller) == "table" and type(controller.init) == "function" then
			controller.init()
			print(`[Client] Loaded {module.Name}`)
		end
	end
end
