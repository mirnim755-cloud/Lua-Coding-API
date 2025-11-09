--[[
	SnippetLibrary.lua

	Manages snippet definitions, storage, and template expansion for the Lua Autocomplete plugin.
	Provides all default snippets and handles custom snippet persistence.
]]

local SnippetLibrary = {}

-- Custom snippets storage (populated from plugin settings)
local customSnippets = {}

-- Default snippet library - 24 snippets across three tiers
local DEFAULT_SNIPPETS = {
	-- Essential (6 snippets)
	{
		name = "service",
		description = "game:GetService() with variable",
		template = 'local $1 = game:GetService("$2")',
		category = "essential",
		tags = {"variable", "service", "initialization"}
	},
	{
		name = "function",
		description = "Function skeleton",
		template = "local function $1($2)\n\t$0\nend",
		category = "essential",
		tags = {"function", "declaration"}
	},
	{
		name = "module",
		description = "ModuleScript template",
		template = "local $1 = {}\n\nfunction $1:$2($3)\n\t$0\nend\n\nreturn $1",
		category = "essential",
		tags = {"module", "class", "structure"}
	},
	{
		name = "remote",
		description = "RemoteEvent handler",
		template = "$1.OnServerEvent:Connect(function($2)\n\t$0\nend)",
		category = "essential",
		tags = {"remote", "event", "server"}
	},
	{
		name = "wait",
		description = "task.wait() loop",
		template = "while true do\n\ttask.wait($1)\n\t$0\nend",
		category = "essential",
		tags = {"loop", "wait", "task"}
	},
	{
		name = "ifelse",
		description = "if/else statement",
		template = "if $1 then\n\t$2\nelse\n\t$3\nend",
		category = "essential",
		tags = {"conditional", "control"}
	},

	-- Common Patterns (8 snippets)
	{
		name = "for",
		description = "Numeric for loop",
		template = "for i = $1, $2 do\n\t$0\nend",
		category = "common",
		tags = {"loop", "iteration"}
	},
	{
		name = "forin",
		description = "pairs() iterator",
		template = "for key, value in pairs($1) do\n\t$0\nend",
		category = "common",
		tags = {"loop", "iteration", "table"}
	},
	{
		name = "while",
		description = "While loop",
		template = "while $1 do\n\t$0\nend",
		category = "common",
		tags = {"loop", "conditional"}
	},
	{
		name = "spawn",
		description = "Character spawn handler with humanoid check",
		template = 'Players.PlayerAdded:Connect(function(player)\n\tplayer.CharacterAdded:Connect(function(character)\n\t\tlocal humanoid = character:WaitForChild("Humanoid")\n\t\thumanoid.Died:Connect(function()\n\t\t\t$1\n\t\tend)\n\t\t$0\n\tend)\nend)',
		category = "common",
		tags = {"player", "character", "event"}
	},
	{
		name = "tween",
		description = "TweenService pattern",
		template = "local tween = TweenService:Create($1, TweenInfo.new($2), {$3})\ntween:Play()",
		category = "common",
		tags = {"animation", "tween"}
	},
	{
		name = "signal",
		description = "BindableEvent signal pattern",
		template = 'local signal = Instance.new("BindableEvent")\nsignal.Event:Connect(function($1)\n\t$0\nend)',
		category = "common",
		tags = {"signal", "event", "bindable"}
	},
	{
		name = "part",
		description = "Create Part instance",
		template = 'local part = Instance.new("Part")\npart.Parent = $1\n$0',
		category = "common",
		tags = {"instance", "part", "creation"}
	},
	{
		name = "pcall",
		description = "Protected call with error handling",
		template = "local success, result = pcall(function()\n\t$1\nend)\nif not success then\n\twarn(result)\nend\n$0",
		category = "common",
		tags = {"error", "safety", "pcall"}
	},

	-- Advanced (10 snippets)
	{
		name = "class",
		description = "OOP class pattern with constructor and methods",
		template = "local $1 = {}\n$1.__index = $1\n\nfunction $1.new($2)\n\tlocal self = setmetatable({}, $1)\n\t$3\n\treturn self\nend\n\nfunction $1:$4($5)\n\t$0\nend\n\nreturn $1",
		category = "advanced",
		tags = {"class", "oop", "constructor"}
	},
	{
		name = "enum",
		description = "Enum-style readonly table",
		template = "local $1 = {\n\t$2 = $3,\n}\nsetmetatable($1, {\n\t__index = function(_, key)\n\t\terror(string.format(\"Invalid enum key: %s\", tostring(key)), 2)\n\tend,\n\t__newindex = function()\n\t\terror(\"Cannot modify enum\", 2)\n\tend\n})\n$0",
		category = "advanced",
		tags = {"enum", "constant", "readonly"}
	},
	{
		name = "maid",
		description = "Maid cleanup pattern for managing connections",
		template = "local Maid = {}\nMaid.__index = Maid\n\nfunction Maid.new()\n\treturn setmetatable({_tasks = {}}, Maid)\nend\n\nfunction Maid:GiveTask(task)\n\ttable.insert(self._tasks, task)\nend\n\nfunction Maid:DoCleaning()\n\tfor _, task in ipairs(self._tasks) do\n\t\tif typeof(task) == \"RBXScriptConnection\" then\n\t\t\ttask:Disconnect()\n\t\telseif typeof(task) == \"function\" then\n\t\t\ttask()\n\t\tend\n\tend\n\tself._tasks = {}\nend\n\nreturn Maid",
		category = "advanced",
		tags = {"cleanup", "maid", "memory"}
	},
	{
		name = "promise",
		description = "Promise-like async pattern",
		template = "local function $1($2)\n\treturn coroutine.wrap(function()\n\t\t$3\n\t\treturn $0\n\tend)()\nend",
		category = "advanced",
		tags = {"async", "promise", "coroutine"}
	},
	{
		name = "datastore",
		description = "DataStoreService with error handling",
		template = 'local DataStoreService = game:GetService("DataStoreService")\nlocal dataStore = DataStoreService:GetDataStore("$1")\n\nlocal success, result = pcall(function()\n\treturn dataStore:GetAsync($2)\nend)\nif success then\n\t$0\nelse\n\twarn("DataStore error:", result)\nend',
		category = "advanced",
		tags = {"datastore", "persistence", "data"}
	},
	{
		name = "profileservice",
		description = "ProfileService data loading pattern",
		template = 'local ProfileService = require($1)\nlocal ProfileStore = ProfileService.GetProfileStore("$2", {})\n\nlocal function loadProfile(player)\n\tlocal profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)\n\tif profile then\n\t\tprofile:AddUserId(player.UserId)\n\t\tprofile:Reconcile()\n\t\tprofile:ListenToRelease(function()\n\t\t\t$3\n\t\tend)\n\t\tif player:IsDescendantOf(game.Players) then\n\t\t\t$0\n\t\telse\n\t\t\tprofile:Release()\n\t\tend\n\telse\n\t\tplayer:Kick()\n\tend\nend',
		category = "advanced",
		tags = {"profile", "data", "persistence"}
	},
	{
		name = "raycast",
		description = "Workspace raycast with params",
		template = "local raycastParams = RaycastParams.new()\nraycastParams.FilterDescendantsInstances = {$1}\nraycastParams.FilterType = Enum.RaycastFilterType.Exclude\nlocal result = workspace:Raycast($2, $3, raycastParams)\nif result then\n\t$0\nend",
		category = "advanced",
		tags = {"raycast", "physics", "detection"}
	},
	{
		name = "input",
		description = "UserInputService input handling",
		template = 'local UserInputService = game:GetService("UserInputService")\n\nUserInputService.InputBegan:Connect(function(input, gameProcessed)\n\tif gameProcessed then return end\n\tif input.KeyCode == Enum.KeyCode.$1 then\n\t\t$0\n\tend\nend)',
		category = "advanced",
		tags = {"input", "keyboard", "user"}
	},
	{
		name = "context",
		description = "ContextActionService bind action",
		template = 'local ContextActionService = game:GetService("ContextActionService")\n\nlocal function $1(actionName, inputState, inputObject)\n\tif inputState == Enum.UserInputState.Begin then\n\t\t$0\n\tend\nend\n\nContextActionService:BindAction("$2", $1, false, Enum.KeyCode.$3)',
		category = "advanced",
		tags = {"context", "action", "input"}
	},
	{
		name = "coroutine",
		description = "Coroutine wrapper",
		template = "coroutine.wrap(function()\n\t$0\nend)()",
		category = "advanced",
		tags = {"coroutine", "async", "thread"}
	},
}

