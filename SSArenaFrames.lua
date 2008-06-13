--[[ 
	SSArena Frames By Amarand (Horde) / Mayen (Horde) from Icecrown (US) PvE
]]

SSAF = LibStub("AceAddon-3.0"):NewAddon("SSAF", "AceEvent-3.0")

local L = SSAFLocals

local enemies = {}
local nameGUIDMap = {}
local partyTargets, partyUnit, partyTargetUnit, usedRows, tempNames = {}, {}, {}, {}
local instanceType

-- Map of pet type to icon
local petClassIcons = {
	["Voidwalker"] = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker", ["Felhunter"] = "Interface\\Icons\\Spell_Shadow_SummonFelHunter", ["Felguard"] = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
	["Succubus"] = "Interface\\Icons\\Spell_Shadow_SummonSuccubus", ["Imp"] = "Interface\\Icons\\Spell_Shadow_SummonImp", ["Cat"] = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
	["Bat"] = "Interface\\Icons\\Ability_Hunter_Pet_Bat", ["Bear"] = "Interface\\Icons\\Ability_Hunter_Pet_Bear", ["Boar"] = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
	["Crab"] = "Interface\\Icons\\Ability_Hunter_Pet_Crab", ["Crocolisk"] = "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk", ["Dragonhawk"] = "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk",
	["Gorilla"] = "Interface\\Icons\\Ability_Hunter_Pet_Gorilla", ["Hyena"] = "Interface\\Icons\\Ability_Hunter_Pet_Hyena", ["Netherray"] = "Interface\\Icons\\Ability_Hunter_Pet_NetherRay",
	["Owl"] = "Interface\\Icons\\Ability_Hunter_Pet_Owl", ["Raptor"] = "Interface\\Icons\\Ability_Hunter_Pet_Raptor", ["Ravager"] = "Interface\\Icons\\Ability_Hunter_Pet_Ravager",
	["Scorpid"] = "Interface\\Icons\\Ability_Hunter_Pet_Scorpid", ["Spider"] = "Interface\\Icons\\Ability_Hunter_Pet_Spider", ["Sporebat"] = "Interface\\Icons\\Ability_Hunter_Pet_Sporebat",
	["Tallstrider"] = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider", ["Turtle"] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle", ["Vulture"] = "Interface\\Icons\\Ability_Hunter_Pet_Vulture",
	["Warp Stalker"] = "Interface\\Icons\\Ability_Hunter_Pet_WarpStalker", ["Windserpent"] = "Interface\\Icons\\Ability_Hunter_Pet_WindSerpent", ["Wolf"] = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
	[L["Water Elemental"]] = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2",
}

function SSAF:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			locked = true,
			targetDots = true,
			reportEnemies = true,
			barTexture = "Minimalist",
			showID = false,
			showIcon = false,
			showMinions = true,
			showPets = false,
			showGuess = true,
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
				{ enabled = true, classes = { ["ALL"] = true }, modifier = "", button = "2", text = "/targetexact *name\n/focus\n/targetlasttarget\n/script SSAF:Print(string.format(\"Set focus %s\", UnitName(\"focus\") or \"<no focus>\"));" },
			}
		}
	}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SSAFDB", self.defaults)
	
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BINDINGS")
	
	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	
	self.talents = LibStub:GetLibrary("TalentGuess-1.0"):Register()
	self.talents:RegisterCallback(self, "OnTalentData")
	
	self.rows = setmetatable({}, {__index = function(t, k)
		local row = SSAF.modules.Frame:CreateRow(k)
		rawset(t, k, row)
		
		return row
	end})
	
	-- Default party units
	for i=1, MAX_PARTY_MEMBERS do
		partyUnit[i] = "party" .. i
		partyTargets["party" .. i .. "target"] = {guid = "", class = ""}
		partyTargetUnit[i] = "party" .. i .. "target"
	end
	
	self.partyTargets = partyTargets
	self.nameGUIDMap = nameGUIDMap
	self.enemies = enemies
	self.partyTargetUnit = partyTargetUnit
	self.partyUnit = partyUnit
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
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	-- Enable modules
	self.modules.Sync:EnableModule()
	self.modules.NP:EnableModule()

	-- Enable talent guessing
	if( self.db.profile.showGuess ) then
		self.talents:EnableCollection()
	end
end

