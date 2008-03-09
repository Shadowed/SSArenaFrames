--[[ 
	SSArena Frames By Amarand (Horde) / Mayen (Horde) from Icecrown (US) PvE
]]

SSAF = LibStub("AceAddon-3.0"):NewAddon("SSAF", "AceEvent-3.0")

local L = SSAFLocals

local enemies, enemyPets = {}, {}
local queuedUpdates = {}
local partyTargets, partyUnit, partyTargetUnit, usedRows = {}, {}, {}, {}
local instanceType

local hookLoaded

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
			barTexture = "BantoBar",
			showID = false,
			showIcon = false,
			showMinions = true,
			showPets = false,
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
				{ enabled = true, classes = { ["ALL"] = true }, modifier = "", button = "2", text = "/targetexact *name\n/focus\n/targetlasttarget" },
			}
		}
	}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SSAFDB", self.defaults)
	
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BINDINGS")
	
	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")

	
	-- Tekkub would be so proud, we're using metatables
	self.rows = setmetatable({}, {__index = function(t, k)
		local row = SSAF.modules.Frame:CreateRow(k)
		rawset(t, k, row)
		
		return row
	end})
	
	-- Default party units
	for i=1, MAX_PARTY_MEMBERS do
		partyUnit[i] = "party" .. i
		partyTargets["party" .. i .. "target"] = {}
		partyTargetUnit[i] = "party" .. i .. "target"
	end
	
	self.partyTargets = partyTargets
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
	
	-- Enable syncing
	self.modules.Sync:EnableModule()
	
	-- Pre-create if need be
	for i=1, 10 do
		local val = self.rows[i]
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
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UPDATE_BINDINGS")
end

-- CHECK ARENA ZONE IN
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

-- UPDATE OOC QUEUES
function SSAF:PLAYER_REGEN_ENABLED()
	for func in pairs(queuedUpdates) do
		self[func](self)
		queuedUpdates[func] = nil
	end
end

-- BINDINGS
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

-- HEALTH UPDATES
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

-- POWER TYPE
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

