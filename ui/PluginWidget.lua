--[[
	PluginWidget.lua

	Constructs and manages the main DockWidget UI for the Lua Autocomplete plugin.
	Handles toolbar, search, snippet list, and mode switching.
]]

local PluginWidget = {}

-- Dependencies (will be set during initialization)
local SnippetLibrary = nil
local SnippetList = nil
local SettingsDialog = nil
local AddSnippetDialog = nil
local AutocompleteEngine = nil

-- State
local widget = nil
local pluginInstance = nil
local enabled = true
local currentMode = "primary"  -- "primary" or "fallback"

-- UI elements
local container = nil
local headerFrame = nil
local toggleButton = nil
local toolbarFrame = nil
local settingsButton = nil
local addButton = nil
local refreshButton = nil
local warningBanner = nil
local searchBox = nil
local snippetListFrame = nil

--[[
	Initializes the widget module with dependencies

	@param plugin Plugin - The plugin instance
	@param snippetLib table - SnippetLibrary module
	@param snippetListModule table - SnippetList UI module
	@param settingsDialog table - SettingsDialog module
	@param addDialog table - AddSnippetDialog module
	@param engine table - AutocompleteEngine module
]]
function PluginWidget.initialize(plugin, snippetLib, snippetListModule, settingsDialog, addDialog, engine)
	pluginInstance = plugin
	SnippetLibrary = snippetLib
	SnippetList = snippetListModule
	SettingsDialog = settingsDialog
	AddSnippetDialog = addDialog
	AutocompleteEngine = engine
end