function SSAF:LeftArena()
	self:UnregisterAllEvents()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BINDINGS")

	-- Reset map
	for k in pairs(nameGUIDMap) do nameGUIDMap[k] = nil end
	
	-- Disable modules
	self.modules.Sync:DisableModule()
	self.modules.NP:DisableModule()
	
	-- Disable guessing
	self.talents:DisableCollection()

	if( not InCombatLockdown() ) then
		self:ClearEnemies()
	else
		instanceType = "none"
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end

-- HEALTH UPDATES
function SSAF:UNIT_HEALTH(event, unit)
	if( unit == "focus" or unit == "target" or unit == "mouseover" ) then
		local guid = UnitGUID(unit)
		if( enemies[guid] ) then
			self:UpdateHealth(enemies[guid], unit)
		end
	end
end

-- POWER TYPE
function SSAF:UPDATE_POWER(event, unit)
	if( unit == "focus" or unit == "target" or unit == "mouseover" ) then
		local guid = UnitGUID(unit)
		if( enemies[guid] ) then
			self:UpdateMana(enemies[guid], unit)
		end
	end
end

-- ENEMY DEATH
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
function SSAF:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags)
	-- Slain will always be accurate, and we sync it just to be safe
	if( eventType == "PARTY_KILL" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		self:EnemyDied(destGUID)
		self:SendMessage("ENEMYDIED:" .. destGUID)
	
	-- Don't accept UNIT_DIED except for elementals, because Hunters can throw things off
	elseif( eventType == "UNIT_DIED" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE and destName == L["Water Elemental"] ) then
		self:EnemyDied(destGUID)
		self:SendMessage("ENEMYDIED:" .. destGUID)
	end
end

-- TARGET OF TARGET
function SSAF:UpdateToT()
	if( not self.db.profile.targetDots ) then
		return
	end
	
	for id, row in pairs(self.rows) do
		if( row.guid ) then
			local enemy = enemies[row.guid]
			
			-- Reset
			for i=1, 4 do
				row.targets[i]:Hide()
			end
			
			-- Set the actual textures + set how many icons are being used
			row.usedIcons = 0
			for unit, data in pairs(partyTargets) do
				if( data.guid == row.guid ) then
					row.usedIcons = row.usedIcons + 1

					local texture = row.targets[row.usedIcons]
					texture:SetVertexColor(RAID_CLASS_COLORS[data.class].r, RAID_CLASS_COLORS[data.class].g, RAID_CLASS_COLORS[data.class].b)
					texture:Show()
				end
			end
			
			-- Update positioning
			self.modules.Frame:UpdateToTTextures(row, row.usedIcons)
		end
	end
end

-- HEALTH UPDATES
function SSAF:UpdateHealth(enemy, unit)
	if( UnitExists(unit) and UnitCanAttack("player", unit) ) then
		enemy.health = UnitHealth(unit)
	end
end

-- MANA UPDATES
function SSAF:UpdateMana(enemy, unit)
	if( UnitExists(unit) and UnitCanAttack("player", unit) ) then
		local maxMana = UnitManaMax(unit)
		local mana = UnitMana(unit)
		
		enemy.mana = math.floor((mana / maxMana) * 100 + 0.5)
		enemy.powerType = UnitPowerType(unit)
	end
end

-- UPDATE ENEMY DISPLAY
local function sortEnemies(a, b)
	if( not a ) then
		return true
	elseif( not b ) then
		return false
	end
	
	return ( a.listID < b.listID )
end

function SSAF:UpdateAFData()
	for id, row in pairs(self.rows) do
		if( row:IsVisible() and row.guid and enemies[row.guid] ) then
			local enemy = enemies[row.guid]
			
			-- Update health
			row.healthText:SetFormattedText("%d%%", enemy.health)
			row:SetValue(enemy.health)
			row:SetAlpha(1.0)

			-- Update mana
			row.manaBar:SetValue(enemy.mana)
			row.manaBar:SetStatusBarColor(ManaBarColor[enemy.powerType].r, ManaBarColor[enemy.powerType].g, ManaBarColor[enemy.powerType].b)

			-- Fade out the bar if they're dead
			if( enemy.isDead ) then
				row.healthText:SetText("0%")
				row.manaBar:SetValue(0)
				row:SetValue(0)
				row:SetAlpha(0.70)
			end
		end
	end
	
	self:UpdateToT()
end

-- New talent data found, do a quick update of everyones talents
function SSAF:OnTalentData()
	if( not self.db.profile.showGuess ) then
		return
	end
	
	for id, row in pairs(self.rows) do
		if( row.guid and row.ownerType == "PLAYER" ) then
			local enemy = enemies[row.guid]			
			if( enemy ) then
				row.talentGuess = ""
				local firstPoints, secondPoints, thirdPoints = self.talents:GetTalents(enemy.fullName)
				if( firstPoints and secondPoints and thirdPoints ) then
					row.talentGuess = string.format("[%d/%d/%d] ", firstPoints, secondPoints, thirdPoints)
				end
				row.text:SetFormattedText("%s%s%s", row.nameID, row.talentGuess, enemy.name)
			end
		end
	end
end

function SSAF:UpdateEnemies()
	-- Can't update in combat, so queue it for when we drop
	if( InCombatLockdown() ) then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	
	for _, row in pairs(self.rows) do
		row.listID = "C"
		row.guid = nil
		row:Hide()
	end
	
	local id = 0
	for _, enemy in pairs(enemies) do
		if( enemy.type == "PLAYER" or ( enemy.type == "MINION" and self.db.profile.showMinions ) or ( enemy.type == "PET" and self.db.profile.showPets ) ) then
			id = id + 1
			
			local row = self.rows[id]
			row.ownerName = enemy.name
			row.ownerType = enemy.type
			row.listID = enemy.sortID
			row.guid = enemy.guid
			row:Show()

			-- Show class icon to the left of the players name
			row.classTexture:Hide()
			row.petTexture:Hide()
			
			if( self.db.profile.showIcon ) then
				if( enemy.type == "PLAYER" ) then
					local coords = CLASS_BUTTONS[enemy.classToken]
					row.classTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
					row.classTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
					row.classTexture:Show()
				else
					local path = petClassIcons[enemy.family or enemy.name]
					if( path ) then
						row.petTexture:SetTexture(path)
						row.petTexture:Show()
					end
				end
			end

			-- Color the health bar by class
			if( enemy.type == "PLAYER" ) then
				row:SetStatusBarColor(RAID_CLASS_COLORS[enemy.classToken].r, RAID_CLASS_COLORS[enemy.classToken].g, RAID_CLASS_COLORS[enemy.classToken].b, 1.0)
			elseif( enemy.type == "PET" ) then
				row:SetStatusBarColor(self.db.profile.petBarColor.r, self.db.profile.petBarColor.g, self.db.profile.petBarColor.b, 1.0)
			elseif( enemy.type == "MINION" ) then
				row:SetStatusBarColor(self.db.profile.minionBarColor.r, self.db.profile.minionBarColor.g, self.db.profile.minionBarColor.b, 1.0)
			end

			-- Set up all the macro things
			for _, macro in pairs(self.db.profile.attributes) do
				if( macro.modifier and macro.button ) then
					if( macro.enabled and ( macro.classes.ALL or macro.classes[enemy.type] ) ) then
						row.button:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
						row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", enemy.name))
					else
						row.button:SetAttribute(macro.modifier .. "type" .. macro.button, nil)
						row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, nil)
					end
				end
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
	
	-- Sort and position
	table.sort(self.rows, sortEnemies)
	
	-- Sort out how much space is between each row + mana bar if included
	local heightUsed = 0
	local manaBar = 0
	if( self.db.profile.manaBar ) then
		manaBar = self.db.profile.manaBarHeight
	end

	-- Position/update displays
	for id, row in pairs(self.rows) do
		if( row.guid and enemies[row.guid] ) then
			-- Grab enemy info
			local enemy = enemies[row.guid]

			-- Add # for easier identification
			row.nameID = ""
			if( self.db.profile.showID ) then
				row.nameID = "#" .. id
			end
			
			if( row.ownerType == "PLAYER" ) then
				row.talentGuess = ""
				if( self.db.profile.showGuess ) then
					local firstPoints, secondPoints, thirdPoints = self.talents:GetTalents(enemy.fullName)
					if( firstPoints and secondPoints and thirdPoints ) then
						row.talentGuess = string.format("[%d/%d/%d] ", firstPoints, secondPoints, thirdPoints)
					end
				end
			
				row.text:SetFormattedText("%s%s%s", row.nameID, row.talentGuess, enemy.name)
			else
				row.text:SetFormattedText("%s%s's %s", row.nameID, enemy.owner, enemy.family or enemy.name)
			end
			
			heightUsed = heightUsed + 18 + manaBar

			-- Reposition
			if( id > 1 ) then
				row:SetPoint("TOPLEFT", self.rows[id - 1], "BOTTOMLEFT", 0, -2 - manaBar)
			else
				row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
			end
		end
	end
	
	
	-- Resize it, I really should learn how to do SetPoint correctly to avoid this hackery
	self.frame:SetHeight(heightUsed)
	self.frame:Show()

	-- Update health info
	self:UpdateAFData()
