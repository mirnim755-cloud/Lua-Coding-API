--[[
	Lua Autocomplete Plugin

	A production-ready Roblox Studio plugin that provides context-aware Lua autocompletions
	and snippet insertion using the official ScriptEditorService API.

	Entry point: Initializes modules, creates UI, registers callbacks.
]]

-- Module paths
local modules = script.Parent:WaitForChild("modules")
local ui = script.Parent:WaitForChild("ui")

-- Load modules
local SnippetLibrary = require(modules:WaitForChild("SnippetLibrary"))
local ContextParser = require(modules:WaitForChild("ContextParser"))
local TabStopManager = require(modules:WaitForChild("TabStopManager"))
local AutocompleteEngine = require(modules:WaitForChild("AutocompleteEngine"))
local ApiIndex = require(modules:WaitForChild("ApiIndex"))

-- Load UI modules
local PluginWidget = require(ui:WaitForChild("PluginWidget"))
local SnippetList = require(ui:WaitForChild("SnippetList"))
local SettingsDialog = require(ui:WaitForChild("SettingsDialog"))
local AddSnippetDialog = require(ui:WaitForChild("AddSnippetDialog"))

-- Plugin state
local toolbar = nil
local toolbarButton = nil
local widget = nil
local apiMode = "unknown"  -- "primary" or "fallback"

--[[
	Detects ScriptEditorService availability and determines API mode

	@return string - "primary" if ScriptEditorService available, "fallback" otherwise
]]
local function detectApiMode()
	local success, ScriptEditorService = pcall(function()
		return game:GetService("ScriptEditorService")
	end)

	if success and ScriptEditorService then
		-- Check if RegisterAutocompleteCallback is available
		if ScriptEditorService.RegisterAutocompleteCallback then
			return "primary"
		end
	end

	return "fallback"
end

--[[
	Initializes all modules with plugin instance

	@param plugin Plugin - The plugin instance
]]
local function initializeModules(plugin)
	-- Initialize AutocompleteEngine
	local engineInitialized = AutocompleteEngine.initialize(
		plugin,
		SnippetLibrary,
		ContextParser,
		TabStopManager
	)

	if not engineInitialized then
		warn("Lua Autocomplete: ScriptEditorService not available, using fallback mode")
		apiMode = "fallback"
	end

	-- Initialize PluginWidget
	PluginWidget.initialize(
		plugin,
		SnippetLibrary,
		SnippetList,
		SettingsDialog,
		AddSnippetDialog,
		AutocompleteEngine
	)

	-- Load saved custom snippets
	local savedCustomSnippets = plugin:GetSetting("CustomSnippets")
	if savedCustomSnippets then
		SnippetLibrary.loadCustomSnippets(savedCustomSnippets)
	end

	-- Load usage statistics
	local savedUsageStats = plugin:GetSetting("SnippetUsageCount")
	if savedUsageStats then
		AutocompleteEngine.loadUsageStats(savedUsageStats)
	end
end

--[[
	Creates the plugin toolbar and button

	@param plugin Plugin - The plugin instance
]]
local function createToolbar(plugin)
	-- Create toolbar
	toolbar = plugin:CreateToolbar("Lua Autocomplete")

	-- Create toolbar button
	toolbarButton = toolbar:CreateButton(
		"Lua Autocomplete",
		"Toggle Lua Autocomplete widget",
		"rbxasset://textures/ui/GuiImagePlaceholder.png"  -- Icon (Studio will show default)
	)

	-- Set button text with emoji
	toolbarButton.Text = "🔧 Lua Autocomplete"

	-- Connect click handler
	toolbarButton.Click:Connect(function()
		if widget then
			PluginWidget.toggle()
		end
	end)
end

--[[
	Creates the main widget UI

	@param plugin Plugin - The plugin instance
]]
local function createWidget(plugin)
	-- Create widget
	widget = PluginWidget.create(plugin)

	-- Update mode based on API availability
	PluginWidget.updateMode(apiMode)

	-- Load saved enabled state
	local savedEnabled = plugin:GetSetting("PluginEnabled")
	if savedEnabled ~= nil then
		PluginWidget.setEnabled(savedEnabled)
	end
end

--[[
	Registers autocomplete callback with ScriptEditorService (primary mode only)

	@return boolean - Success status
]]
local function registerAutocomplete()
	if apiMode ~= "primary" then
		return false
	end

	local success, err = AutocompleteEngine.registerCallback()

	if success then
		print("Lua Autocomplete: Registered autocomplete callback")
		return true
	else
		warn("Lua Autocomplete: Failed to register callback: " .. tostring(err))
		return false
	end
end

--[[
	Sets up periodic API mode detection (for fallback → primary upgrade)

	@param plugin Plugin - The plugin instance
]]
local function setupApiDetection(plugin)
	if apiMode == "primary" then
		return  -- Already in primary mode
	end

	-- Check every 5 seconds if ScriptEditorService becomes available
	spawn(function()
		while apiMode == "fallback" do
			wait(5)

			local newMode = detectApiMode()
			if newMode == "primary" then
				-- API became available!
				apiMode = "primary"

				-- Re-initialize engine
				AutocompleteEngine.initialize(
					plugin,
					SnippetLibrary,
					ContextParser,
					TabStopManager
				)

				-- Register callback
				local success = registerAutocomplete()

				if success then
					-- Update UI
					PluginWidget.updateMode("primary")

					-- Show notification
					print("Lua Autocomplete: Script Editor API detected! Full autocomplete now available.")
				end

				break
			end
		end
	end)
end

--[[
	Cleanup when plugin unloading

	@param plugin Plugin - The plugin instance
]]
local function cleanup(plugin)
	-- Unregister autocomplete callback
	if apiMode == "primary" then
		AutocompleteEngine.unregisterCallback()
	end

	-- Close any open dialogs
	if SettingsDialog.isOpen() then
		SettingsDialog.close()
	end

	if AddSnippetDialog.isOpen() then
		AddSnippetDialog.close()
	end
end

--[[
	Main plugin initialization
]]
local function main()
	print("Lua Autocomplete: Initializing plugin...")

	-- Detect API availability
	apiMode = detectApiMode()
	print("Lua Autocomplete: API mode = " .. apiMode)

	-- Initialize all modules
	initializeModules(plugin)

	-- Create toolbar button
	createToolbar(plugin)

	-- Create widget UI
	createWidget(plugin)

	-- Register autocomplete callback if in primary mode
	if apiMode == "primary" then
		registerAutocomplete()
	end

	-- Set up periodic API detection (for fallback mode)
	setupApiDetection(plugin)

	-- Connect plugin unloading event
	plugin.Unloading:Connect(function()
		cleanup(plugin)
	end)

	print("Lua Autocomplete: Plugin initialized successfully")
	print("Lua Autocomplete: " .. #SnippetLibrary.getDefaultSnippets() .. " default snippets loaded")

	local customCount = #SnippetLibrary.getCustomSnippets()
	if customCount > 0 then
		print("Lua Autocomplete: " .. customCount .. " custom snippets loaded")
	end

	-- Show API statistics
	local apiStats = ApiIndex.getStats()
	print(string.format(
		"Lua Autocomplete: API index loaded (%d services, %d instances, %d enums)",
		apiStats.services,
		apiStats.instances,
		apiStats.enums
	))
end

-- Run main initialization
local success, err = pcall(main)

if not success then
	warn("Lua Autocomplete: Initialization failed: " .. tostring(err))
end
