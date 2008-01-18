--[[ 
	SSArena Frames By Amarand (Horde) / Mayen (Horde) from Icecrown (US) PvE
]]

SSAF = LibStub("AceAddon-3.0"):NewAddon("SSAF", "AceEvent-3.0")

local L = SSAFLocals
local CREATED_ROWS = 0
local DOT_FIRSTROW = 11
local DOT_SECONDROW = 20

local instanceType
local queuedUpdates = {}

local enemies = {}
local enemyPets = {}

local displayRows = {}

-- For ToT
local partyTargets = {["party1target"] = {}, ["party2target"] = {}, ["party3target"] = {}, ["party4target"] = {}}
local usedRows = {}

local PartySlain
local SelfSlain
local WaterDies

local AceComm

-- Map of pet type to icon
local petClassIcons = {
	["Voidwalker"] = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
	["Felhunter"] = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
	["Felguard"] = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
	["Succubus"] = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
	["Imp"] = "Interface\\Icons\\Spell_Shadow_SummonImp",
	["Cat"] = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
	["Bat"] = "Interface\\Icons\\Ability_Hunter_Pet_Bat",
	["Bear"] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
	["Boar"] = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
	["Crab"] = "Interface\\Icons\\Ability_Hunter_Pet_Crab",
	["Crocolisk"] = "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk",
	["Dragonhawk"] = "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk",
	["Gorilla"] = "Interface\\Icons\\Ability_Hunter_Pet_Gorilla",
	["Hyena"] = "Interface\\Icons\\Ability_Hunter_Pet_Hyena",
	["Netherray"] = "Interface\\Icons\\Ability_Hunter_Pet_NetherRay",
	["Owl"] = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
	["Raptor"] = "Interface\\Icons\\Ability_Hunter_Pet_Raptor",
	["Ravager"] = "Interface\\Icons\\Ability_Hunter_Pet_Ravager",
	["Scorpid"] = "Interface\\Icons\\Ability_Hunter_Pet_Scorpid",
	["Spider"] = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
	["Sporebat"] = "Interface\\Icons\\Ability_Hunter_Pet_Sporebat",
	["Tallstrider"] = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
	["Turtle"] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
	["Vulture"] = "Interface\\Icons\\Ability_Hunter_Pet_Vulture",
	["Warp Stalker"] = "Interface\\Icons\\Ability_Hunter_Pet_WarpStalker",
	["Windserpent"] = "Interface\\Icons\\Ability_Hunter_Pet_WindSerpent",
	["Wolf"] = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
	[L["Water Elemental"]] = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2",
}

function SSAF:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			locked = true,
			targetDots = true,
			reportEnemies = true,
			barTexture = "Interface\\TargetingFrame\\UI-StatusBar",
			showID = false,
			showIcon = false,
			showMinions = true,
			showPets = false,
			showTalents = true,
			manaBar = true,
			manaBarHeight = 3,
			position = { x = 300, y = 600 },
			fontColor = { r = 1.0, g = 1.0, b = 1.0 },
			petBarColor = { r = 0.20, g = 1.0, b = 0.20 },
			minionBarColor = { r = 0.30, g = 1.0, b = 0.30 },
			attributes = {
				-- Valid modifiers: shift, ctrl, alt
				-- LeftButton/RightButton/MiddleButton/Button4/Button5
				-- All numbered from left -> right as 1 -> 5
				{ enabled = true, classes = { ["ALL"] = true }, modifier = "", button = "", text = "/targetexact *name" },
			}
		}
	}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SSAFDB", self.defaults)

	
	-- Events we want active all the time
	-- The only reason we do a ZCNA check in UBS is mostly to be safe incase you log in
	-- I guess this isn't possible....but if you reload in an arena it is
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BINDINGS")

	-- Party/We killed someone
	PartySlain = string.gsub(PARTYKILLOTHER, "%%s", "(.+)")
	SelfSlain = string.gsub(SELFKILLOTHER, "%%s", "(.+)")
	WaterDies = string.format(UNITDIESOTHER, L["Water Elemental"])	
	
	self.rows = {}
end

function SSAF:JoinedArena()
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MANA", "UPDATE_POWER")
	self:RegisterEvent("UNIT_RAGE", "UPDATE_POWER")
	self:RegisterEvent("UNIT_ENERGY", "UPDATE_POWER")
	self:RegisterEvent("UNIT_FOCUS", "UPDATE_POWER")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
	
	-- Enable syncing
	self.modules.Sync:EnableModule()
	
	-- Pre-create if need be
	for i=CREATED_ROWS, 10 do
		self:CreateRow()
	end
end

function SSAF:LeftArena()
	-- Disable syncing
	self.modules.Sync:DisableModule()
	self:UnregisterOOCUpdate("UpdateEnemies")

	if( InCombatLockdown() ) then
		self:RegisterOOCUpdate("ClearEnemies")
	else
		self:ClearEnemies()
	end
	
	self:UnregisterAllEvents()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BINDINGS")
end

