if( not SSAF ) then return end

local Config = SSAF:NewModule("Config")
local L = SSAFLocals

local registered, options, config, dialog, SML

function Config:OnInitialize()
	SML = SSAF.SML

	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\SSArenaFrames\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth", "Interface\\Addons\\SSArenaFrames\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl", "Interface\\Addons\\SSArenaFrames\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze", "Interface\\Addons\\SSArenaFrames\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\SSArenaFrames\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi", "Interface\\Addons\\SSArenaFrames\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped", "Interface\\Addons\\SSArenaFrames\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\SSArenaFrames\\images\\LiteStep")
	SML:Register(SML.MediaType.STATUSBAR, "Minimalist", "Interface\\Addons\\SSArenaFrames\\images\\Minimalist")
end

-- GUI
-- General Set/Get
local function set(info, value)
	SSAF.db.profile[info[(#info)]] = value
	
	SSAF:Reload()
end

local function get(info)
	return SSAF.db.profile[info[(#info)]]
end

-- Set/Get the click action attributes
local function setAttribute(info, value)
	SSAF.db.profile.attributes[info[#(info) - 1]][info[(#info)]] = value
	
	SSAF:Reload()
end

local function getAttribute(info)
	return SSAF.db.profile[info[#(info) - 1]][info[(#info)]]
end

-- Set/Get colors
local function setColor(info, r, g, b)
	set(info, {r = r, g = g, b = b})
end

local function getColor(info)
	local value = get(info)
	if( type(value) == "table" ) then
		return value.r, value.g, value.b
	end
	
	return value
end

-- Grab textures from SML
local textures = {}
function Config:GetTextures()
	for k in pairs(textures) do textures[k] = nil end

	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		textures[name] = name
	end
	
	return textures
end

--[[
local function createAttributeOptions(number)
	local text = string.format(L["Action #%s"], number)
	
	return {
		order = 1,
		type = "group",
		name = text,
		get = get,
		set = set,
		args = {
			enabled = {
				order = 1,
				type = "toggle",
				name = L["Show flag carrier"],
				width = "full",
			},
			color = {
				order = 1,
				type = "toggle",
				name = L["Color carrier name by class"],
				width = "full",
			},
			health = {
				order = 1,
				type = "toggle",
				name = L["Show carrier health when available"],
				width = "full",
			},
			macro = {
				order = 1,
				type = "input",
				multiline = true,
				name = L["Text to execute when clicking the carrier button"],
				width = "full",
			},
		},
	}
end
]]

local function loadOptions()
	options = {}
	options.type = "group"
	options.name = "SSArena Frames"
	
	options.args = {}

	options.args.general = {
		type = "group",
		order = 1,
		name = L["General"],
		get = get,
		set = set,
		handler = Config,
		args = {
			showGuess = {
				order = 1,
				type = "toggle",
				name = L["Show talent guess"],
				desc = L["Shows the enemies talents using the spells that they use, this is not completely accurate but for most specializations it'll be fairly close."],
				width = "full",
			},
			reportEnemies = {
				order = 2,
				type = "toggle",
				name = L["Report enemies to battleground chat"],
				desc = L["Sends information on the enemy when you notice them for the first time in the match."],
				width = "full",
			},
			showMinions = {
				order = 3,
				type = "toggle",
				name = L["Show minions"],
				desc = L["Shows summoned minions in the arena frame."],
			},
			showPets = {
				order = 4,
				type = "toggle",
				name = L["Show pets"],
				desc = L["Shows tamed pets in the arena frames."],
			},
			frame = {
				type = "group",
				order = 5,
				inline = true,
				name = L["Frame"],
				args = {
					locked = {
						order = 1,
						type = "toggle",
						name = L["Lock frames"],
						desc = L["Prevents the arena frame from being moved."],
						width = "full",
					},
					scale = {
						order = 2,
						type = "range",
						name = L["Scale"],
						min = 0, max = 2, step = 0.1,
					},
					barTexture = {
						order = 3,
						type = "select",
						name = L["Bar texture"],
						dialogControl = "LSM30_Statusbar",
						values = "GetTextures",
					},
				},
			},
			display = {
				type = "group",
				order = 6,
				inline = true,
				name = L["Display"],
				args = {
					showID = {
						order = 1,
						type = "toggle",
						name = L["Show row number"],
						desc = L["Adds the row number to the left of the name, this can be used as a quick way of identifying people rather then full name."],
						width = "full",
					},
					showIcon = {
						order = 2,
						type = "toggle",
						name = L["Show class icon"],
						desc = L["Adds the class icon, or the pet icon to the left of the frame row."],
					},
					showTargets = {
						order = 3,
						type = "toggle",
						name = L["Show target icons"],
						desc = L["Adds mini icons to the right of the arena frames with the class of the person targeting an enemy."],
					},
					mana = {
						type = "group",
						order = 4,
						inline = true,
						name = L["Mana"],
						args = {
							showMana = {
								order = 1,
								type = "toggle",
								name = L["Show power bars"],
								desc = L["Adds bars for the enemies power below the row, color is based on power type."],
								width = "full",
							},
							manaBarHeight = {
								order = 2,
								type = "range",
								name = L["Power bar height"],
								min = 1, max = 30, step = 1,
							},
						},
					},
					color = {
						type = "group",
						order = 5,
						inline = true,
						name = L["Color"],
						set = setColor,
						get = getColor,
						args = {
							fontColor = {
								order = 1,
								type = "color",
								name = L["Text color"],
								width = "full",
							},
							petBarColor = {
								order = 2,
								type = "color",
								name = L["Pet bar color"],
							},
							minionBarColor = {
								order = 3,
								type = "color",
								name = L["Minion bar color"],
							},
						},
					},
				},
			},
		},
	}

	-- DB management
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(SSAF.db)
	options.args.profile.order = 2
end

SLASH_SSAF1 = "/ssaf"
SLASH_SSAF2 = "/ssarenaframes"
SlashCmdList["SSAF"] = function()
	if( not config and not dialog ) then
		config = LibStub("AceConfig-3.0")
		dialog = LibStub("AceConfigDialog-3.0")

		if( not options ) then
			loadOptions()
		end

		config:RegisterOptionsTable("SSArena Frames", options)
		dialog:SetDefaultSize("SSArena Frames", 625, 590)
	end

	dialog:Open("SSArena Frames")
end