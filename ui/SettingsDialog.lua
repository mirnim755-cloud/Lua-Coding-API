--[[
	SettingsDialog.lua

	Settings configuration UI for the autocomplete plugin.
	Provides controls for suggestion style, trigger keys, preview options, and usage stats.
]]

local SettingsDialog = {}

-- State
local dialogOpen = false
local dialogGui = nil
local currentSettings = {}
local onSaveCallback = nil

--[[
	Opens the settings dialog

	@param settings table - Current settings to display
	@param onSave function - Callback when settings saved: onSave(newSettings)
]]
function SettingsDialog.open(settings, onSave)
	if dialogOpen then
		return
	end

	currentSettings = settings or {}
	onSaveCallback = onSave

	-- Create dialog GUI
	dialogGui = Instance.new("ScreenGui")
	dialogGui.Name = "SettingsDialog"
	dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	dialogGui.Parent = game:GetService("CoreGui")

	-- Semi-transparent background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = dialogGui

	-- Main dialog frame
	local dialog = Instance.new("Frame")
	dialog.Name = "Dialog"
	dialog.Size = UDim2.new(0, 400, 0, 450)
	dialog.Position = UDim2.new(0.5, -200, 0.5, -225)
	dialog.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	dialog.BorderSizePixel = 1
	dialog.BorderColor3 = Color3.fromRGB(100, 100, 100)
	dialog.Parent = overlay

	-- Dialog corner rounding
	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 8)
	dialogCorner.Parent = dialog

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = dialog

	local titleBarCorner = Instance.new("UICorner")
	titleBarCorner.CornerRadius = UDim.new(0, 8)
	titleBarCorner.Parent = titleBar

	-- Title text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Settings"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 18
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Content area
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -100)
	content.Position = UDim2.new(0, 10, 0, 50)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.CanvasSize = UDim2.new(0, 0, 0, 350)
	content.Parent = dialog

	local yOffset = 10

	-- Helper function to create a setting row
	local function createSettingRow(label, control, height)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, height)
		row.Position = UDim2.new(0, 0, 0, yOffset)
		row.BackgroundTransparency = 1
		row.Parent = content

		local labelText = Instance.new("TextLabel")
		labelText.Size = UDim2.new(1, 0, 0, 20)
		labelText.BackgroundTransparency = 1
		labelText.Text = label
		labelText.Font = Enum.Font.SourceSansBold
		labelText.TextSize = 14
		labelText.TextColor3 = Color3.fromRGB(0, 0, 0)
		labelText.TextXAlignment = Enum.TextXAlignment.Left
		labelText.Parent = row

		control.Position = UDim2.new(0, 0, 0, 25)
		control.Parent = row

		yOffset = yOffset + height + 10
		return row
	end

	-- Suggestion Style dropdown
	local suggestionStyleFrame = Instance.new("Frame")
	suggestionStyleFrame.Size = UDim2.new(1, 0, 0, 30)
	suggestionStyleFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	suggestionStyleFrame.BorderSizePixel = 1
	suggestionStyleFrame.BorderColor3 = Color3.fromRGB(180, 180, 180)

	local suggestionStyleLabel = Instance.new("TextLabel")
	suggestionStyleLabel.Size = UDim2.new(1, -10, 1, 0)
	suggestionStyleLabel.Position = UDim2.new(0, 5, 0, 0)
	suggestionStyleLabel.BackgroundTransparency = 1
	suggestionStyleLabel.Text = currentSettings.SuggestionStyle or "inline"
	suggestionStyleLabel.Font = Enum.Font.SourceSans
	suggestionStyleLabel.TextSize = 13
	suggestionStyleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	suggestionStyleLabel.TextXAlignment = Enum.TextXAlignment.Left
	suggestionStyleLabel.Parent = suggestionStyleFrame

	createSettingRow("Suggestion Style", suggestionStyleFrame, 60)

	-- Trigger Key dropdown
	local triggerKeyFrame = Instance.new("Frame")
	triggerKeyFrame.Size = UDim2.new(1, 0, 0, 30)
	triggerKeyFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	triggerKeyFrame.BorderSizePixel = 1
	triggerKeyFrame.BorderColor3 = Color3.fromRGB(180, 180, 180)

	local triggerKeyLabel = Instance.new("TextLabel")
	triggerKeyLabel.Size = UDim2.new(1, -10, 1, 0)
	triggerKeyLabel.Position = UDim2.new(0, 5, 0, 0)
	triggerKeyLabel.BackgroundTransparency = 1
	triggerKeyLabel.Text = currentSettings.TriggerKey or "Tab"
	triggerKeyLabel.Font = Enum.Font.SourceSans
	triggerKeyLabel.TextSize = 13
	triggerKeyLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	triggerKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
	triggerKeyLabel.Parent = triggerKeyFrame

	createSettingRow("Trigger Key", triggerKeyFrame, 60)

	-- Show Preview checkbox
	local showPreviewCheckbox = Instance.new("TextButton")
	showPreviewCheckbox.Size = UDim2.new(0, 20, 0, 20)
	showPreviewCheckbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	showPreviewCheckbox.BorderSizePixel = 1
	showPreviewCheckbox.BorderColor3 = Color3.fromRGB(100, 100, 100)
	showPreviewCheckbox.Text = currentSettings.ShowPreview ~= false and "✓" or ""
	showPreviewCheckbox.Font = Enum.Font.SourceSansBold
	showPreviewCheckbox.TextSize = 16
	showPreviewCheckbox.TextColor3 = Color3.fromRGB(0, 150, 0)

	showPreviewCheckbox.MouseButton1Click:Connect(function()
		currentSettings.ShowPreview = not (currentSettings.ShowPreview ~= false)
		showPreviewCheckbox.Text = currentSettings.ShowPreview and "✓" or ""
	end)

	createSettingRow("Show Preview", showPreviewCheckbox, 50)

	-- Preview Style dropdown
	local previewStyleFrame = Instance.new("Frame")
	previewStyleFrame.Size = UDim2.new(1, 0, 0, 30)
	previewStyleFrame.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	previewStyleFrame.BorderSizePixel = 1
	previewStyleFrame.BorderColor3 = Color3.fromRGB(180, 180, 180)

	local previewStyleLabel = Instance.new("TextLabel")
	previewStyleLabel.Size = UDim2.new(1, -10, 1, 0)
	previewStyleLabel.Position = UDim2.new(0, 5, 0, 0)
	previewStyleLabel.BackgroundTransparency = 1
	previewStyleLabel.Text = currentSettings.PreviewStyle or "Both"
	previewStyleLabel.Font = Enum.Font.SourceSans
	previewStyleLabel.TextSize = 13
	previewStyleLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	previewStyleLabel.TextXAlignment = Enum.TextXAlignment.Left
	previewStyleLabel.Parent = previewStyleFrame

	createSettingRow("Preview Style", previewStyleFrame, 60)

	-- Reset Usage Stats button
	local resetStatsButton = Instance.new("TextButton")
	resetStatsButton.Size = UDim2.new(1, 0, 0, 35)
	resetStatsButton.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
	resetStatsButton.BorderSizePixel = 0
	resetStatsButton.Text = "Reset Usage Statistics"
	resetStatsButton.Font = Enum.Font.SourceSansBold
	resetStatsButton.TextSize = 14
	resetStatsButton.TextColor3 = Color3.fromRGB(255, 255, 255)

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 4)
	resetCorner.Parent = resetStatsButton

	resetStatsButton.MouseButton1Click:Connect(function()
		-- This will be handled by the plugin
		currentSettings.ResetStats = true
	end)

	createSettingRow("", resetStatsButton, 60)

	-- Button bar at bottom
	local buttonBar = Instance.new("Frame")
	buttonBar.Name = "ButtonBar"
	buttonBar.Size = UDim2.new(1, 0, 0, 50)
	buttonBar.Position = UDim2.new(0, 0, 1, -50)
	buttonBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	buttonBar.BorderSizePixel = 0
	buttonBar.Parent = dialog

	-- Save button
	local saveButton = Instance.new("TextButton")
	saveButton.Name = "SaveButton"
	saveButton.Size = UDim2.new(0, 100, 0, 30)
	saveButton.Position = UDim2.new(1, -220, 0.5, -15)
	saveButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	saveButton.BorderSizePixel = 0
	saveButton.Text = "Save"
	saveButton.Font = Enum.Font.SourceSansBold
	saveButton.TextSize = 14
	saveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveButton.Parent = buttonBar

	local saveCorner = Instance.new("UICorner")
	saveCorner.CornerRadius = UDim.new(0, 4)
	saveCorner.Parent = saveButton

	saveButton.MouseButton1Click:Connect(function()
		if onSaveCallback then
			onSaveCallback(currentSettings)
		end
		SettingsDialog.close()
	end)

	-- Cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0, 100, 0, 30)
	cancelButton.Position = UDim2.new(1, -110, 0.5, -15)
	cancelButton.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "Cancel"
	cancelButton.Font = Enum.Font.SourceSansBold
	cancelButton.TextSize = 14
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.Parent = buttonBar

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 4)
	cancelCorner.Parent = cancelButton

	cancelButton.MouseButton1Click:Connect(function()
		SettingsDialog.close()
	end)

	dialogOpen = true
end

--[[
	Closes the settings dialog

	@return void
]]
function SettingsDialog.close()
	if not dialogOpen then
		return
	end

	if dialogGui then
		dialogGui:Destroy()
		dialogGui = nil
	end

	dialogOpen = false
	currentSettings = {}
	onSaveCallback = nil
end

--[[
	Checks if settings dialog is currently open

	@return boolean - True if dialog is open
]]
function SettingsDialog.isOpen()
	return dialogOpen
end

return SettingsDialog