-- 1 = Top left / 2 = Bottom left / 3 = Bottom right / 4 = Top right
function SSAF:UpdateToTTextures(row, totalTargets)
	if( row.currentStyle == totalTargets ) then
		return
	end
	
		
	-- Reset size
	for _, target in pairs(row.targets) do
		target:SetHeight(8)
		target:SetWidth(8)
	end
		
	-- 1 dot
	if( totalTargets == 1 ) then
		row.targets[1]:SetHeight(16)
		row.targets[1]:SetWidth(16)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", 15, 0)

	-- 2 dots
	elseif( totalTargets == 2 ) then
		row.targets[1]:SetWidth(16)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", 15, 4)

		row.targets[2]:SetWidth(16)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", 15, -4)
	
	-- 3 dots
	elseif( totalTargets == 3 ) then
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 4)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, -4)

		row.targets[3]:SetHeight(16)
		row.targets[3]:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, 0)
	
	-- 4 dots
	else
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 4)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, -4)
		row.targets[3]:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, -4)
	end

	row.currentStyle = totalTargets
end

-- Set up bindings
function SSAF:UPDATE_BINDINGS()
	if( not self.frame ) then
		return
	end
	
	for i=1, CREATED_ROWS do
		local bindKey = GetBindingKey("ARENATAR" .. i)
				
		if( bindKey ) then
			SetOverrideBindingClick(self.rows[i].button, false, bindKey, self.rows[i].button:GetName())	
		else
			ClearOverrideBindings(self.rows[i].button)
		end
	end
end

-- Check if an enemy died
function SSAF:CHAT_MSG_COMBAT_HOSTILE_DEATH(event, msg)
	-- Check if someone in our party killed them
	if( string.match(msg, PartySlain) ) then
		local died = string.match(msg, PartySlain)

		self:EnemyDied(died)		
		self:SendMessage("ENEMYDIED:" .. died)

	-- Check if we killed them
	elseif( string.match(msg, SelfSlain) ) then
		local died = string.match(msg, SelfSlain)

		self:EnemyDied(died)
		self:SendMessage("ENEMYDIED:" .. died)
	
	-- Water elemental died (time limit hit)
	elseif( msg == WaterDies ) then
		self:EnemyDied(L["Water Elemental"])
		self:SendMessage("ENEMYDIED:" .. L["Water Elemental"])
	end
end

-- Update all of the ToT stuff
function SSAF:UpdateToT()
	if( not self.db.profile.targetDots ) then
		return
	end
	
	-- Reset the current target icons
	for id in pairs(usedRows) do
		self.rows[id].usedIcons = 0
		for _, texture in pairs(self.rows[id].targets) do
			texture:Hide()
		end
		
		usedRows[id] = nil
	end
		
	-- Now update them
	for unit, data in pairs(partyTargets) do
		local enemy
		
		-- Figure out if we're targeting a pet or a player
		if( enemies[data.name] and data.isPlayer ) then
			enemy = enemies[data.name]
		elseif( enemyPets[data.name] and not data.isPlayer ) then
			enemy = enemyPets[data.name]
		end
				
		if( enemy and enemy.displayRow ) then
			-- Set the row to having a dot active
			usedRows[enemy.displayRow] = true
			
			-- Update how many icons are active
			self.rows[enemy.displayRow].usedIcons = (self.rows[enemy.displayRow].usedIcons or 0) + 1
			
			-- Color the icon by the class of the person targeting them
			local texture = self.rows[enemy.displayRow].targets[self.rows[enemy.displayRow].usedIcons]
			texture:SetVertexColor(RAID_CLASS_COLORS[data.class].r, RAID_CLASS_COLORS[data.class].g, RAID_CLASS_COLORS[data.class].b)
			texture:Show()
		end
	end
	
	-- Update icon size
	for id in pairs(usedRows) do
		self:UpdateToTTextures(self.rows[id], self.rows[id].usedIcons)
	end
end

-- Updates all the health info!
function SSAF:UpdateHealth(enemy, unit, maxHealth)
	-- We have a unitid provided, so update based off that
	if( unit and not maxHealth ) then
		enemy.maxHealth = UnitHealthMax(unit) or enemy.maxHealth
		enemy.health = UnitHealth(unit) or enemy.health
	
	-- We're specifically updating off set health/maxHealth values
	elseif( unit and maxHealth ) then
		enemy.maxHealth = maxHealth or enemy.maxHealth
		enemy.health = unit or enemy.health
	end
	
	-- Just incase
	if( unit and enemy.health > enemy.maxHealth ) then
		enemy.maxHealth = enemy.health
	end

	if( not enemy.displayRow ) then
		return
	end
	
	local row = self.rows[enemy.displayRow]
	

	-- Fade out the bar if they're dead
	if( enemy.isDead ) then
		row:SetAlpha(0.75)
	else
		row:SetAlpha(1.0)
	end
	
	-- Update value/percent text
	row:SetMinMaxValues(0, enemy.maxHealth)
	row:SetValue(enemy.health)
	row.healthText:SetText(math.floor((enemy.health / enemy.maxHealth) * 100 + 0.5) .. "%")
