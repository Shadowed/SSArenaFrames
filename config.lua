local Config = SSAF:NewModule("Config")
local L = SSAFLocals

local TOTAL_CLICKIES = 10

local OptionHouse
local HouseAuthority
local SML

function Config:OnInitialize()
	-- Open the OH UI
	SLASH_SSAF1 = "/ssaf"
	SLASH_SSAF2 = "/ssarenaframes"
	SlashCmdList["SSAF"] = function()
		OptionHouse:Open("Arena Frames")
	end
	
	-- Register with OptionHouse
	OptionHouse = LibStub("OptionHouse-1.1")
	HouseAuthority = LibStub("HousingAuthority-1.2")
	
	local OHObj = OptionHouse:RegisterAddOn("Arena Frames", nil, "Mayen", "r" .. tonumber(string.match("$Revision: 402 $", "(%d+)") or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
	
	-- Yes, this is hackish because we're creating new widgets everytime you click the frame
	-- it'll require a change to HA which I need to get around to.
	OHObj:RegisterCategory(L["Click Actions"], self, "CreateClickListUI", true, 2)
	
	for i=1, TOTAL_CLICKIES do
		OHObj:RegisterSubCategory(L["Click Actions"], string.format(L["Action #%d"], i), self, "CreateAttributeUI", nil, i)
	end

	-- Register our default list of textures with SML
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
function Config:Set(var, value)
	SSAF.db.profile[var] = value
end

function Config:Get(var)
	return SSAF.db.profile[var]
end

function Config:Reload()
	SSAF:Reload()
end

function Config:CreateUI()
	local textures = {}
	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		table.insert(textures, {name, name})
	end

	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["General"], order = 1, text = L["Report enemies to battleground chat"], help = L["Sends name, server, class, race and guild to battleground chat when you mouse over or target an enemy."], type = "check", var = "reportEnemies"},
		{ group = L["General"], order = 2, text = L["Show row number"], help = L["Shows the row number next to the name, can be used in place of names for other SSAF/SSPVP users to identify enemies."], type = "check", var = "showID"},
		{ group = L["General"], order = 3, text = L["Show class icon"], help = L["Displays the players class icon to the left of the arena frame on their row."], type = "check", var = "showIcon"},
		{ group = L["General"], order = 4, text = L["Show enemy mage/warlock minions"], help = L["Will display Warlock and Mage minions in the arena frames below all the players."], type = "check", var = "showMinions"},
		{ group = L["General"], order = 5, text = L["Show enemy hunter pets"], help = L["Will display Hunter pets in the arena frames below all the players."], type = "check", var = "showPets"},
		{ group = L["General"], order = 8, text = L["Show whos targeting an enemy"], help = L["Shows a little button to the right side of the enemies row for whos targeting them, it's colored by class of the person targeting them."], type = "check", var = "targetDots"},

		{ group = L["Frame"], type = "groupOrder", order = 2 },
		{ group = L["Frame"], order = 1, text = L["Lock arena frame"], help = L["Allows you to move the arena frames around, will also show a few examples. You will be unable to target anything while the arena frames are unlocked."], type = "check", var = "locked"},
		{ group = L["Frame"], order = 2, format = L["Frame Scale: %d%%"], help = L["Allows you to increase, or decrease the total size of the arena frames."], min = 0.0, max = 2.0, type = "slider", var = "scale"},

		{ group = L["Display"], type = "groupOrder", order = 3 },
		{ group = L["Display"], order = 1, text = L["Bar texture"], help = L["Texture to use for health, mana and party target bars."], type = "dropdown", list = textures, var = "barTexture"},

		{ group = L["Mana"], type = "groupOrder", order = 4 },
		{ group = L["Mana"], order = 1, text = L["Show mana bars"], help = L["Shows a mana bar at the bottom of the health bar, requires you or a party member to target the enemy for them to update."], type = "check", var = "manaBar"},
		{ group = L["Mana"], order = 2, text = L["Mana bar height"], help = L["Height of the mana bars, the health bar will not resize for this however."], type = "input", numeric = true, default = 3, width = 30, var = "manaBarHeight"},

		{ group = L["Color"], type = "groupOrder", order = 5 },
		{ group = L["Color"], order = 1, text = L["Pet health bar color"], help = L["Hunter pet health bar color."], type = "color", var = "petBarColor"},
		{ group = L["Color"], order = 2, text = L["Minion health bar color"], help = L["Warlock and Mage pet health bar color."], type = "color", var = "minionBarColor"},
		{ group = L["Color"], order = 3, text = L["Name and health text font color"], type = "color", var = "fontColor"},
	}

	-- Update the dropdown incase any new textures were added
	return HouseAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = self})
end

-- Listing click actions by class/binding/ect
local cachedFrame
function Config:OpenAttributeUI(var)
	OptionHouse:Open("Arena Frames", L["Click Actions"], string.format(L["Action #%d"], var))
end