--[[
	Creates the main DockWidget UI

	@param plugin Plugin - The plugin instance
	@return DockWidgetPluginGui - Created widget
]]
function PluginWidget.create(plugin)
	pluginInstance = plugin

	-- Create DockWidgetPluginGui
	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Right,  -- Docked to right by default
		false,                         -- Initially not enabled (user opens via toolbar)
		false,                         -- Don't override previous enabled state
		400,                           -- Width
		300,                           -- Height (flexible)
		400,                           -- Min width
		200                            -- Min height
	)

	widget = plugin:CreateDockWidgetPluginGui("LuaAutocompleteWidget", widgetInfo)
	widget.Title = "Lua Autocomplete"

	-- Create main container
	container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	container.BorderSizePixel = 0
	container.Parent = widget

	-- Header frame
	headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0, 40)
	headerFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = container

	-- Title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -100, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Lua Autocomplete"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 16
	titleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = headerFrame

	-- Toggle button (ON/OFF)
	toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 60, 0, 25)
	toggleButton.Position = UDim2.new(1, -70, 0.5, -12.5)
	toggleButton.BackgroundColor3 = Color3.fromRGB(144, 192, 144)  -- Green when enabled
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "ON"
	toggleButton.Font = Enum.Font.SourceSansBold
	toggleButton.TextSize = 14
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.Parent = headerFrame

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 4)
	toggleCorner.Parent = toggleButton

	toggleButton.MouseButton1Click:Connect(function()
		PluginWidget.setEnabled(not enabled)
	end)

	-- Toolbar frame
	toolbarFrame = Instance.new("Frame")
	toolbarFrame.Name = "Toolbar"
	toolbarFrame.Size = UDim2.new(1, 0, 0, 40)
	toolbarFrame.Position = UDim2.new(0, 0, 0, 40)
	toolbarFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
	toolbarFrame.BorderSizePixel = 0
	toolbarFrame.Parent = container

	-- Settings button
	settingsButton = Instance.new("TextButton")
	settingsButton.Name = "SettingsButton"
	settingsButton.Size = UDim2.new(0.33, -7, 0, 30)
	settingsButton.Position = UDim2.new(0, 5, 0.5, -15)
	settingsButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	settingsButton.BorderSizePixel = 0
	settingsButton.Text = "⚙ Settings"
	settingsButton.Font = Enum.Font.SourceSans
	settingsButton.TextSize = 13
	settingsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	settingsButton.Parent = toolbarFrame

	local settingsCorner = Instance.new("UICorner")
	settingsCorner.CornerRadius = UDim.new(0, 4)
	settingsCorner.Parent = settingsButton

	settingsButton.MouseButton1Click:Connect(function()
		PluginWidget._openSettings()
	end)

	-- Add button
	addButton = Instance.new("TextButton")
	addButton.Name = "AddButton"
	addButton.Size = UDim2.new(0.33, -7, 0, 30)
	addButton.Position = UDim2.new(0.33, 2.5, 0.5, -15)
	addButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	addButton.BorderSizePixel = 0
	addButton.Text = "+ Add"
	addButton.Font = Enum.Font.SourceSans
	addButton.TextSize = 13
	addButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	addButton.Parent = toolbarFrame

	local addCorner = Instance.new("UICorner")
	addCorner.CornerRadius = UDim.new(0, 4)
	addCorner.Parent = addButton

	addButton.MouseButton1Click:Connect(function()
		PluginWidget._openAddDialog()
	end)

	-- Refresh button
	refreshButton = Instance.new("TextButton")
	refreshButton.Name = "RefreshButton"
	refreshButton.Size = UDim2.new(0.33, -7, 0, 30)
	refreshButton.Position = UDim2.new(0.66, 2.5, 0.5, -15)
	refreshButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	refreshButton.BorderSizePixel = 0
	refreshButton.Text = "↻ Refresh"
	refreshButton.Font = Enum.Font.SourceSans
	refreshButton.TextSize = 13
	refreshButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	refreshButton.Parent = toolbarFrame

	local refreshCorner = Instance.new("UICorner")
	refreshCorner.CornerRadius = UDim.new(0, 4)
	refreshCorner.Parent = refreshButton

	refreshButton.MouseButton1Click:Connect(function()
		PluginWidget._refreshApi()
	end)

	-- Warning banner (hidden by default, shown in fallback mode)
	warningBanner = Instance.new("Frame")
	warningBanner.Name = "WarningBanner"
	warningBanner.Size = UDim2.new(1, 0, 0, 60)
	warningBanner.Position = UDim2.new(0, 0, 0, 80)
	warningBanner.BackgroundColor3 = Color3.fromRGB(255, 240, 200)
	warningBanner.BorderSizePixel = 1
	warningBanner.BorderColor3 = Color3.fromRGB(220, 180, 100)
	warningBanner.Visible = false
	warningBanner.Parent = container

	local warningText = Instance.new("TextLabel")
	warningText.Name = "WarningText"
	warningText.Size = UDim2.new(1, -20, 0, 35)
	warningText.Position = UDim2.new(0, 10, 0, 5)
	warningText.BackgroundTransparency = 1
	warningText.Text = "Script Editor API unavailable. Snippets will insert at end of selected script. Enable Beta Features for full integration."
	warningText.Font = Enum.Font.SourceSans
	warningText.TextSize = 11
	warningText.TextColor3 = Color3.fromRGB(100, 70, 0)
	warningText.TextXAlignment = Enum.TextXAlignment.Left
	warningText.TextYAlignment = Enum.TextYAlignment.Top
	warningText.TextWrapped = true
	warningText.Parent = warningBanner

	local enableBetaButton = Instance.new("TextButton")
	enableBetaButton.Name = "EnableBetaButton"
	enableBetaButton.Size = UDim2.new(0, 120, 0, 20)
	enableBetaButton.Position = UDim2.new(0, 10, 1, -25)
	enableBetaButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	enableBetaButton.BorderSizePixel = 0
	enableBetaButton.Text = "Enable Beta Features"
	enableBetaButton.Font = Enum.Font.SourceSansBold
	enableBetaButton.TextSize = 11
	enableBetaButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	enableBetaButton.Parent = warningBanner

	local betaCorner = Instance.new("UICorner")
	betaCorner.CornerRadius = UDim.new(0, 3)
	betaCorner.Parent = enableBetaButton

	enableBetaButton.MouseButton1Click:Connect(function()
		PluginWidget._showBetaInstructions()
	end)

	-- Search box
	local searchYOffset = 80  -- Will be adjusted based on warning banner
	searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, -20, 0, 30)
	searchBox.Position = UDim2.new(0, 10, 0, searchYOffset)
	searchBox.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	searchBox.BorderSizePixel = 1
	searchBox.BorderColor3 = Color3.fromRGB(200, 200, 200)
	searchBox.PlaceholderText = "Search snippets..."
	searchBox.Text = ""
	searchBox.Font = Enum.Font.SourceSans
	searchBox.TextSize = 13
	searchBox.TextColor3 = Color3.fromRGB(0, 0, 0)
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = container

	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 4)
	searchCorner.Parent = searchBox

	-- Search functionality
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		PluginWidget._filterSnippets(searchBox.Text)
	end)

	-- Snippet list scrolling frame
	local listYOffset = searchYOffset + 40
	snippetListFrame = Instance.new("ScrollingFrame")
	snippetListFrame.Name = "SnippetList"
	snippetListFrame.Size = UDim2.new(1, -20, 1, -(listYOffset + 10))
	snippetListFrame.Position = UDim2.new(0, 10, 0, listYOffset)
	snippetListFrame.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
	snippetListFrame.BorderSizePixel = 1
	snippetListFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
	snippetListFrame.ScrollBarThickness = 6
	snippetListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	snippetListFrame.Parent = container

	-- Initial snippet list render
	PluginWidget._renderSnippets()

	return widget
