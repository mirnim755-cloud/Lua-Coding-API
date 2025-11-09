--[[
	SnippetList.lua

	Renders snippet items in a scrolling list with search filtering.
	Handles snippet selection and click events.
]]

local SnippetList = {}

--[[
	Renders snippet items in a scrolling list

	@param parent ScrollingFrame - Parent container to render items in
	@param snippets array - Array of snippet definitions
	@param onClick function - Callback when snippet clicked: onClick(snippet)
]]
function SnippetList.render(parent, snippets, onClick)
	-- Clear existing items first
	SnippetList.clear(parent)

	-- Track total height for canvas size
	local totalHeight = 0
	local itemHeight = 50  -- Each item is 50px tall (20px name + 20px desc + 10px padding)
	local itemSpacing = 5

	for index, snippet in ipairs(snippets) do
		-- Create container frame for snippet item
		local itemFrame = Instance.new("Frame")
		itemFrame.Name = "SnippetItem_" .. snippet.name
		itemFrame.Size = UDim2.new(1, -10, 0, itemHeight)
		itemFrame.Position = UDim2.new(0, 5, 0, totalHeight)
		itemFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = parent

		-- Add UICorner for rounded edges
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = itemFrame

		-- Snippet name label (bold, larger)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "SnippetName"
		nameLabel.Size = UDim2.new(1, -10, 0, 20)
		nameLabel.Position = UDim2.new(0, 5, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = snippet.name
		nameLabel.Font = Enum.Font.SourceSansBold
		nameLabel.TextSize = 14
		nameLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextYAlignment = Enum.TextYAlignment.Top
		nameLabel.Parent = itemFrame

		-- Snippet description label (smaller, gray)
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "SnippetDesc"
		descLabel.Size = UDim2.new(1, -10, 0, 20)
		descLabel.Position = UDim2.new(0, 5, 0, 25)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = snippet.description
		descLabel.Font = Enum.Font.SourceSans
		descLabel.TextSize = 11
		descLabel.TextColor3 = Color3.fromRGB(128, 128, 128)
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = itemFrame

		-- Make item clickable with TextButton
		local clickButton = Instance.new("TextButton")
		clickButton.Name = "ClickButton"
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.Parent = itemFrame

		-- Hover effect
		clickButton.MouseEnter:Connect(function()
			itemFrame.BackgroundColor3 = Color3.fromRGB(232, 232, 232)  -- #e8e8e8
		end)

		clickButton.MouseLeave:Connect(function()
			itemFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end)

		-- Click handler
		clickButton.MouseButton1Click:Connect(function()
			if onClick then
				onClick(snippet)
			end
		end)

		-- Update total height
		totalHeight = totalHeight + itemHeight + itemSpacing
	end

	-- Update canvas size
	parent.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

--[[
	Clears all snippet items from the list

	@param parent ScrollingFrame - Parent container
]]
function SnippetList.clear(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^SnippetItem_") then
			child:Destroy()
		end
	end
end

--[[
	Filters snippets based on search text

	@param snippets array - All snippets
	@param searchText string - Search query
	@return array - Filtered snippets
]]
function SnippetList.filter(snippets, searchText)
	-- Empty search returns all
	if not searchText or searchText == "" then
		return snippets
	end

	local searchLower = searchText:lower()
	local filtered = {}

	for _, snippet in ipairs(snippets) do
		local matches = false

		-- Check name
		if snippet.name:lower():find(searchLower, 1, true) then
			matches = true
		end

		-- Check description
		if snippet.description:lower():find(searchLower, 1, true) then
			matches = true
		end

		-- Check tags
		if snippet.tags then
			for _, tag in ipairs(snippet.tags) do
				if tag:lower():find(searchLower, 1, true) then
					matches = true
					break
				end
			end
		end

		if matches then
			table.insert(filtered, snippet)
		end
	end

	return filtered
end

--[[
	Creates the scrolling frame container for snippet list

	@param parent Instance - Parent GUI element
	@param position UDim2 - Position of scrolling frame
	@param size UDim2 - Size of scrolling frame
	@return ScrollingFrame - Created scrolling frame
]]
function SnippetList.createContainer(parent, position, size)
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "SnippetList"
	scrollingFrame.Position = position
	scrollingFrame.Size = size
	scrollingFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	scrollingFrame.BorderSizePixel = 1
	scrollingFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
	scrollingFrame.ScrollBarThickness = 6
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.Parent = parent

	return scrollingFrame
end

--[[
	Highlights a specific snippet item (for keyboard navigation)

	@param parent ScrollingFrame - Parent container
	@param snippetName string - Name of snippet to highlight
]]
function SnippetList.highlightItem(parent, snippetName)
	-- Remove existing highlights
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^SnippetItem_") then
			child.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end

	-- Highlight target item
	local targetItem = parent:FindFirstChild("SnippetItem_" .. snippetName)
	if targetItem then
		targetItem.BackgroundColor3 = Color3.fromRGB(220, 240, 255)  -- Light blue
	end
end

--[[
	Gets the number of rendered items

	@param parent ScrollingFrame - Parent container
	@return number - Count of snippet items
]]
function SnippetList.getItemCount(parent)
	local count = 0
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^SnippetItem_") then
			count = count + 1
		end
	end
	return count
end

return SnippetList