end

-- Quick redirects!
function SSAF:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")

	local guid = UnitGUID("target")
	if( enemies[guid] ) then
		self:UpdateMana(enemies[guid], "target")
		self:UpdateHealth(enemies[guid], "target")	
	end
end

function SSAF:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")

	local guid = UnitGUID("mouseover")
	if( enemies[guid] ) then
		self:UpdateMana(enemies[guid], "mouseover")
		self:UpdateHealth(enemies[guid], "mouseover")	
	end
end

function SSAF:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")

	local guid = UnitGUID("focus")
	if( enemies[guid] ) then
		self:UpdateMana(enemies[guid], "focus")
		self:UpdateHealth(enemies[guid], "focus")	
	end
end

-- Scan unit, see if they're valid as an enemy or enemy pet
function SSAF:ScanUnit(unit)
	local name, server = UnitName(unit)
	if( name == UNKNOWNOBJECT or not UnitIsEnemy("player", unit) or UnitIsCharmed(unit) or UnitIsCharmed("player") or GetPlayerBuffTexture(L["Arena Preparation"]) ) then
		return
	end

	local guid = UnitGUID(unit)
	if( enemies[guid] ) then
		return
	end
	
	-- Check for a new player
	if( UnitIsPlayer(unit) ) then
		server = server or GetRealmName()
		
		local race = UnitRace(unit)
		local class, classToken = UnitClass(unit)
		local guild = GetGuildInfo(unit)
		local dontReport = enemies[name]
		
		self:AddEnemy(name, server, race, classToken, guild, UnitPowerType(unit), nil, guid, unit)
		self:SendMessage(string.format("ENEMY:%s,%s,%s,%s,%s,%s,%s,%s", name, server, race, classToken, guild or "", UnitPowerType(unit), "", guid))

		if( self.db.profile.reportEnemies and not dontReport ) then
			if( guild ) then
				self:ChannelMessage(string.format("%s / %s / %s / %s / %s", name, server, race, class, guild))
			else
				self:ChannelMessage(string.format("%s / %s / %s / %s", name, server, race, class))
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
			self:AddEnemyPet(name, owner, family, type, UnitPowerType(unit), guid, unit)
			self:SendMessage(string.format("ENEMYPET:%s,%s,%s,%s,%s,%s", name, owner, family or "", type, UnitPowerType(unit), guid))

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
function SSAF:AddEnemy(name, server, race, classToken, guild, powerType, talents, guid, unit)
	if( not guid or enemies[guid] ) then
		return
	end
	
	-- If it's an old version sync, check if we already have a new sync with an actual GUID
	if( name == guid ) then
		for _, enemy in pairs(enemies) do
			if( enemy.name == name ) then
				return
			end
		end
	end

	-- So we can pull out talent data
	local fullName = name
	if( server and server ~= "" ) then
		fullName = string.format("%s-%s", name, server)
	end
	
	-- Store it!
	enemies[guid] = {sortID = "A" .. name .. "-" .. (server or ""),
			name = name,
			fullName = fullName,
			type = "PLAYER",
			server = server,
			race = race,
			classToken = classToken,
			guild = guild,
			guid = guid,
			health = 100,
			mana = 0,
			maxMana = 100,
			powerType = tonumber(powerType) or 0,
			targets = {}}
	
	-- If we have an enemy record for this name/server combo, then it means we have a temp sync from another mod
	-- nil out our old data table, and convert it's AF row to the new one with an actual GUID
	if( enemies[name] and name ~= guid ) then
		enemies[name] = nil
		for id, row in pairs(self.rows) do
			if( row.guid == name ) then
				row.guid = guid
			end
		end
	end

	self:UpdateEnemies()

	if( unit ) then
		self:UpdateHealth(enemies[guid], unit)
		self:UpdateMana(enemies[guid], unit)
	end

	-- Check if a pet has a matching name before we update the name -> guid map
	for guid, enemy in pairs(enemies) do
		if( enemy.type ~= "PLAYER" and enemy.name == name ) then
			return
		end
	end
	
	nameGUIDMap[name] = guid