end

function SSAF:UpdateMana(enemy, unit)
	-- unitid provided, meaning we can actually update it
	if( unit ) then
		enemy.mana = UnitMana(unit)
		enemy.maxMana = UnitManaMax(unit)
		enemy.powerType = UnitPowerType(unit)
		
		if( enemy.classToken == "SHAMAN" ) then
			enemy.powerType = 3
		end
	end
	
	if( not enemy.displayRow ) then
		return
	end

	local row = self.rows[enemy.displayRow]
	row.manaBar:SetStatusBarColor(ManaBarColor[enemy.powerType].r, ManaBarColor[enemy.powerType].g, ManaBarColor[enemy.powerType].b)
	row.manaBar:SetMinMaxValues(0, enemy.maxMana)
	row.manaBar:SetValue(enemy.mana)
end

-- Health update, check if it's one of our guys
function SSAF:UNIT_HEALTH(event, unit)
	if( unit == "focus" or unit == "target" ) then
		local name = UnitName(unit)
		local isPlayer = UnitIsPlayer(unit)
		
		if( enemies[name] and isPlayer ) then
			self:UpdateHealth(enemies[name], unit)
		elseif( enemyPets[name] and not isPlayer ) then
			self:UpdateHealth(enemyPets[name], unit)
		end
	end
end

-- Update a power
function SSAF:UPDATE_POWER(event, unit)
	if( unit == "focus" or unit == "target" ) then
		local name = UnitName(unit)
		local isPlayer = UnitIsPlayer(unit)
		
		if( enemies[name] and isPlayer ) then
			self:UpdateMana(enemies[name], unit)
		elseif( enemyPets[name] and not isPlayer ) then
			self:UpdateMana(enemyPets[name], unit)
		end
	end
end

-- Load talents from one of the player talent types of mods
function SSAF:GetTalents(name, server)
	if( IsAddOnLoaded("Remembrance") ) then
		local tree1, tree2, tree3 = Remembrance:GetTalents(name, server)
		if( tree1 and tree2 and tree3 ) then
			return tree1 .. "/" .. tree2 .. "/" .. tree3
		end
	elseif( IsAddOnLoaded("Tattle") ) then
		local data = Tattle:GetPlayerData(name, server)
		if( data ) then
			return data.tree1 .. "/" .. data.tree2 .. "/" .. data.tree3
		end
	end
	
	return nil
end

-- Update displayed talents even if we're in combat
function SSAF:UpdateTalentDisplay()
	for _, row in pairs(self.rows) do
		if( row.ownerType == "PLAYER" and row.talents == "") then
			local enemy = enemies[row.ownerName]
			if( enemy ) then
				if( not enemy.talents and enemy.name and enemy.server ) then
					enemy.talents = SSAF:GetTalents(enemy.name, enemy.server)
				end

				if( enemy.talents and enemy.talents ~= "" ) then
					row.talents = "[" .. enemy.talents .. "] "
				end

				row.text:SetText(row.talents .. row.nameID .. enemy.name)
			end
 		end
	end
end

-- Health value updated, rescan our saved enemies
local function healthValueChanged(...)
	if( this.SSAFValueChanged ) then
		this.SSAFValueChanged(...)
	end

	if( not instanceType ) then
		return
	end
	
	local name = select(5, this:GetParent():GetRegions()):GetText()	
	

	-- The "isCorrupted" flag is a way of letting us know to disregard any health updates from them
	-- due to Hunters naming the pet the same as someone on the friendly team
	if( enemies[name] and enemies[name].isCorrupted ) then
		return
	end
	
	if( enemies[name] ) then
		SSAF:UpdateHealth(enemies[name], this:GetValue(), select(2, this:GetMinMaxValues()))
	else
		for _, enemy in pairs(enemyPets) do
			if( enemy.name == name ) then
				SSAF:UpdateHealth(enemy, this:GetValue(), select(2, this:GetMinMaxValues()))
				break
			end
		end
	end
end

-- Find unhooked anonymous frames
local function findUnhookedNameplates(...)
	for i=1, select("#", ...) do
		local health = select(i, ...)
		if( health and not health.SSAFHooked and not health:GetName() and health:IsVisible() and health.GetFrameType and health:GetFrameType() == "StatusBar" ) then
			return health
		end
	end
end

-- Scan WorldFrame children
local function scanFrames(...)
	for i=1, select("#", ...) do
		local health = findUnhookedNameplates(select(i, ...):GetChildren())
		if( health ) then
			health.SSAFHooked = true
			health.SSAFValueChanged = health:GetScript("OnValueChanged")
			health:SetScript("OnValueChanged", healthValueChanged)
		end
	end
end

-- Sort the enemies by the sortID thing
local function sortEnemies(a, b)
	if( not b ) then
		return false
	end
	
	return ( a.sortID < b.sortID )
end