function Config:CreateClickListUI()
	-- This lets us implement at least a basic level of caching
	if( cachedFrame ) then
		return cachedFrame
	end
	
	local config = {}
	
	for i=1, TOTAL_CLICKIES do
		local row = SSAF.db.profile.attributes[i]
		if( row ) then
			local enabled = GREEN_FONT_COLOR_CODE .. L["Enabled"] .. FONT_COLOR_CODE_CLOSE
			if( not row.enabled ) then
				enabled = RED_FONT_COLOR_CODE .. L["Disabled"] .. FONT_COLOR_CODE_CLOSE
			end
			
			local key = row.modifier or ""
			if( key == "" ) then
				key = L["All"]
			elseif( key == "ctrl-" ) then
				key = L["CTRL"]			
			elseif( key == "shift-" ) then
				key = L["SHIFT"]			
			elseif( key == "alt-" ) then
				key = L["ALT"]			
			end
			
			local mouse = row.button or ""
			if( mouse == "" ) then
				mouse = L["Any button"]
			elseif( mouse == "1" ) then
				mouse = L["Left button"]
			elseif( mouse == "2" ) then
				mouse = L["Right button"]
			elseif( mouse == "3" ) then
				mouse = L["Middle button"]
			elseif( mouse == "4" ) then
				mouse = L["Button 4"]
			elseif( mouse == "5" ) then
				mouse = L["Button 5"]
			end
			
			-- Grab total classes enabled for this
			local total = 0
			if( row.classes ) then
				for _ in pairs(row.classes) do
					total = total + 1
				end
			end
			
			table.insert(config, { group = "#" .. i, type = "groupOrder", order = i })
			table.insert(config, { group = "#" .. i, text = enabled, type = "label", xPos = 5, yPos = 0, font = GameFontHighlightSmall })
			table.insert(config, { group = "#" .. i, text = L["Edit"], type = "button", onSet = "OpenAttributeUI", var = i})
			table.insert(config, { group = "#" .. i, text = string.format(L["Classes: %s"], "|cffffffff" .. total .. "|r"), type = "label", xPos = 50, yPos = 0, font = GameFontNormalSmall })
			table.insert(config, { group = "#" .. i, text = string.format(L["Modifier: %s"], "|cffffffff" .. key .. "|r"), type = "label", xPos = 75, yPos = 0, font = GameFontNormalSmall })
			table.insert(config, { group = "#" .. i, text = string.format(L["Mouse: %s"], "|cffffffff" .. mouse .. "|r"), type = "label", xPos = 100, yPos = 0, font = GameFontNormalSmall })
		end
	end

	-- Update the dropdown incase any new textures were added
	cachedFrame = HouseAuthority:CreateConfiguration(config, {handler = self, columns = 5})
	
	return cachedFrame
end

-- Modifying click actions
function Config:AttribSet(var, value)
	cachedFrame = nil
	
	-- Not created yet, set to default
	if( not SSAF.db.profile[var[1]][var[2]] ) then
		SSAF.db.profile[var[1]][var[2]] = { enabled = false, classes = { ["ALL"] = true }, text = "/targetexact *name", modifier = "", button = "" }
	end
	
	SSAF.db.profile[var[1]][var[2]][var[3]] = value
end

function Config:AttribGet(var)
	-- Not created yet, set to default
	if( not SSAF.db.profile[var[1]][var[2]] ) then
		cachedFrame = nil
		SSAF.db.profile[var[1]][var[2]] = { enabled = false, classes = { ["ALL"] = true }, text = "/targetexact *name", modifier = "", button = "" }
	end
	
	return SSAF.db.profile[var[1]][var[2]][var[3]]
end

function Config:AttribOnSet()
	SSAF:UpdateEnemies()
end

function Config:CreateAttributeUI(category, attributeID)
	attributeID = tonumber(string.match(attributeID, "(%d+)"))
	if( not attributeID ) then
		return
	end

	-- Laugh at this now, when we get death knights I'll be the victor!
	local classes = {}
	table.insert(classes, {"ALL", L["All"]})
	table.insert(classes, {"PET", L["Pet"]})
	table.insert(classes, {"MINION", L["Minion"]})
	
	for k, v in pairs(L["CLASSES"]) do
		table.insert(classes, {k, v})
	end
		
	local config = {
		{ order = 1, group = L["Enable"], text = L["Enable macro case"], help = L["Enables the macro text entered to be ran on the specified modifier key and mouse button combo."], default = false, type = "check", var = {"attributes", attributeID, "enabled"}},
		{ order = 2, group = L["Enable"], text = L["Enable for class"], help = L["Enables the macro for a specific class, or for pets only."], default = "ALL", list = classes, multi = true, type = "dropdown", var = {"attributes", attributeID, "classes"}},
		
		{ order = 1, group = L["Modifiers"], text = L["Modifier key"], type = "dropdown", list = {{"", L["All"]}, {"ctrl-", L["CTRL"]}, {"shift-", L["SHIFT"]}, {"alt-", L["ALT"]}}, default = "", var = {"attributes", attributeID, "modifier"}},
		{ order = 2, group = L["Modifiers"], text = L["Mouse button"], type = "dropdown", list = {{"", L["Any button"]}, {"1", L["Left button"]}, {"2", L["Right button"]}, {"3", L["Middle button"]}, {"4", L["Button 4"]}, {"5", L["Button 5"]}}, default = "", var = {"attributes", attributeID, "button"}},

		{ order = 1, group = L["Macro Text"], text = L["Command to execute when clicking the frame using the above modifier/mouse button"], type = "editbox", default = "/targetexact *name", var = {"attributes", attributeID, "text"}},
	}
	
	return HouseAuthority:CreateConfiguration(config, {set = "AttribSet", get = "AttribGet", onSet = "AttribOnSet", handler = self})
end