--[[
	Returns all default snippets (24 total)

	@return array<Snippet> - Array of default snippet definitions
]]
function SnippetLibrary.getDefaultSnippets()
	return DEFAULT_SNIPPETS
end

--[[
	Returns user-added custom snippets

	@return array<Snippet> - Array of custom snippet definitions
]]
function SnippetLibrary.getCustomSnippets()
	return customSnippets
end

--[[
	Returns all snippets (default + custom merged)

	@return array<Snippet> - Combined array of all snippets
]]
function SnippetLibrary.getAllSnippets()
	local all = {}

	-- Add default snippets
	for _, snippet in ipairs(DEFAULT_SNIPPETS) do
		table.insert(all, snippet)
	end

	-- Add custom snippets
	for _, snippet in ipairs(customSnippets) do
		table.insert(all, snippet)
	end

	return all
end

--[[
	Adds a custom snippet to the library

	@param snippet table - Snippet definition with name, description, template, category, tags
	@return boolean - Success status
	@return string - Error message if failed
]]
function SnippetLibrary.addCustomSnippet(snippet)
	-- Validate required fields
	if not snippet.name or snippet.name == "" then
		return false, "Snippet name is required"
	end

	if not snippet.description or snippet.description == "" then
		return false, "Snippet description is required"
	end

	if not snippet.template or snippet.template == "" then
		return false, "Snippet template is required"
	end

	-- Check for duplicate name
	for _, existingSnippet in ipairs(DEFAULT_SNIPPETS) do
		if existingSnippet.name == snippet.name then
			return false, "Snippet name conflicts with default snippet"
		end
	end

	for _, existingSnippet in ipairs(customSnippets) do
		if existingSnippet.name == snippet.name then
			return false, "Snippet name already exists"
		end
	end

	-- Set default category if not provided
	if not snippet.category then
		snippet.category = "custom"
	end

	-- Ensure tags is an array
	if not snippet.tags then
		snippet.tags = {}
	end

	-- Add to custom snippets
	table.insert(customSnippets, snippet)

	return true