-- Update the entire frame and everything in it
function SSAF:UpdateEnemies()
	-- Can't update in combat, so queue it for when we drop
	if( InCombatLockdown() ) then
		self:RegisterOOCUpdate("UpdateEnemies")
		return
	end
	
	-- Hide all rows
	for i=1, CREATED_ROWS do
		self.rows[i]:Hide()
	end
	
	-- The reason we recycle a table here instead of our old method of using an indexed table
	-- followed by a hash table to reference to the indexed one
	-- is mostly because it was a crazy ass idea done at 2 AM
	-- if we call this, we're out of combat and it's only called teamSize times per a match
	-- so the performance loss isn't that big and lets us do saner code while in combat which is where it matters more
	
	-- Clear out our display table
	for i=#(displayRows), 1, -1 do
		table.remove(displayRows, i)
	end
	
	-- Now add stuff into it
	for _, enemy in pairs(enemies) do
		table.insert(displayRows, enemy)
	end
	
	-- Sort
	table.sort(displayRows, sortEnemies)
	
	local id = 0

	-- Update enemy players
	for _, enemy in pairs(displayRows) do
		id = id + 1
		
		local row = self.rows[id]
		if( not row ) then
			row = self:CreateRow()
		end

		row:Show()
		
		-- So we can update the row quickly from health/mana
		enemy.displayRow = id
				
		-- Show talents
		row.talents = ""
		if( self.db.profile.showTalents ) then
			-- Grab their talents if we don't have it
			if( not enemy.talents and enemy.name and enemy.server ) then
				enemy.talents = SSAF:GetTalents(enemy.name, enemy.server)
			end
			
			-- Display talents
			if( enemy.talents and enemy.talents ~= "" ) then
				row.talents = "[" .. enemy.talents .. "] "
			end
		end
		
		-- ID to make it easier to call out
		if( self.db.profile.showID ) then
			row.nameID = "#" .. id .. " "
		else
			row.nameID = ""
		end
			
		row.text:SetText(row.talents .. row.nameID .. enemy.name)
		row.ownerName = enemy.name
		row.ownerType = "PLAYER"
				
		-- Show class icon to the left of the players name
		if( self.db.profile.showIcon ) then
			local coords = CLASS_BUTTONS[enemy.classToken]

			row.classTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			row.classTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			row.classTexture:Show()
		else
			row.classTexture:Hide()
		end
		
		-- Color the health bar by class
		row:SetStatusBarColor(RAID_CLASS_COLORS[enemy.classToken].r, RAID_CLASS_COLORS[enemy.classToken].g, RAID_CLASS_COLORS[enemy.classToken].b, 1.0)
		
		-- Now do a quick basic update of other info
		self:UpdateHealth(enemy)
		self:UpdateMana(enemy)

		-- Set up all the macro things
		local foundMacro
		for _, macro in pairs(self.db.profile.attributes) do
			if( macro.modifier and macro.button ) then
				if( macro.enabled and ( macro.classes.ALL or macro.classes[enemy.type] ) ) then
					row.button:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
					row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", enemy.name))
					foundMacro = true
				else
					row.button:SetAttribute(macro.modifier .. "type" .. macro.button, nil)
					row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, nil)
				end
			end
		end

		-- Make sure we always have at least one macro to target
		if( not foundMacro ) then
			row.button:SetAttribute("type", "macro")
			row.button:SetAttribute("macrotext", "/targetexact " .. enemy.name)
		end
	end
	
	-- Clear out our display table again
	for i=#(displayRows), 1, -1 do
		table.remove(displayRows, i)
	end
	
	-- Now add stuff into it
	for _, enemy in pairs(enemyPets) do
		table.insert(displayRows, enemy)
	end
	
	-- Sort
	table.sort(displayRows, sortEnemies)
	
	-- Update enemy pets
	for _, enemy in pairs(displayRows) do
		if( ( enemy.type == "MINION" and self.db.profile.showMinions ) or ( enemy.type == "PET" and self.db.profile.showPets ) ) then
			id = id + 1

			local row = self.rows[id]
			if( not row ) then
				row = self:CreateRow()
			end
			row:Show()

			-- So we can update the row quickly from health/mana
			enemy.displayRow = id

			-- ID to make it easier to call out
			if( self.db.profile.showID ) then
				row.nameID = "#" .. id .. " "
			else
				row.nameID = ""
			end

			-- Show it as "<owner>'s <pet family> or <pet name> if no family"
			row.text:SetFormattedText("%s%s's %s", row.nameID, enemy.owner, enemy.family or enemy.name)
			row.ownerName = enemy.name
			row.ownerType = enemy.type

			row:SetMinMaxValues(0, enemy.maxHealth)
			
			-- Color health bar based on type
			if( enemy.type == "PET" ) then
				row:SetStatusBarColor(self.db.profile.petBarColor.r, self.db.profile.petBarColor.g, self.db.profile.petBarColor.b, 1.0)
			elseif( enemy.type == "MINION" ) then
				row:SetStatusBarColor(self.db.profile.minionBarColor.r, self.db.profile.minionBarColor.g, self.db.profile.minionBarColor.b, 1.0)
			end

			-- Quick update
			self:UpdateHealth(enemy)
			self:UpdateMana(enemy)

			-- Show pet icon like we show class icons
			if( self.db.profile.showIcon ) then
				local path = petClassIcons[enemy.family or enemy.name]
				if( path ) then
					row.classTexture:SetTexture(path)
				else
					row.classTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
					row.classTexture:SetTexCoord(0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0)
				end

				row.classTexture:Show()
			else
				row.classTexture:Hide()
			end
			
			-- Set up all the macro things
			local foundMacro
			for _, macro in pairs(self.db.profile.attributes) do
				if( macro.modifier and macro.button ) then
					if( macro.enabled and ( macro.classes.ALL or macro.classes[enemy.type] ) ) then
						row.button:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
						row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", enemy.name))
						foundMacro = true
					else
						row.button:SetAttribute(macro.modifier .. "type" .. macro.button, nil)
						row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, nil)
					end
				end
			end
			
			-- Make sure we always have at least one macro to target
			if( not foundMacro ) then
				row.button:SetAttribute("type", "macro")
				row.button:SetAttribute("macrotext", "/targetexact " .. enemy.name)
			end
		end
	end
	
	-- Nothing displayed, hide frame
	if( id == 0 ) then
		if( self.frame ) then
			self.frame:Hide()
		end
		return
	end
		
	-- Resize it
	self.frame:SetHeight(18 * id)
	self.frame:Show()

	-- Update all of the ToT info whenever we update everything
	-- incase it's done AFTER the person targets
	self:UpdateToT()
