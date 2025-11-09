--[[
	AutocompleteEngine.lua

	Core autocomplete logic and ScriptEditorService integration.
	Handles callback registration, completion ranking, and snippet insertion.
]]

local AutocompleteEngine = {}

-- Module dependencies (will be required during initialization)
local SnippetLibrary = nil
local ContextParser = nil
local TabStopManager = nil

-- State
local callbackRegistered = false
local registeredCallbackId = "LuaAutocomplete"
local usageStats = {}  -- Track snippet usage frequency
local plugin = nil

-- Services
local ScriptEditorService = nil

--[[
	Initializes the autocomplete engine with dependencies

	@param pluginInstance Plugin - The plugin instance for settings
	@param snippetLib table - SnippetLibrary module
	@param contextParser table - ContextParser module
	@param tabStopMgr table - TabStopManager module
	@return boolean - Success status
]]
function AutocompleteEngine.initialize(pluginInstance, snippetLib, contextParser, tabStopMgr)
	plugin = pluginInstance
	SnippetLibrary = snippetLib
	ContextParser = contextParser
	TabStopManager = tabStopMgr

	-- Try to get ScriptEditorService
	local success, service = pcall(function()
		return game:GetService("ScriptEditorService")
	end)

	if success then
		ScriptEditorService = service
		return true
	end

	return false
end

--[[
	Registers autocomplete callback with ScriptEditorService

	@return boolean - Success status
	@return string - Error message if failed
]]
function AutocompleteEngine.registerCallback()
	if not ScriptEditorService then
		return false, "ScriptEditorService not available"
	end

	if not ScriptEditorService.RegisterAutocompleteCallback then
		return false, "RegisterAutocompleteCallback method not available"
	end

	if callbackRegistered then
		return true, "Callback already registered"
	end

	-- Register callback with priority 100
	local success, err = pcall(function()
		ScriptEditorService:RegisterAutocompleteCallback(
			registeredCallbackId,
			100,
			function(request)
				return AutocompleteEngine._handleAutocompleteRequest(request)
			end
		)
	end)

	if success then
		callbackRegistered = true
		return true
	else
		return false, tostring(err)
	end
end

--[[
	Unregisters autocomplete callback

	@return boolean - Success status
]]
function AutocompleteEngine.unregisterCallback()
	if not ScriptEditorService or not callbackRegistered then
		return true
	end

	if not ScriptEditorService.DeregisterAutocompleteCallback then
		return false
	end

	local success = pcall(function()
		ScriptEditorService:DeregisterAutocompleteCallback(registeredCallbackId)
	end)

	if success then
		callbackRegistered = false
	end

	return success
end

--[[
	Handles autocomplete request from ScriptEditorService
	Internal function called by the registered callback

	@param request table - Autocomplete request with position, textBefore, textAfter
	@return array - Array of completion items
	@private
]]
function AutocompleteEngine._handleAutocompleteRequest(request)
	local startTime = tick()

	-- Extract context from request
	local textBefore = request.textBefore or ""
	local textAfter = request.textAfter or ""
	local cursorLine = textBefore:match("[^\n]*$") or ""

	-- Skip autocomplete in strings or comments
	if AutocompleteEngine._isInStringOrComment(textBefore) then
		return {}
	end

	-- Get all snippets
	local snippets = SnippetLibrary.getAllSnippets()

	-- Rank and filter completions
	local rankedSnippets = AutocompleteEngine.rankCompletions(request, snippets)

	-- Format as completion items
	local completionItems = {}
	for _, snippet in ipairs(rankedSnippets) do
		table.insert(completionItems, AutocompleteEngine.formatCompletionItem(snippet))
	end

	-- Performance check (should be < 10ms)
	local elapsed = (tick() - startTime) * 1000
	if elapsed > 10 then
		warn(string.format("Autocomplete callback took %.2fms (target: <10ms)", elapsed))
	end

	return completionItems
end