-- ENEMY DEATH
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
function SSAF:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags)
	if( eventType == "PARTY_KILL" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		self:EnemyDied(destGUID)
		self:SendMessage("ENEMYDIED:" .. destGUID)
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
				
		if( enemy and enemy.displayRow and self.rows[enemy.displayRow] ) then
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
		self.modules.Frame:UpdateToTTextures(self.rows[id], self.rows[id].usedIcons)
	end
end

-- TARGET OF TARGET + HEALTH SCANS
-- Health value updated, rescan our saved enemies
local function healthValueChanged(...)
	if( this.SSAFValueChanged ) then
		this.SSAFValueChanged(...)
	end

	if( instanceType ~= "arena" ) then
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
local numChildren = -1
local timeElapsed = 0
function SSAF.ScanPartyTargets(self, elapsed)
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
		timeElapsed = 0

		for i=1, GetNumPartyMembers() do
			local unit = partyTargetUnit[i]
			local name = UnitName(unit)
			local isPlayer = UnitIsPlayer(unit)

			-- Target monitoring
			if( partyTargets[unit].name ~= name or partyTargets[unit].isPlayer ~= isPlayer ) then
				partyTargets[unit].name = name
				partyTargets[unit].isPlayer = isPlayer
				partyTargets[unit].class = select(2, UnitClass(partyUnit[i]))

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
end

-- HEALTH UPDATES
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

-- MANA UPDATES
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

-- UPDATE NEEMY DISPLAY
local function sortEnemies(a, b)
	if( not a ) then
		return true

	elseif( not b ) then
		return false
	end
	
	return ( a.listID < b.listID )
end

function SSAF:UpdateEnemies()
	-- Can't update in combat, so queue it for when we drop
	if( InCombatLockdown() ) then
		self:RegisterOOCUpdate("UpdateEnemies")
		return
	end
	
	for _, row in pairs(self.rows) do
		row.listID = "C"
		row:Hide()
	end
	
	local id = 0
	
	-- UPDATE ENEMY PLAYERS
	for _, enemy in pairs(enemies) do
		id = id + 1
		
		local row = self.rows[id]
		row.ownerName = enemy.name
		row.ownerType = "PLAYER"
		row.listID = "A" .. enemy.sortID
		row:Show()
				
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
	
	-- Update enemy pets
	for _, enemy in pairs(enemyPets) do
		if( ( enemy.type == "MINION" and self.db.profile.showMinions ) or ( enemy.type == "PET" and self.db.profile.showPets ) ) then
			id = id + 1

			local row = self.rows[id]
			row:Show()

			-- Show it as "<owner>'s <pet family> or <pet name> if no family"
			row.ownerName = enemy.name
			row.ownerType = enemy.type
			row.listID = "B" .. enemy.sortID

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
	
	-- Sort and position
	table.sort(self.rows, sortEnemies)
	
	for id, row in pairs(self.rows) do
		if( row.listID ~= "C" ) then
			usedRows[id] = nil
			row.usedIcons = 0

			for _, texture in pairs(row.targets) do
				texture:Hide()
			end
		
			if( self.db.profile.showID ) then
				row.nameID = "#" .. id
			else
				row.nameID = ""
			end
		
			if( row.ownerType == "PLAYER" ) then
				local enemy = enemies[row.ownerName]			
				enemy.displayRow = id
				row.text:SetFormattedText("%s%s", row.nameID, enemy.name)
			else
				local enemy = enemyPets[row.ownerName]
				enemy.displayRow = id
				row.text:SetFormattedText("%s%s's %s", row.nameID, enemy.owner, enemy.family or enemy.name)
			end

			if( id > 1 ) then
				row:SetPoint("TOPLEFT", self.rows[id - 1], "BOTTOMLEFT", 0, -2)
			else
				row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
			end
		end
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
	local name, server = UnitName(unit)
	if( name == UNKNOWNOBJECT or not UnitIsEnemy("player", unit) or UnitIsCharmed(unit) or UnitIsCharmed("player") or GetPlayerBuffTexture(L["Arena Preparation"]) ) then
		return
	end
	
	-- Check if we should update their health/mana/ect info
	local isPlayer = UnitIsPlayer(unit)
	if( enemies[name] and isPlayer ) then
		self:UpdateMana(enemies[name], unit)
		self:UpdateHealth(enemies[name], unit)	
	

	elseif( enemyPets[name] and not isPlayer ) then
		self:UpdateMana(enemyPets[name], unit)
		self:UpdateHealth(enemyPets[name], unit)
	end
	
	-- Check for a new player
	if( isPlayer ) then
		server = server or GetRealmName()
		
		if( enemies[name] ) then
			-- Most syncs from other addons don't provide server or GUID
			if( enemies[name].server and enemies[name].guid ) then
				return
			end
			
			enemies[name].sortID = name .. "-" .. server
			enemies[name].server = server
			enemies[name].guid = UnitGUID(unit)
			return
		end
		
		local race = UnitRace(unit)
		local class, classToken = UnitClass(unit)
		local guild = GetGuildInfo(unit)
		
		self:AddEnemy(name, server, race, classToken, guild, UnitPowerType(unit), nil, nil, unit)
		self:SendMessage(string.format("ENEMY:%s,%s,%s,%s,%s,%s,%s,%s", name, server, race, classToken, guild or "", UnitPowerType(unit), "", UnitGUID(unit)))

		if( self.db.profile.reportEnemies ) then
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
			self:SendMessage(string.format("ENEMYPET:%s,%s,%s,%s,%s,%s", name, owner, family or "", type, UnitPowerType(unit), UnitGUID(unit)))

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
	if( enemies[name] ) then
		return
	end
	
	local health, mana, maxHealth, maxMana
	if( unit ) then
		health = UnitHealth(unit)
		mana = UnitMana(unit)
		
		maxHealth = UnitHealthMax(unit)
		maxMana = UnitManaMax(unit)
		
		guid = UnitGUID(unit)
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
			health = health or 100,
			maxHealth = maxHealth or 100,
			mana = mana or 0,
			maxMana = maxMana or 100,
			guid = guid,
			powerType = tonumber(powerType) or 0}
	
	-- Check if a pet has the same as this player
	if( enemyPets[name] ) then
		enemies[name].isCorrupted = true
	end

	self:UpdateEnemies()
	return true
end

-- New pet found
function SSAF:AddEnemyPet(name, owner, family, type, powerType, guid, unit)
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
		
		guid = UnitGUID(unit)
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
				guid = guid,
				powerType = tonumber(powerType) or 2}
				
	self:UpdateEnemies()
	return true
end

-- Kill an enemy by the GUID
function SSAF:EnemyDied(guid)
	for name, enemy in pairs(enemies) do
		if( not enemy.isDead and enemy.guid and enemy.guid == guid ) then
			enemy.isDead = true
			enemy.health = 0
			enemy.mana = 0
			
			return true
		end
	end

	for name, enemy in pairs(enemyPets) do
		if( not enemy.isDead and enemy.guid and enemy.guid == guid ) then
			enemy.isDead = true
			enemy.health = 0
			enemy.mana = 0
			
			return true
		end
	end
	
	return false
end

-- Output
function SSAF:ChannelMessage(msg)
	SendChatMessage(msg, "BATTLEGROUND")
end

function SSAF:SendMessage(msg, type)
	SendAddonMessage("SSAF", msg, "BATTLEGROUND")
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
			self:AddEnemy(UnitName("player"), GetRealmName(), (UnitRace("player")), select(2, UnitClass("player")), nil, UnitPowerType("player"), nil, nil, "player")
			self:AddEnemy("Mayen", "Icecrown", "TAUREN", "DRUID", nil, 0, nil, nil, "player")
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
	for id, row in pairs(self.rows) do
		-- Texture/mana bar height
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