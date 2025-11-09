--[[
	ApiIndex.lua

	Bundled Roblox API reference data for autocomplete.
	Provides offline-first access to services, instance types, and enums.
]]

local ApiIndex = {}

-- Bundled API data
local API_DATA = {
	services = {
		"Workspace",
		"Players",
		"ReplicatedStorage",
		"ServerScriptService",
		"ServerStorage",
		"StarterGui",
		"StarterPlayer",
		"StarterPack",
		"Lighting",
		"SoundService",
		"Chat",
		"Teams",
		"BadgeService",
		"GamePassService",
		"MarketplaceService",
		"TeleportService",
		"DataStoreService",
		"HttpService",
		"InsertService",
		"TweenService",
		"UserInputService",
		"ContextActionService",
		"GuiService",
		"TextService",
		"TextChatService",
		"VoiceChatService",
		"LocalizationService",
		"PolicyService",
		"RunService",
		"CollectionService",
		"PhysicsService",
		"PathfindingService",
		"ProximityPromptService",
		"SocialService",
		"MemoryStoreService",
		"MessagingService",
		"ReplicatedFirst",
		"ScriptContext",
		"Selection",
		"ChangeHistoryService",
		"LogService",
		"StudioService",
		"TestService",
		"VRService",
		"AssetService",
		"GroupService",
	},

	instances = {
		-- Primitive objects
		"Part",
		"MeshPart",
		"UnionOperation",
		"TrussPart",
		"WedgePart",
		"CornerWedgePart",
		"SpawnLocation",

		-- Models
		"Model",
		"WorldModel",
		"Folder",

		-- UI objects
		"ScreenGui",
		"BillboardGui",
		"SurfaceGui",
		"Frame",
		"ScrollingFrame",
		"TextLabel",
		"TextBox",
		"TextButton",
		"ImageLabel",
		"ImageButton",
		"ViewportFrame",
		"VideoFrame",
		"UIListLayout",
		"UIGridLayout",
		"UITableLayout",
		"UIPageLayout",
		"UIPadding",
		"UIAspectRatioConstraint",
		"UISizeConstraint",
		"UITextSizeConstraint",
		"UICorner",
		"UIStroke",
		"UIGradient",
		"UIScale",

		-- Effects
		"Fire",
		"Smoke",
		"Sparkles",
		"ParticleEmitter",
		"Beam",
		"Trail",
		"Atmosphere",
		"Sky",
		"Clouds",
		"BloomEffect",
		"BlurEffect",
		"ColorCorrectionEffect",
		"DepthOfFieldEffect",
		"SunRaysEffect",

		-- Lighting
		"PointLight",
		"SpotLight",
		"SurfaceLight",

		-- Humanoid
		"Humanoid",
		"HumanoidDescription",
		"Accessory",
		"Shirt",
		"Pants",
		"ShirtGraphic",
		"BodyColors",

		-- Sounds
		"Sound",
		"SoundGroup",
		"Equalize rSoundEffect",
		"ReverbSoundEffect",
		"DistortionSoundEffect",
		"ChorusSoundEffect",
		"FlangeSoundEffect",
		"PitchShiftSoundEffect",
		"TremoloSoundEffect",
		"CompressorSoundEffect",

		-- Scripts
		"Script",
		"LocalScript",
		"ModuleScript",

		-- Events
		"RemoteEvent",
		"RemoteFunction",
		"BindableEvent",
		"BindableFunction",

		-- Values
		"StringValue",
		"IntValue",
		"NumberValue",
		"BoolValue",
		"ObjectValue",
		"Vector3Value",
		"CFrameValue",
		"Color3Value",
		"BrickColorValue",
		"RayValue",

		-- Constraints
		"HingeConstraint",
		"BallSocketConstraint",
		"RopeConstraint",
		"RodConstraint",
		"SpringConstraint",
		"PrismaticConstraint",
		"CylindricalConstraint",
		"UniversalConstraint",
		"WeldConstraint",
		"RigidConstraint",
		"NoCollisionConstraint",
		"AlignOrientation",
		"AlignPosition",
		"VectorForce",
		"Torque",
		"LineForce",

		-- Animations
		"Animation",
		"AnimationController",
		"Animator",
		"Keyframe",
		"KeyframeSequence",

		-- Camera
		"Camera",

		-- Tools
		"Tool",
		"HopperBin",

		-- Attachments
		"Attachment",
		"Bone",

		-- Terrain
		"TerrainRegion",

		-- Other
		"Configuration",
		"Decal",
		"Texture",
		"SurfaceAppearance",
		"ProximityPrompt",
		"Highlight",
		"SelectionBox",
		"BillboardGui",
		"ClickDetector",
		"TouchTransmitter",
	},

	enums = {
		"KeyCode",
		"UserInputType",
		"Material",
		"PartType",
		"FormFactor",
		"EasingStyle",
		"EasingDirection",
		"RaycastFilterType",
		"NormalId",
		"Axis",
		"Font",
		"TextXAlignment",
		"TextYAlignment",
		"AutomaticSize",
		"FillDirection",
		"HorizontalAlignment",
		"VerticalAlignment",
		"SizeConstraint",
		"AspectType",
		"UIListLayout",
		"SortOrder",
		"ScaleType",
		"TweenStatus",
		"AnimationPriority",
		"HumanoidRigType",
		"HumanoidStateType",
		"JointCreationMode",
		"CollisionFidelity",
		"RenderFidelity",
		"BodyPart",
		"Limb",
		"ChatMode",
		"ChatColor",
		"Platform",
		"DeviceType",
		"VRTouchpad",
		"VRTouchpadMode",
		"PlayerActions",
		"MouseBehavior",
		"FramerateManagerMode",
		"SaveFilter",
		"RenderPriority",
		"ExplosionType",
		"SpecialMesh",
		"MeshType",
		"PathStatus",
		"PathWaypointAction",
		"TeleportState",
		"TeleportType",
		"ThumbnailType",
		"ThumbnailSize",
		"AvatarJointUpgrade",
		"QualityLevel",
		"GraphicsMode",
	},
}