end

-- New pet found
function SSAF:AddEnemyPet(name, owner, family, type, powerType, guid, unit)
	if( not guid or enemies[guid] ) then
		return
	end
	
	-- If the owner already had a pet, but the GUID is different then remove the old one
	for id, enemy in pairs(enemies) do
		if( enemy.owner == owner and enemy.guid ~= guid ) then
			enemies[id] = nil	
		end
	end
		
	enemies[guid] = {sortID = "B" .. name .. "-" .. owner,
			name = name,
			owner = owner,
			type = type,
			family = family,
			guid = guid,
			health = 100,
			mana = 100,
			maxMana = 100,
			powerType = tonumber(powerType) or 2,
			targets = {}}
	

	self:UpdateEnemies()

	if( unit ) then
		self:UpdateHealth(enemies[guid], unit)
		self:UpdateMana(enemies[guid], unit)
	end

	-- If theres a player with the same name of this pet, then remove the name -> guid map of the player
	for guid, enemy in pairs(enemies) do
		if( enemy.type == "PLAYER" and enemy.name == name ) then
			nameGUIDMap[name] = nil
			return
		end
	end
	
	nameGUIDMap[name] = guid
end

-- Kill an enemy by the GUID
function SSAF:EnemyDied(guid)
	local enemy = enemies[guid]
	if( enemy ) then
		enemy.isDead = true
		enemy.health = 0
		enemy.mana = 0
		
		-- Kill off this players pet if they have any
		if( enemy.type == "PLAYER" ) then
			for guid, pet in pairs(enemies) do
				if( pet.type ~= "PLAYER" and pet.owner == enemy.name ) then
					self:EnemyDied(guid)
				end
			end
		end
	end
