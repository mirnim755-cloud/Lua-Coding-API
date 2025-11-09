--[[
	TabStopManager.lua

	Handles tab-stop navigation after snippet insertion.
	Manages cursor movement through $1, $2, ..., $0 placeholders.
]]

local TabStopManager = {}

-- State
local active = false
local currentDocument = nil
local tabStops = {}
local currentStopIndex = 0
local connections = {}

-- Services (will be initialized when needed)
local UserInputService = game:GetService("UserInputService")

--[[
	Starts tab-stop mode for a script document

	@param scriptDocument ScriptDocument - The document where snippet was inserted
	@param stops array<{stop: number, line: number, column: number}> - Tab stop positions
]]
function TabStopManager.startTabStopMode(scriptDocument, stops)
	-- Don't start if no tab stops
	if not stops or #stops == 0 then
		return
	end

	-- Exit any existing tab-stop mode
	TabStopManager.exitTabStopMode()

	-- Set up new tab-stop mode
	active = true
	currentDocument = scriptDocument
	tabStops = stops
	currentStopIndex = 1

	-- Move cursor to first tab stop
	if tabStops[1] then
		local success = pcall(function()
			-- Note: ScriptEditorService cursor positioning would be done here
			-- For now, we track the state and let the engine handle cursor movement
		end)

		if not success then
			-- If cursor positioning fails, exit tab-stop mode
			TabStopManager.exitTabStopMode()
			return
		end
	end

	-- Connect input handlers
	TabStopManager._connectInputHandlers()
end

--[[
	Moves to the next tab stop in sequence

	@return boolean - Success status
]]
function TabStopManager.nextTabStop()
	if not active or not currentDocument then
		return false
	end

	-- Move to next stop
	currentStopIndex = currentStopIndex + 1

	-- Check if we've reached the end
	if currentStopIndex > #tabStops then
		-- Exit tab-stop mode when reaching the end
		TabStopManager.exitTabStopMode()
		return false
	end

	-- Move cursor to next tab stop
	local stop = tabStops[currentStopIndex]
	if stop then
		local success = pcall(function()
			-- Cursor positioning would be done via ScriptEditorService
			-- Placeholder for actual cursor movement
		end)

		if not success then
			TabStopManager.exitTabStopMode()
			return false
		end
	end

	return true
end

--[[
	Moves to the previous tab stop in sequence

	@return boolean - Success status
]]
function TabStopManager.previousTabStop()
	if not active or not currentDocument then
		return false
	end

	-- Can't go before first stop
	if currentStopIndex <= 1 then
		return false
	end

	-- Move to previous stop
	currentStopIndex = currentStopIndex - 1

	-- Move cursor to previous tab stop
	local stop = tabStops[currentStopIndex]
	if stop then
		local success = pcall(function()
			-- Cursor positioning would be done via ScriptEditorService
			-- Placeholder for actual cursor movement
		end)

		if not success then
			TabStopManager.exitTabStopMode()
			return false
		end
	end

	return true
end

--[[
	Exits tab-stop mode and cleans up

	@return void
]]
function TabStopManager.exitTabStopMode()
	if not active then
		return
	end

	-- Clean up state
	active = false
	currentDocument = nil
	tabStops = {}
	currentStopIndex = 0

	-- Disconnect all input handlers
	TabStopManager._disconnectInputHandlers()
end

--[[
	Checks if tab-stop mode is currently active

	@return boolean - True if tab-stop mode is active
]]
function TabStopManager.isActive()
	return active
end

--[[
	Connects input handlers for Tab/Shift+Tab/Escape keys
	Internal function

	@private
]]
function TabStopManager._connectInputHandlers()
	-- Disconnect any existing handlers first
	TabStopManager._disconnectInputHandlers()

	-- Connect to InputBegan for Tab, Shift+Tab, Escape
	connections.inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not active then
			return
		end

		-- Don't process if game UI consumed the input
		if gameProcessed then
			return
		end

		-- Handle Tab key (next tab stop)
		if input.KeyCode == Enum.KeyCode.Tab then
			local shiftPressed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or
			                     UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

			if shiftPressed then
				-- Shift+Tab: Previous tab stop
				TabStopManager.previousTabStop()
			else
				-- Tab: Next tab stop
				TabStopManager.nextTabStop()
			end

		-- Handle Escape key (exit tab-stop mode)
		elseif input.KeyCode == Enum.KeyCode.Escape then
			TabStopManager.exitTabStopMode()

		-- Handle any character input (exit tab-stop mode when user types)
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			-- Check if it's a printable character (not modifier keys)
			if input.KeyCode.Value >= Enum.KeyCode.A.Value and input.KeyCode.Value <= Enum.KeyCode.Z.Value then
				-- User is typing, exit tab-stop mode
				TabStopManager.exitTabStopMode()
			elseif input.KeyCode.Value >= Enum.KeyCode.Zero.Value and input.KeyCode.Value <= Enum.KeyCode.Nine.Value then
				-- User typing numbers
				TabStopManager.exitTabStopMode()
			elseif input.KeyCode == Enum.KeyCode.Space or
			       input.KeyCode == Enum.KeyCode.Return or
			       input.KeyCode == Enum.KeyCode.Backspace or
			       input.KeyCode == Enum.KeyCode.Delete then
				-- User editing text
				TabStopManager.exitTabStopMode()
			end
		end
	end)

	-- Connect to mouse button events (clicking exits tab-stop mode)
	connections.mouseButton1Down = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not active then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- User clicked mouse, exit tab-stop mode
			TabStopManager.exitTabStopMode()
		end
	end)
end

--[[
	Disconnects all input handlers
	Internal function

	@private
]]
function TabStopManager._disconnectInputHandlers()
	for _, connection in pairs(connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	connections = {}
end

--[[
	Gets the current tab stop information
	Useful for debugging and testing

	@return table|nil - Current tab stop info or nil if not active
]]
function TabStopManager.getCurrentStop()
	if not active or currentStopIndex == 0 or currentStopIndex > #tabStops then
		return nil
	end

	return tabStops[currentStopIndex]
end

--[[
	Gets all tab stops
	Useful for debugging and testing

	@return array - All tab stops
]]
function TabStopManager.getAllStops()
	return tabStops
end

return TabStopManager