--[[
	Returns list of all Roblox service names

	@return array<string> - Service names
]]
function ApiIndex.getServiceNames()
	return API_DATA.services
end

--[[
	Returns list of common Roblox instance types

	@return array<string> - Instance type names
]]
function ApiIndex.getInstanceTypes()
	return API_DATA.instances
end

--[[
	Returns list of common Roblox enum names

	@return array<string> - Enum names
]]
function ApiIndex.getEnumNames()
	return API_DATA.enums
end

--[[
	Gets API members (methods/properties) for a class
	Currently returns empty - could be populated with full API data

	@param className string - Name of class to get members for
	@return array<table> - Member definitions
]]
function ApiIndex.getApiMembers(className)
	-- Placeholder for full API member data
	-- In a full implementation, this would return methods/properties
	-- from a bundled API dump

	return {}
end

--[[
	Refreshes API data from remote source (optional feature)
	Fetches latest API data from robloxapi.github.io

	@param callback function - Callback(success, errorMessage) when complete
	@param pluginInstance Plugin - Plugin instance for HttpService access
]]
function ApiIndex.refresh(callback, pluginInstance)
	-- Check if HttpService is available
	local success, HttpService = pcall(function()
		return game:GetService("HttpService")
	end)

	if not success or not HttpService then
		if callback then
			callback(false, "HttpService not available")
		end
		return
	end

	-- Note: Roblox plugins cannot make HTTP requests for security reasons
	-- This function is a placeholder for potential future functionality
	-- or for Studio API integration

	warn("API refresh not implemented - HTTP requests not available in plugins")

	if callback then
		callback(false, "API refresh not available in plugin environment")
	end
end

--[[
	Searches for services matching a query

	@param query string - Search query
	@return array<string> - Matching service names
]]
function ApiIndex.searchServices(query)
	if not query or query == "" then
		return API_DATA.services
	end

	local queryLower = query:lower()
	local results = {}

	for _, serviceName in ipairs(API_DATA.services) do
		if serviceName:lower():find(queryLower, 1, true) then
			table.insert(results, serviceName)
		end
	end

	return results
end

--[[
	Searches for instance types matching a query

	@param query string - Search query
	@return array<string> - Matching instance type names
]]
function ApiIndex.searchInstanceTypes(query)
	if not query or query == "" then
		return API_DATA.instances
	end

	local queryLower = query:lower()
	local results = {}

	for _, instanceType in ipairs(API_DATA.instances) do
		if instanceType:lower():find(queryLower, 1, true) then
			table.insert(results, instanceType)
		end
	end

	return results
end

--[[
	Searches for enums matching a query

	@param query string - Search query
	@return array<string> - Matching enum names
]]
function ApiIndex.searchEnums(query)
	if not query or query == "" then
		return API_DATA.enums
	end

	local queryLower = query:lower()
	local results = {}

	for _, enumName in ipairs(API_DATA.enums) do
		if enumName:lower():find(queryLower, 1, true) then
			table.insert(results, enumName)
		end
	end

	return results
end

--[[
	Gets statistics about bundled API data

	@return table - Statistics {services, instances, enums}
]]
function ApiIndex.getStats()
	return {
		services = #API_DATA.services,
		instances = #API_DATA.instances,
		enums = #API_DATA.enums
	}
end

return ApiIndex