end

-- Output
function SSAF:ChannelMessage(msg)
	SendChatMessage(msg, "BATTLEGROUND")
end

function SSAF:SendMessage(msg, type)
	SendAddonMessage("SSAF", msg, "BATTLEGROUND")
end

-- Enabling/Disabling SSAF
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

-- OOC updating
function SSAF:PLAYER_REGEN_ENABLED()
	if( instanceType == "arena" ) then
		SSAF:UpdateEnemies()
	else
		SSAF:ClearEnemies()
	end
	
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

-- Key bindings
function SSAF:UPDATE_BINDINGS()
	if( self.frame ) then
		for id, row in pairs(self.rows) do
			local bindKey = GetBindingKey("ARENATAR" .. id)
			if( bindKey ) then
				SetOverrideBindingClick(row.button, false, bindKey, row.button:GetName())	
			else
				ClearOverrideBindings(row.button)
			end
		end
	end
end

-- Something in configuration changed
function SSAF:Reload()
	if( not self.db.profile.locked ) then
		local noEnemies = true
		for _ in pairs(enemies) do
			noEnemies = nil
		end

		if( noEnemies ) then
			self:AddEnemy(UnitName("player"), GetRealmName(), (UnitRace("player")), select(2, UnitClass("player")), nil, UnitPowerType("player"), nil, "a", "player")
			self:AddEnemy("Mayen", "Icecrown", "TAUREN", "DRUID", nil, 0, nil, "b", "player")
			self:AddEnemyPet(L["Pet"], UnitName("player"), "Cat", "PET", 2, "c", "player")
			self:AddEnemyPet(L["Minion"], "Mayen", "Felhunter", "MINION", 0, "d", "player")
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
	for id, row in pairs(self.rows) do
		-- Texture/mana bar height
		row:SetStatusBarTexture(self.db.profile.barTexture)
		row.manaBar:SetStatusBarTexture(self.db.profile.barTexture)
		row.manaBar:SetHeight(self.db.profile.manaBarHeight)
		
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
	for k in pairs(enemies) do enemies[k] = nil end
	for _, data in pairs(partyTargets) do data.guid = "" end
	
	if( self.rows ) then
		for id, row in pairs(self.rows) do
			row.ownerName = nil
			row.ownerType = nil
			row:Hide()
		end
	end
	
	if( self.frame ) then
		self.frame:Hide()
	end
end

function SSAF:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SSAF|r: " .. msg)
end