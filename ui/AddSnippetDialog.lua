--[[
	AddSnippetDialog.lua

	UI for creating custom snippets.
	Provides form with validation for name, description, template, category, and tags.
]]

local AddSnippetDialog = {}

-- State
local dialogOpen = false
local dialogGui = nil
local onAddCallback = nil

-- Form field values
local nameValue = ""
local descriptionValue = ""
local templateValue = ""
local categoryValue = "custom"
local tagsValue = ""

--[[
	Opens the add snippet dialog

	@param onAdd function - Callback when snippet added: onAdd(snippet)
]]
function AddSnippetDialog.open(onAdd)
	if dialogOpen then
		return
	end

	onAddCallback = onAdd

	-- Reset form values
	nameValue = ""
	descriptionValue = ""
	templateValue = ""
	categoryValue = "custom"
	tagsValue = ""

	-- Create dialog GUI
	dialogGui = Instance.new("ScreenGui")
	dialogGui.Name = "AddSnippetDialog"
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
	dialog.Size = UDim2.new(0, 500, 0, 600)
	dialog.Position = UDim2.new(0.5, -250, 0.5, -300)
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
	titleLabel.Text = "Add Custom Snippet"
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 18
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Content area
	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -140)
	content.Position = UDim2.new(0, 10, 0, 50)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.CanvasSize = UDim2.new(0, 0, 0, 500)
	content.Parent = dialog

	local yOffset = 10

	-- Helper function to create form field
	local function createFormField(label, placeholder, height, multiline)
		local fieldFrame = Instance.new("Frame")
		fieldFrame.Size = UDim2.new(1, 0, 0, height + 30)
		fieldFrame.Position = UDim2.new(0, 0, 0, yOffset)
		fieldFrame.BackgroundTransparency = 1
		fieldFrame.Parent = content

		local labelText = Instance.new("TextLabel")
		labelText.Size = UDim2.new(1, 0, 0, 20)
		labelText.BackgroundTransparency = 1
		labelText.Text = label
		labelText.Font = Enum.Font.SourceSansBold
		labelText.TextSize = 14
		labelText.TextColor3 = Color3.fromRGB(0, 0, 0)
		labelText.TextXAlignment = Enum.TextXAlignment.Left
		labelText.Parent = fieldFrame

		local textBox = Instance.new("TextBox")
		textBox.Size = UDim2.new(1, 0, 0, height)
		textBox.Position = UDim2.new(0, 0, 0, 25)
		textBox.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
		textBox.BorderSizePixel = 1
		textBox.BorderColor3 = Color3.fromRGB(180, 180, 180)
		textBox.PlaceholderText = placeholder
		textBox.Text = ""
		textBox.Font = Enum.Font.SourceSans
		textBox.TextSize = 13
		textBox.TextColor3 = Color3.fromRGB(0, 0, 0)
		textBox.TextXAlignment = Enum.TextXAlignment.Left
		textBox.TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
		textBox.ClearTextOnFocus = false
		textBox.MultiLine = multiline or false
		textBox.TextWrapped = multiline or false
		textBox.Parent = fieldFrame

		local textBoxCorner = Instance.new("UICorner")
		textBoxCorner.CornerRadius = UDim.new(0, 4)
		textBoxCorner.Parent = textBox

		yOffset = yOffset + height + 40

		return textBox
	end

	-- Name field
	local nameBox = createFormField("Name*", "e.g., mysnippet", 30, false)
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		nameValue = nameBox.Text
	end)

	-- Description field
	local descBox = createFormField("Description*", "Brief description of snippet", 30, false)
	descBox:GetPropertyChangedSignal("Text"):Connect(function()
		descriptionValue = descBox.Text
	end)

	-- Template field (multiline)
	local templateBox = createFormField("Template*", 'Code with placeholders ($1, $2, $0)\nExample: local $1 = Instance.new("$2")', 120, true)
	templateBox:GetPropertyChangedSignal("Text"):Connect(function()
		templateValue = templateBox.Text
	end)

	-- Category dropdown (simplified as text for now)
	local categoryBox = createFormField("Category", "custom, essential, common, or advanced", 30, false)
	categoryBox.Text = "custom"
	categoryBox:GetPropertyChangedSignal("Text"):Connect(function()
		categoryValue = categoryBox.Text
	end)

	-- Tags field
	local tagsBox = createFormField("Tags", "Comma-separated tags (e.g., loop, utility)", 30, false)
	tagsBox:GetPropertyChangedSignal("Text"):Connect(function()
		tagsValue = tagsBox.Text
	end)

	-- Preview section
	local previewLabel = Instance.new("TextLabel")
	previewLabel.Size = UDim2.new(1, 0, 0, 20)
	previewLabel.Position = UDim2.new(0, 0, 0, yOffset)
	previewLabel.BackgroundTransparency = 1
	previewLabel.Text = "Preview"
	previewLabel.Font = Enum.Font.SourceSansBold
	previewLabel.TextSize = 14
	previewLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	previewLabel.TextXAlignment = Enum.TextXAlignment.Left
	previewLabel.Parent = content

	local previewBox = Instance.new("TextLabel")
	previewBox.Size = UDim2.new(1, 0, 0, 100)
	previewBox.Position = UDim2.new(0, 0, 0, yOffset + 25)
	previewBox.BackgroundColor3 = Color3.fromRGB(240, 248, 255)
	previewBox.BorderSizePixel = 1
	previewBox.BorderColor3 = Color3.fromRGB(180, 180, 180)
	previewBox.Text = ""
	previewBox.Font = Enum.Font.Code
	previewBox.TextSize = 12
	previewBox.TextColor3 = Color3.fromRGB(0, 0, 0)
	previewBox.TextXAlignment = Enum.TextXAlignment.Left
	previewBox.TextYAlignment = Enum.TextYAlignment.Top
	previewBox.TextWrapped = true
	previewBox.Parent = content

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 4)
	previewCorner.Parent = previewBox

	-- Update preview when template changes
	templateBox:GetPropertyChangedSignal("Text"):Connect(function()
		previewBox.Text = templateBox.Text
	end)

	-- Error message label
	local errorLabel = Instance.new("TextLabel")
	errorLabel.Name = "ErrorLabel"
	errorLabel.Size = UDim2.new(1, -20, 0, 30)
	errorLabel.Position = UDim2.new(0, 10, 1, -90)
	errorLabel.BackgroundTransparency = 1
	errorLabel.Text = ""
	errorLabel.Font = Enum.Font.SourceSans
	errorLabel.TextSize = 13
	errorLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
	errorLabel.TextXAlignment = Enum.TextXAlignment.Left
	errorLabel.TextWrapped = true
	errorLabel.Visible = false
	errorLabel.Parent = dialog

	-- Button bar at bottom
	local buttonBar = Instance.new("Frame")
	buttonBar.Name = "ButtonBar"
	buttonBar.Size = UDim2.new(1, 0, 0, 50)
	buttonBar.Position = UDim2.new(0, 0, 1, -50)
	buttonBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
	buttonBar.BorderSizePixel = 0
	buttonBar.Parent = dialog

	-- Add button
	local addButton = Instance.new("TextButton")
	addButton.Name = "AddButton"
	addButton.Size = UDim2.new(0, 100, 0, 30)
	addButton.Position = UDim2.new(1, -220, 0.5, -15)
	addButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70)
	addButton.BorderSizePixel = 0
	addButton.Text = "Add"
	addButton.Font = Enum.Font.SourceSansBold
	addButton.TextSize = 14
	addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	addButton.Parent = buttonBar

	local addCorner = Instance.new("UICorner")
	addCorner.CornerRadius = UDim.new(0, 4)
	addCorner.Parent = addButton

	addButton.MouseButton1Click:Connect(function()
		-- Validate form
		local error = AddSnippetDialog._validateForm()
		if error then
			errorLabel.Text = error
			errorLabel.Visible = true
			return
		end

		-- Parse tags
		local tags = {}
		if tagsValue and tagsValue ~= "" then
			for tag in tagsValue:gmatch("[^,]+") do
				local trimmed = tag:match("^%s*(.-)%s*$")
				if trimmed and trimmed ~= "" then
					table.insert(tags, trimmed)
				end
			end
		end

		-- Create snippet object
		local snippet = {
			name = nameValue,
			description = descriptionValue,
			template = templateValue,
			category = categoryValue,
			tags = tags
		}

		-- Call callback
		if onAddCallback then
			onAddCallback(snippet)
		end

		AddSnippetDialog.close()
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
		AddSnippetDialog.close()
	end)

	dialogOpen = true
