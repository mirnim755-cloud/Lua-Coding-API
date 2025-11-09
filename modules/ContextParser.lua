--[[
	ContextParser.lua

	Analyzes code context around cursor position for intelligent snippet ranking.
	Detects patterns like "game:", "local ", ":Connect(" to suggest relevant snippets.
]]

local ContextParser = {}

--[[
	Parses code context around cursor position

	@param textBefore string - Text before cursor (up to 100 chars)
	@param textAfter string - Text after cursor
	@param cursorLine string - Full current line content
	@return table - Context object with analyzed information
]]
function ContextParser.parseContext(textBefore, textAfter, cursorLine)
	local context = {
		currentToken = "",
		previousToken = "",
		currentLine = cursorLine or "",
		inFunction = false,
		inTable = false,
		afterDot = false,
		afterColon = false,
		lineStart = false,
		patterns = {},
		isEmpty = false
	}

	-- Check if script is empty (< 10 chars)
	if #textBefore < 10 then
		context.isEmpty = true
		table.insert(context.patterns, "empty_script")
	end

	-- Extract current token being typed
	local currentToken = textBefore:match("([%w_]+)$") or ""
	context.currentToken = currentToken

	-- Extract previous token (before current)
	local beforeCurrentToken = textBefore:sub(1, -(#currentToken + 1))
	local previousToken = beforeCurrentToken:match("([%w_]+)%s*$") or ""
	context.previousToken = previousToken

	-- Check if after dot or colon
	context.afterDot = textBefore:match("%.$") ~= nil or textBefore:match("%.%w*$") ~= nil
	context.afterColon = textBefore:match(":$") ~= nil or textBefore:match(":%w*$") ~= nil

	-- Check if at line start (after whitespace only)
	context.lineStart = cursorLine:match("^%s*" .. currentToken .. "$") ~= nil

	-- Detect specific patterns in textBefore
	if textBefore:match("game:") then
		table.insert(context.patterns, "game:")
	end

	if textBefore:match(":Connect%s*%($") or textBefore:match(":Connect%s*%(function") then
		table.insert(context.patterns, ":Connect(")
	end

	if textBefore:match("^%s*local%s+$") or cursorLine:match("^%s*local%s+") then
		table.insert(context.patterns, "local ")
		context.lineStart = true
	end

	if cursorLine:match("^%s*for%s+") then
		table.insert(context.patterns, "for ")
	end

	if textBefore:match('Instance%.new%s*%(%s*"$') then
		table.insert(context.patterns, "Instance.new")
	end

	if textBefore:match("%.OnServerEvent%s*:") or textBefore:match("%.OnClientEvent%s*:") then
		table.insert(context.patterns, "remote_event")
	end

	-- Check if inside function body (rough heuristic)
	local functionCount = 0
	local endCount = 0
	for _ in textBefore:gmatch("function") do
		functionCount = functionCount + 1
	end
	for _ in textBefore:gmatch("%send%s") do
		endCount = endCount + 1
	end
	context.inFunction = functionCount > endCount

	-- Check if inside table literal
	local openBraces = 0
	for _ in textBefore:gmatch("{") do
		openBraces = openBraces + 1
	end
	local closeBraces = 0
	for _ in textBefore:gmatch("}") do
		closeBraces = closeBraces + 1
	end
	context.inTable = openBraces > closeBraces

	return context
end

--[[
	Detects specific patterns in context
	Returns primary pattern detected (for specialized handling)

	@param context table - Context object from parseContext()
	@return string|nil - Primary pattern name or nil
]]
function ContextParser.detectPattern(context)
	-- Priority order for pattern detection
	if context.isEmpty then
		return "empty_script"
	end

	for _, pattern in ipairs(context.patterns) do
		if pattern == "game:" then
			return "game:"
		elseif pattern == ":Connect(" then
			return ":Connect("
		elseif pattern == "local " then
			return "local "
		elseif pattern == "Instance.new" then
			return "Instance.new"
		elseif pattern == "remote_event" then
			return "remote_event"
		elseif pattern == "for " then
			return "for "
		end
	end

	return nil
end

--[[
	Scores how well a snippet matches the current context
	Returns score 0-50 based on context relevance

	@param snippet table - Snippet definition with name, tags, template
	@param context table - Context object from parseContext()
	@return number - Score 0-50 (higher = better match)
]]
function ContextParser.scoreContextMatch(snippet, context)
	local score = 0
	local snippetName = snippet.name:lower()
	local snippetTags = snippet.tags or {}

	-- Convert tags to lowercase for comparison
	local tagsLower = {}
	for _, tag in ipairs(snippetTags) do
		table.insert(tagsLower, tag:lower())
	end

	-- Empty script context: Prioritize module template
	if context.isEmpty then
		if snippetName == "module" then
			score = score + 40
		elseif snippetName == "service" or snippetName == "function" then
			score = score + 20
		end
		return score
	end

	-- Pattern-based scoring
	local primaryPattern = ContextParser.detectPattern(context)

	if primaryPattern == "game:" then
		-- After "game:" suggest service-related snippets
		if snippetName == "service" then
			score = score + 50
		end
		for _, tag in ipairs(tagsLower) do
			if tag == "service" then
				score = score + 30
			end
		end

	elseif primaryPattern == ":Connect(" then
		-- After ":Connect(" suggest function snippets
		if snippetName == "function" then
			score = score + 40
		end
		for _, tag in ipairs(tagsLower) do
			if tag == "function" or tag == "callback" then
				score = score + 30
			end
		end

	elseif primaryPattern == "local " then
		-- After "local " suggest variable-creating snippets
		if snippetName == "service" then
			score = score + 35
		elseif snippetName == "function" then
			score = score + 30
		elseif snippetName == "part" then
			score = score + 25
		end
		for _, tag in ipairs(tagsLower) do
			if tag == "variable" or tag == "declaration" then
				score = score + 20
			end
		end

	elseif primaryPattern == "Instance.new" then
		-- After Instance.new suggest instance creation snippets
		if snippetName == "part" then
			score = score + 40
		end
		for _, tag in ipairs(tagsLower) do
			if tag == "instance" or tag == "creation" then
				score = score + 25
			end
		end

	elseif primaryPattern == "remote_event" then
		-- Remote event context
		if snippetName == "remote" or snippetName == "function" then
			score = score + 40
		end

	elseif primaryPattern == "for " then
		-- Loop context
		if snippetName == "for" or snippetName == "forin" or snippetName == "while" then
			score = score + 35
		end
		for _, tag in ipairs(tagsLower) do
			if tag == "loop" then
				score = score + 25
			end
		end
	end

	-- Line start context: Prefer statement-level snippets
	if context.lineStart then
		if snippetName == "service" or snippetName == "function" or snippetName == "local" then
			score = score + 10
		end
	end

	-- Inside function: Prefer logic snippets
	if context.inFunction then
		for _, tag in ipairs(tagsLower) do
			if tag == "conditional" or tag == "loop" or tag == "pcall" then
				score = score + 8
			end
		end
	end

	-- Inside table: Prefer table-related snippets
	if context.inTable then
		for _, tag in ipairs(tagsLower) do
			if tag == "table" then
				score = score + 10
			end
		end
	end

	return math.min(score, 50)  -- Cap at 50 (max context score)
end

return ContextParser