end

--[[
	Shows the widget

	@return void
]]
function PluginWidget.show()
	if widget then
		widget.Enabled = true
	end
end

--[[
	Hides the widget

	@return void
]]
function PluginWidget.hide()
	if widget then
		widget.Enabled = false
	end
end

--[[
	Toggles widget visibility

	@return void
]]
function PluginWidget.toggle()
	if widget then
		widget.Enabled = not widget.Enabled
	end
end

--[[
	Updates UI based on mode (primary or fallback)

	@param mode string - "primary" or "fallback"
]]
function PluginWidget.updateMode(mode)
	currentMode = mode

	if mode == "fallback" then
		-- Show warning banner
		warningBanner.Visible = true

		-- Disable settings button
		settingsButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		settingsButton.TextColor3 = Color3.fromRGB(150, 150, 150)

		-- Adjust search box and list positions
		searchBox.Position = UDim2.new(0, 10, 0, 140)
		snippetListFrame.Position = UDim2.new(0, 10, 0, 180)
		snippetListFrame.Size = UDim2.new(1, -20, 1, -190)

	else
		-- Hide warning banner
		warningBanner.Visible = false

		-- Enable settings button
		settingsButton.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
		settingsButton.TextColor3 = Color3.fromRGB(0, 0, 0)

		-- Reset positions
		searchBox.Position = UDim2.new(0, 10, 0, 80)
		snippetListFrame.Position = UDim2.new(0, 10, 0, 120)
		snippetListFrame.Size = UDim2.new(1, -20, 1, -130)
	end
end

--[[
	Sets plugin enabled/disabled state

	@param isEnabled boolean - True to enable, false to disable
]]
function PluginWidget.setEnabled(isEnabled)
	enabled = isEnabled

	-- Update toggle button
	if enabled then
		toggleButton.BackgroundColor3 = Color3.fromRGB(144, 192, 144)  -- Green
		toggleButton.Text = "ON"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(204, 204, 204)  -- Gray
		toggleButton.Text = "OFF"
	end

	-- Save setting
	if pluginInstance then
		pluginInstance:SetSetting("PluginEnabled", enabled)
	end
end

--[[
	Renders all snippets to the list

	@private
]]
function PluginWidget._renderSnippets()
	if not snippetListFrame or not SnippetList then
		return
	end

	local allSnippets = SnippetLibrary.getAllSnippets()

	SnippetList.render(snippetListFrame, allSnippets, function(snippet)
		PluginWidget._onSnippetClicked(snippet)
	end)