end

-- Quick redirects!
function SSAF:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function SSAF:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function SSAF:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

-- Scan unit, see if they're valid as an enemy or enemy pet
function SSAF:ScanUnit(unit)
	-- 1) Roll a healer with the name Unknown
	-- 2) Join an arena team
	-- 3) ????
	-- 4) Profit! Because all arena mods check for the name "Unknown" before exiting
	local name, server = UnitName(unit)
	if( name == UNKNOWNOBJECT or not UnitIsEnemy("player", unit) or GetPlayerBuffTexture(L["Arena Preparation"]) ) then
		return
	end
	
	-- Check if we should update their health/mana/ect info
	if( enemies[name] ) then
		self:UpdateMana(enemies[name], unit)
		self:UpdateHealth(enemies[name], unit)	
	elseif( enemyPets[name] ) then
		self:UpdateMana(enemyPets[name], unit)
		self:UpdateHealth(enemyPets[name], unit)
	end
	
	-- Check for a new player
	if( UnitIsPlayer(unit) ) then
		server = server or GetRealmName()
		
		if( enemies[name] ) then
			-- Already found them, AND server is provided
			if( enemies[name].server ) then
				return
			end
			
			-- All the current arena mods do not provide server meaning we have to add it ourself
			-- in order to do talent lookups
			enemies[name].sortID = name .. "-" .. server
			enemies[name].server = server
		end
		
		local race = UnitRace(unit)
		local class, classToken = UnitClass(unit)
		local guild = GetGuildInfo(unit)
		local talents = SSAF:GetTalents(name, server)
		
		self:AddEnemy(name, server, race, classToken, guild, UnitPowerType(unit), talents, unit)
		self:SendMessage("ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken .. "," .. (guild or "") .. "," .. UnitPowerType(unit) .. "," .. (talents or ""))

		if( self.db.profile.reportEnemies ) then
			if( talents and talents ~= "" ) then
				talents = "[" .. talents .. "] "
			else
				talents = ""
			end
			
			if( guild ) then
				self:ChannelMessage(string.format("%s%s / %s / %s / %s / %s", talents, name, server, race, class, guild))
			else
				self:ChannelMessage(string.format("%s%s / %s / %s / %s", talents, name, server, race, class))
			end
		end

	-- Hunter pet, or Warlock/Mage minion
	elseif( UnitCreatureFamily(unit) or name == L["Water Elemental"] ) then
		-- Need to find the pets owner
		if( not self.tooltip ) then
			self.tooltip = CreateFrame("GameTooltip", "SSArenaTooltip", UIParent, "GameTooltipTemplate")
			self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		end
		
		self.tooltip:SetUnit(unit)
		if( self.tooltip:NumLines() == 0 ) then
			return
		end
		
		-- Warlock/Mage
		local owner = string.match(SSArenaTooltipTextLeft2:GetText(), L["([a-zA-Z]+)%'s Minion"])
		local type = "MINION"
		
		-- Hunters
		if( not owner ) then
			owner = string.match(SSArenaTooltipTextLeft2:GetText(), L["([a-zA-Z]+)%'s Pet"])
			type = "PET"
		end
				
		-- Found the pet owner
		if( owner and owner ~= UNKNOWNOBJECT ) then
			local family = UnitCreatureFamily(unit)
			
			for id, enemy in pairs(enemyPets) do
				if( enemy.owner == owner ) then
					-- New pet summoned, remove the old
					if( enemy.name ~= name ) then
						enemyPets[id] = nil
						break
					else
						return
					end
				end
			end
					
			self:AddEnemyPet(name, owner, family, type, UnitPowerType(unit), unit)
			self:SendMessage("ENEMYPET:" .. name .. "," .. owner .. "," .. (family or "") .. "," .. type .. "," .. UnitPowerType(unit))

			if( self.db.profile.reportEnemies ) then
				if( family ) then
					self:ChannelMessage(string.format(L["%s's pet, %s %s"], owner, name, family))
				else
					self:ChannelMessage(string.format(L["%s's pet, %s"], owner, name))
				end
			end
		end
	end
end

-- Syncing
function SSAF:AddEnemy(name, server, race, classToken, guild, powerType, talents, unit)
	-- Prevent bad syncs from adding people in our group
	if( enemies[name] or UnitInParty(name) or UnitInRaid(name) ) then
		return
	end
	
	local health, mana, maxHealth, maxMana
	if( unit ) then
		health = UnitHealth(unit)
		mana = UnitMana(unit)
		
		maxHealth = UnitHealthMax(unit)
		maxMana = UnitManaMax(unit)
	end

	-- Use Rogue energy indicator so you can actually see mana
	if( classToken == "SHAMAN" ) then
		powerType = 3
	end
		
	enemies[name] = {sortID = name .. "-" .. (server or ""),
			name = name,
			type = "PLAYER",
			server = server,
			race = race,
			classToken = classToken,
			guild = guild,
			talents = talents,
			health = health or 100,
			maxHealth = maxHealth or 100,
			mana = mana or 0,
			maxMana = maxMana or 100,
			powerType = tonumber(powerType) or 0}
	
	-- Check if a pet has the same as this player
	if( enemyPets[name] ) then
		enemies[name].isCorrupted = true
	end

	self:UpdateEnemies()
	return true
end

-- New pet found
function SSAF:AddEnemyPet(name, owner, family, type, powerType, unit)
	-- Old SSAF sync
	if( not type ) then
		return nil
	end

	-- When a unit is passed, we verified it ourselve
	if( not unit ) then
		-- Check for dup
		for id, enemy in pairs(enemyPets) do
			if( enemy.owner == owner ) then
				-- New pet summoned, remove the old
				if( enemy.name ~= name ) then
					enemyPets[id] = nil
					break
				else
					return
				end
			end
		end
	end
	
	local health, mana, maxHealth, maxMana
	if( unit ) then
		health = UnitHealth(unit)
		maxHealth = UnitHealthMax(unit)
		
		mana = UnitMana(unit)
		maxMana = UnitManaMax(unit)
	end
	
	-- Check if the pet has the same name as a player
	if( enemies[name] ) then
		enemies[name].isCorrupted = true
	end
	
	enemyPets[name] = {	sortID = name .. "-" .. owner,
				name = name,
				owner = owner,
				type = type,
				family = family,
				health = health or 100,
				maxHealth = maxHealth or 100,
				mana = mana or 0,
				maxMana = maxMana or 100,
				powerType = tonumber(powerType) or 2}
				
	self:UpdateEnemies()
	return true
end

-- Someone died, update them to actually be dead
function SSAF:EnemyDied(name)
	if( enemies[name] ) then
		local enemy = enemies[name]
		if( not enemy.isDead ) then
			enemy.isDead = true
			enemy.health = 0
			enemy.mana = 0

			self:UpdateHealth(enemy)
		end
	
	elseif( enemyPets[name] ) then
		local enemy = enemyPets[name]
		if( not enemy.isDead ) then
			enemy.isDead = true
			enemy.health = 0
			enemy.mana = 0
			
			self:UpdateHealth(enemy)
		end
	end
end


-- Create the master frame to hold everything
local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.6,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}
function SSAF:CreateFrame()
	if( self.frame ) then
		return
	end
	
	self.frame = CreateFrame("Frame")
	self.frame:SetBackdrop(backdrop)
	self.frame:SetBackdropColor(0, 0, 0, 1.0)
	self.frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.frame:SetScale(self.db.profile.scale)
	self.frame:SetWidth(180)
	self.frame:SetHeight(18)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(false)
	self.frame:SetClampedToScreen(true)
	self.frame:Hide()

	-- Create our anchor for moving the frame
	self.anchor = CreateFrame("Frame")
	self.anchor:SetWidth(180)
	self.anchor:SetHeight(12)
	self.anchor:SetBackdrop(backdrop)
	self.anchor:SetBackdropColor(0, 0, 0, 1.0)
	self.anchor:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.anchor:SetClampedToScreen(true)
	self.anchor:SetScale(self.db.profile.scale)
	self.anchor:EnableMouse(true)
	self.anchor:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 14)
	self.anchor:SetScript("OnMouseDown", function(self)
		if( not SSAF.db.profile.locked and IsAltKeyDown() ) then
			self.isMoving = true
			SSAF.frame:StartMoving()
		end
	end)

	self.anchor:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			SSAF.frame:StopMovingOrSizing()

			SSAF.db.profile.position.x = SSAF.frame:GetLeft()
			SSAF.db.profile.position.y = SSAF.frame:GetTop()
		end
	end)	
	
	self.anchor.text = self.anchor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.anchor.text:SetText(L["SSArena Frames"])
	self.anchor.text:SetPoint("CENTER", self.anchor, "CENTER")
	
	-- Hide anchor if locked
	if( self.db.profile.locked ) then
		self.anchor:Hide()
	end
	
	-- Health monitoring
	local timeElapsed = 0
	local numChildren = -1
	self.frame:SetScript("OnUpdate", function(self, elapsed)
		-- When number of children changes, 99% of the time it's
		-- due to a new nameplate being added
		if( WorldFrame:GetNumChildren() ~= numChildren ) then
			numChildren = WorldFrame:GetNumChildren()
			scanFrames(WorldFrame:GetChildren())
		end
		
		-- Scan party targets every 0.25 second
		-- Really, nameplate scanning should get the info 99% of the time
		-- so we don't need to be so aggressive with this
		timeElapsed = timeElapsed + elapsed
		if( timeElapsed >= 0.25 ) then
			for i=1, GetNumPartyMembers() do
				local unit = "party" .. i .. "target"
				local name = UnitName(unit)
				local isPlayer = UnitIsPlayer(unit)
				
				-- Target monitoring
				if( partyTargets[unit].name ~= name or partyTargets[unit].isPlayer ~= isPlayer ) then
					partyTargets[unit].name = name
					partyTargets[unit].isPlayer = isPlayer
					partyTargets[unit].class = select(2, UnitClass("party" .. i))
										
					SSAF:UpdateToT()
				end
				
				-- Health/mana
				if( UnitExists(unit) ) then
					if( enemies[name] and isPlayer ) then
						SSAF:UpdateHealth(enemies[name], unit)
						SSAF:UpdateMana(enemies[name], unit)
					elseif( enemyPets[name] and not isPlayer ) then
						SSAF:UpdateHealth(enemyPets[name], unit)
						SSAF:UpdateMana(enemyPets[name], unit)
					end
				end
			end
		end
	end)
	
	-- Position to last saved area
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)
end