end

--[[
	Removes a custom snippet by name

	@param name string - Name of snippet to remove
	@return boolean - Success status
]]
function SnippetLibrary.removeCustomSnippet(name)
	for i, snippet in ipairs(customSnippets) do
		if snippet.name == name then
			table.remove(customSnippets, i)
			return true
		end
	end

	return false
end

--[[
	Loads custom snippets from plugin settings

	@param savedSnippets array - Array of custom snippets from plugin:GetSetting()
]]
function SnippetLibrary.loadCustomSnippets(savedSnippets)
	if savedSnippets and type(savedSnippets) == "table" then
		customSnippets = savedSnippets
	end
end

--[[
	Expands a template by replacing placeholders with values
	If no values provided, placeholders are preserved for tab-stop mode

	@param template string - Template string with $1, $2, etc.
	@param values table - Optional map of {1: "value1", 2: "value2"}
	@return string - Expanded template
]]
function SnippetLibrary.expandTemplate(template, values)
	if not values or not next(values) then
		-- No values provided, return template as-is for tab-stop mode
		return template
	end

	local expanded = template

	-- Replace placeholders with values
	for placeholder, value in pairs(values) do
		local pattern = "%$" .. tostring(placeholder)
		expanded = expanded:gsub(pattern, value)
	end

	return expanded
end

--[[
	Parses template to extract tab stop positions
	Returns array of tab stops with their stop number

	@param template string - Template string with $1, $2, $0 markers
	@return array<{stop: number, position: number}> - Tab stops found in order
]]
function SnippetLibrary.parseTabStops(template)
	local tabStops = {}
	local position = 1

	-- Scan through template to find all $N markers
	for match in template:gmatch("%$(%d+)") do
		local stopNumber = tonumber(match)
		if stopNumber then
			-- Find the position of this tab stop in the template
			local _, endPos = template:find("%$" .. match, position)
			if endPos then
				table.insert(tabStops, {
					stop = stopNumber,
					position = endPos + 1  -- Position after the placeholder
				})
				position = endPos + 1
			end
		end
	end

	-- Sort tab stops by stop number ($1, $2, ..., $0 should be last)
	table.sort(tabStops, function(a, b)
		-- $0 is always last
		if a.stop == 0 then return false end
		if b.stop == 0 then return true end
		return a.stop < b.stop
	end)

	return tabStops
end

return SnippetLibrary