end

--[[
	Filters and re-renders snippets based on search text

	@param searchText string - Search query
	@private
]]
function PluginWidget._filterSnippets(searchText)
	if not snippetListFrame or not SnippetList then
		return
	end

	local allSnippets = SnippetLibrary.getAllSnippets()
	local filtered = SnippetList.filter(allSnippets, searchText)

	SnippetList.render(snippetListFrame, filtered, function(snippet)
		PluginWidget._onSnippetClicked(snippet)
	end)
end

--[[
	Handles snippet click event

	@param snippet table - Clicked snippet
	@private
]]
function PluginWidget._onSnippetClicked(snippet)
	-- In fallback mode, insert at end of selected script
	if currentMode == "fallback" then
		local Selection = game:GetService("Selection")
		local selected = Selection:Get()

		if #selected == 1 and selected[1]:IsA("LuaSourceContainer") then
			local script = selected[1]
			local currentSource = script.Source or ""
			script.Source = currentSource .. "\n\n" .. snippet.template
			print("Snippet inserted at end of " .. script.Name)
		else
			warn("Please select a script in Explorer to insert snippet")
		end
	else
		-- In primary mode, would be handled by autocomplete engine
		-- This is a manual insert from the list
		warn("Manual snippet insertion from list not yet implemented for primary mode")
	end
end

--[[
	Opens the settings dialog

	@private
]]
function PluginWidget._openSettings()
	if not pluginInstance or currentMode == "fallback" then
		return
	end

	local currentSettings = {
		SuggestionStyle = pluginInstance:GetSetting("SuggestionStyle") or "inline",
		TriggerKey = pluginInstance:GetSetting("TriggerKey") or "Tab",
		ShowPreview = pluginInstance:GetSetting("ShowPreview") ~= false,
		PreviewStyle = pluginInstance:GetSetting("PreviewStyle") or "Both"
	}

	SettingsDialog.open(currentSettings, function(newSettings)
		-- Save settings
		pluginInstance:SetSetting("SuggestionStyle", newSettings.SuggestionStyle)
		pluginInstance:SetSetting("TriggerKey", newSettings.TriggerKey)
		pluginInstance:SetSetting("ShowPreview", newSettings.ShowPreview)
		pluginInstance:SetSetting("PreviewStyle", newSettings.PreviewStyle)

		-- Handle reset stats
		if newSettings.ResetStats and AutocompleteEngine then
			AutocompleteEngine.resetUsageStats()
		end

		print("Settings saved")
	end)
end

--[[
	Opens the add snippet dialog

	@private
]]
function PluginWidget._openAddDialog()
	AddSnippetDialog.open(function(snippet)
		-- Add snippet to library
		local success, err = SnippetLibrary.addCustomSnippet(snippet)

		if success then
			-- Save custom snippets to plugin settings
			if pluginInstance then
				local customSnippets = SnippetLibrary.getCustomSnippets()
				pluginInstance:SetSetting("CustomSnippets", customSnippets)
			end

			-- Refresh snippet list
			PluginWidget._renderSnippets()

			print("Custom snippet added: " .. snippet.name)
		else
			warn("Failed to add snippet: " .. (err or "Unknown error"))
		end
	end)
end

--[[
	Refreshes API index

	@private
]]
function PluginWidget._refreshApi()
	warn("API refresh not yet implemented")
end

--[[
	Shows instructions for enabling beta features

	@private
]]
function PluginWidget._showBetaInstructions()
	local instructions = [[
To enable Script Editor Beta Features:

1. Go to File → Studio Settings
2. Navigate to Studio tab
3. Scroll to "Script Editor" section
4. Enable "Script Editor Beta Features"
5. Restart Studio
6. Reopen this plugin

Full autocomplete integration will then be available.
]]

	print(instructions)
	warn(instructions)
end

return PluginWidget