--[[
	Checks if cursor is inside a string literal or comment

	@param textBefore string - Text before cursor
	@return boolean - True if in string or comment
	@private
]]
function AutocompleteEngine._isInStringOrComment(textBefore)
	-- Check for comment (-- or --[[)
	local lastLine = textBefore:match("[^\n]*$") or ""
	if lastLine:match("^%s*%-%-") then
		return true
	end

	-- Check for string literal (count quotes)
	local doubleQuotes = 0
	local singleQuotes = 0

	for i = 1, #textBefore do
		local char = textBefore:sub(i, i)
		if char == '"' then
			doubleQuotes = doubleQuotes + 1
		elseif char == "'" then
			singleQuotes = singleQuotes + 1
		end
	end

	-- Odd number of quotes means we're inside a string
	if doubleQuotes % 2 == 1 or singleQuotes % 2 == 1 then
		return true
	end

	return false
end

--[[
	Ranks and filters completions based on context and usage

	@param request table - Autocomplete request
	@param snippets array - All available snippets
	@return array - Ranked array of top snippets
]]
function AutocompleteEngine.rankCompletions(request, snippets)
	local textBefore = request.textBefore or ""
	local textAfter = request.textAfter or ""
	local cursorLine = textBefore:match("[^\n]*$") or ""

	-- Parse context
	local context = ContextParser.parseContext(textBefore, textAfter, cursorLine)

	-- Get current token being typed
	local currentToken = context.currentToken:lower()

	-- Score each snippet
	local scoredSnippets = {}

	for _, snippet in ipairs(snippets) do
		local score = 0

		-- Context matching (weight: 50%)
		local contextScore = ContextParser.scoreContextMatch(snippet, context)
		score = score + (contextScore * 0.5)

		-- Usage frequency (weight: 30%)
		local usageCount = usageStats[snippet.name] or 0
		local frequencyScore = math.min(usageCount * 3, 50)  -- Cap at 50
		score = score + (frequencyScore * 0.3)

		-- Prefix match quality (weight: 20%)
		local prefixScore = AutocompleteEngine._calculatePrefixScore(snippet.name, currentToken)
		score = score + (prefixScore * 0.2)

		-- Only include snippets with some relevance
		if score > 0 or currentToken == "" then
			table.insert(scoredSnippets, {
				snippet = snippet,
				score = score
			})
		end
	end

	-- Sort by score (highest first)
	table.sort(scoredSnippets, function(a, b)
		return a.score > b.score
	end)

	-- Return top 10 snippets
	local topSnippets = {}
	for i = 1, math.min(10, #scoredSnippets) do
		table.insert(topSnippets, scoredSnippets[i].snippet)
	end

	return topSnippets
end

--[[
	Calculates prefix match score

	@param snippetName string - Name of snippet
	@param prefix string - Current token being typed
	@return number - Score 0-10
	@private
]]
function AutocompleteEngine._calculatePrefixScore(snippetName, prefix)
	if prefix == "" then
		return 5  -- Neutral score for no prefix
	end

	local nameLower = snippetName:lower()
	local prefixLower = prefix:lower()

	-- Exact prefix match
	if nameLower:sub(1, #prefixLower) == prefixLower then
		return 10
	end

	-- Contains match
	if nameLower:find(prefixLower, 1, true) then
		return 5
	end

	-- Fuzzy match (initials)
	local initials = ""
	for word in snippetName:gmatch("[%w]+") do
		initials = initials .. word:sub(1, 1):lower()
	end
	if initials:find(prefixLower, 1, true) then
		return 2
	end

	return 0
end

--[[
	Formats a snippet as a completion item for ScriptEditorService

	@param snippet table - Snippet definition
	@return table - Completion item in ScriptEditorService format
]]
function AutocompleteEngine.formatCompletionItem(snippet)
	return {
		label = snippet.name,
		kind = Enum.CompletionItemKind.Snippet,
		detail = snippet.description,
		documentation = snippet.template,
		overloads = {},
		learnMoreLink = "",
		codeSample = "",
		preselect = false,
		-- textEdit would be populated by ScriptEditorService
		-- We handle actual insertion in insertSnippet()
	}
end

--[[
	Inserts a snippet into a script document

	@param scriptDocument ScriptDocument - Target script document
	@param snippet table - Snippet to insert
	@param position table - Position {line, column} to insert at
	@return boolean - Success status
	@return string - Error message if failed
]]
function AutocompleteEngine.insertSnippet(scriptDocument, snippet, position)
	if not scriptDocument then
		return false, "No script document provided"
	end

	-- Get template
	local template = snippet.template

	-- Parse tab stops
	local tabStops = SnippetLibrary.parseTabStops(template)

	-- Try to insert using EditTextAsync
	local success, err = pcall(function()
		if scriptDocument.EditTextAsync then
			-- Use EditTextAsync for safe insertion
			local line = position.line or 1
			local column = position.column or 1

			scriptDocument:EditTextAsync(
				{line, column},
				{line, column},
				template
			)
		else
			return false, "EditTextAsync not available"
		end
	end)

	if not success then
		return false, "Failed to insert snippet: " .. tostring(err)
	end

	-- Update usage statistics
	usageStats[snippet.name] = (usageStats[snippet.name] or 0) + 1

	-- Save usage stats to plugin settings
	if plugin then
		pcall(function()
			plugin:SetSetting("SnippetUsageCount", usageStats)
		end)
	end

	-- Start tab-stop mode if there are tab stops
	if #tabStops > 0 then
		-- Calculate actual positions after insertion
		local adjustedTabStops = {}
		for _, stop in ipairs(tabStops) do
			table.insert(adjustedTabStops, {
				stop = stop.stop,
				line = position.line + stop.line - 1,
				column = stop.column
			})
		end

		TabStopManager.startTabStopMode(scriptDocument, adjustedTabStops)
	end

	return true
end

--[[
	Loads usage statistics from plugin settings

	@param savedStats table - Usage stats from plugin:GetSetting()
]]
function AutocompleteEngine.loadUsageStats(savedStats)
	if savedStats and type(savedStats) == "table" then
		usageStats = savedStats
	end
end

--[[
	Resets usage statistics

	@return boolean - Success status
]]
function AutocompleteEngine.resetUsageStats()
	usageStats = {}

	-- Save empty stats to plugin settings
	if plugin then
		pcall(function()
			plugin:SetSetting("SnippetUsageCount", {})
		end)
	end

	return true
end

--[[
	Gets current usage statistics

	@return table - Usage stats map {snippetName: count}
]]
function AutocompleteEngine.getUsageStats()
	return usageStats
end

--[[
	Checks if ScriptEditorService is available

	@return boolean - True if available
]]
function AutocompleteEngine.isAvailable()
	return ScriptEditorService ~= nil
end

return AutocompleteEngine