-- Create a single row
function SSAF:CreateRow()
	if( not self.frame ) then
		self:CreateFrame()
	end
	
	CREATED_ROWS = CREATED_ROWS + 1
	local id = CREATED_ROWS
	
	-- Health bar
	local row = CreateFrame("StatusBar", nil, self.frame)
	row:SetHeight(16)
	row:SetWidth(178)
	row:SetStatusBarTexture(self.db.profile.barTexture)
	row:Hide()
	
	-- Mana bar
	local mana = CreateFrame("StatusBar", nil, row)
	mana:SetWidth(178)
	mana:SetHeight(self.db.profile.manaBarHeight)
	mana:SetStatusBarTexture(self.db.profile.barTexture)
	mana:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
	
	if( not self.db.profile.manaBar ) then
		mana:Hide()
	end

	local path, size = GameFontNormalSmall:GetFont()

	-- Player name text
	local text = mana:CreateFontString(nil, "OVERLAY")
	text:SetPoint("LEFT", row, "LEFT", 1, 0)
	text:SetJustifyH("LEFT")
	
	text:SetFont(path, size)
	text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	
	text:SetShadowOffset(1, -1)
	text:SetShadowColor(0, 0, 0, 1)
	

	-- We have to do this for GetStringHeight()
	text:SetText("*")
	text:SetWidth(145)
	text:SetHeight(text:GetStringHeight())
	
	-- Health percent text
	local healthText = mana:CreateFontString(nil, "OVERLAY")
	healthText:SetPoint("RIGHT", row, "RIGHT", -1, 0)
	healthText:SetJustifyH("RIGHT")
	
	healthText:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	healthText:SetFont(path, size)
	
	healthText:SetShadowOffset(1, -1)
	healthText:SetShadowColor(0, 0, 0, 1)
	
	-- Reparent text so they'll show if mana bars are disabled
	if( not self.db.profile.manaBar ) then
		text:SetParent(row)
		healthText:SetParent(row)
	end

	-- Class icon
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(16)
	texture:SetWidth(16)
	texture:SetPoint("CENTER", row, "LEFT", -12, 0)
	
	-- So we can actually run macro text
	local button = CreateFrame("Button", "SSArenaButton" .. id, row, "SecureActionButtonTemplate")
	button:SetHeight(16)
	button:SetWidth(179)
	button:SetPoint("LEFT", row, "LEFT", 1, 0)
	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp", "Button4Up", "Button5Up")
	
	-- Position
	if( id > 1 ) then
		row:SetPoint("TOPLEFT", self.rows[id - 1], "BOTTOMLEFT", 0, -2)
	else
		row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
	end

	self.rows[id] = row
	self.rows[id].targets = {}
	self.rows[id].text = text
	self.rows[id].manaBar = mana
	self.rows[id].classTexture = texture
	self.rows[id].button = button
	self.rows[id].healthText = healthText
	
	-- Add the "whos targeting us" buttons
	-- Top left
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 4)
	texture:SetTexture(self.db.profile.barTexture)
	texture:Hide()
	
	self.rows[id].targets[1] = texture

	-- Top right
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, 4)
	texture:SetTexture(self.db.profile.barTexture)
	texture:Hide()

	self.rows[id].targets[4] = texture

	-- Bottom left
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, -4)
	texture:SetTexture(self.db.profile.barTexture)
	texture:Hide()
	
	self.rows[id].targets[2] = texture

	-- Bottom right
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, -4)
	texture:SetTexture(self.db.profile.barTexture)
	texture:Hide()
	
	self.rows[id].targets[3] = texture
	
	-- Add key bindings
	local bindKey = GetBindingKey("ARENATAR" .. id)

	if( bindKey ) then
		SetOverrideBindingClick(self.rows[id].button, false, bindKey, self.rows[id].button:GetName())	
	else
		ClearOverrideBindings(self.rows[id].button)
	end
	
	return self.rows[id]