end

--[[
	Validates the form fields

	@return string|nil - Error message if validation failed, nil if valid
	@private
]]
function AddSnippetDialog._validateForm()
	-- Name required
	if not nameValue or nameValue == "" then
		return "Error: Snippet name is required"
	end

	-- Name must be alphanumeric
	if not nameValue:match("^[a-zA-Z0-9_]+$") then
		return "Error: Snippet name must be alphanumeric (letters, numbers, underscore)"
	end

	-- Description required
	if not descriptionValue or descriptionValue == "" then
		return "Error: Description is required"
	end

	-- Template required
	if not templateValue or templateValue == "" then
		return "Error: Template is required"
	end

	return nil
end

--[[
	Closes the add snippet dialog

	@return void
]]
function AddSnippetDialog.close()
	if not dialogOpen then
		return
	end

	if dialogGui then
		dialogGui:Destroy()
		dialogGui = nil
	end

	dialogOpen = false
	onAddCallback = nil

	-- Reset form values
	nameValue = ""
	descriptionValue = ""
	templateValue = ""
	categoryValue = "custom"
	tagsValue = ""
end

--[[
	Checks if add snippet dialog is currently open

	@return boolean - True if dialog is open
]]
function AddSnippetDialog.isOpen()
	return dialogOpen
end

return AddSnippetDialog