end

-- Are we inside an arena?
function SSAF:ZONE_CHANGED_NEW_AREA()
	local type = select(2, IsInInstance())
	-- Inside an arena, but wasn't already
	if( type == "arena" and type ~= instanceType ) then
		self:JoinedArena()

	-- Was in an arena, but left it
	elseif( type ~= "arena" and instanceType == "arena" ) then
		self:LeftArena()
	end
	
	instanceType = type
end

function SSAF:ChannelMessage(msg)
	SendChatMessage(msg, "BATTLEGROUND")
end

function SSAF:SendMessage(msg, type)
	SendAddonMessage("SSAF", msg, "BATTLEGROUND")
end

-- Update queued frames
function SSAF:PLAYER_REGEN_ENABLED()
	for func in pairs(queuedUpdates) do
		self[func](self)
		queuedUpdates[func] = nil
	end
end

-- So we can update secure things once we're OOC
function SSAF:UnregisterOOCUpdate(func)
	queuedUpdates[func] = nil
end

function SSAF:RegisterOOCUpdate(func)
	queuedUpdates[func] = true
end

-- Something in configuration changed
function SSAF:Reload()
	if( not self.db.profile.locked ) then
		local noEnemies = true
		for _ in pairs(enemies) do
			noEnemies = nil
		end
		for _ in pairs(enemyPets) do
			noEnemies = nil
		end
		
		if( noEnemies ) then
			self:AddEnemy(UnitName("player"), GetRealmName(), (UnitRace("player")), select(2, UnitClass("player")), nil, UnitPowerType("player"), nil, "player")
			self:AddEnemy("Mayen", "Icecrown", "TAUREN", "DRUID", nil, 0, nil, "player")
			self:AddEnemyPet(L["Pet"], UnitName("player"), "Cat", "PET", 2)
			self:AddEnemyPet(L["Minion"], "Mayen", "Felhunter", "MINION", 0)
		end
	else
		self:ClearEnemies()
	end
	
	if( self.frame ) then
		self.frame:SetScale(self.db.profile.scale)
		self.anchor:SetScale(self.db.profile.scale)

		-- Change anchor visability
		if( self.db.profile.locked ) then
			self.anchor:Hide()
		else
			self.anchor:Show()
		end
	end
		
	-- Update all the rows to the current settings
	for i=1, CREATED_ROWS do
		-- Texture/mana bar height
		local row = self.rows[i]
		row:SetStatusBarTexture(self.db.profile.barTexture)
		row.manaBar:SetStatusBarTexture(self.db.profile.barTexture)
		row.manaBar:SetHeight(self.db.profile.manaBarHeight)
		
		-- Mana Bar
		if( self.db.profile.manaBar ) then
			row.text:SetParent(row.manaBar)
			row.healthText:SetParent(row.manaBar)
			row.manaBar:Show()
		else
			row.text:SetParent(row)
			row.healthText:SetParent(row)
			row.manaBar:Hide()
		end
		
		-- Update ToT textures
		for _, texture in pairs(row.targets) do
			texture:SetTexture(self.db.profile.barTexture)
			
			if( not self.db.profile.targetDots ) then
				texture:Hide()
			end
		end
	
		-- Update text color
		row.text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
		row.healthText:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	end
		
	-- Update it if we're already showing something
	if( self.rows[1] and self.rows[1]:IsVisible() ) then
		self:UpdateEnemies()
	end
end

-- Recycle tables/left arena
function SSAF:ClearEnemies()
	for k in pairs(enemies) do
		enemies[k] = nil

	end

	for k in pairs(enemyPets) do
		enemyPets[k] = nil
	end
	
	for _, data in pairs(partyTargets) do
		for k, v in pairs(data) do
			data[k] = nil
		end
	end
	
	if( self.rows ) then
		for i=1, CREATED_ROWS do
			self.rows[i].ownerName = nil
			self.rows[i].ownerType = nil
			self.rows[i]:Hide()
		end
	end
	
	if( self.frame ) then
		self.frame:Hide()
	end
end