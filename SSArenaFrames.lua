--[[ 
	SSArena Frames By Selari (Horde) / Mayen (Horde) from Illidan (US) PvP
]]

SSAF = LibStub("AceAddon-3.0"):NewAddon("SSAF", "AceEvent-3.0")

local L = SSAFLocals

local enemies = {}
local partyUnits, partyTargetUnits, partyTargets, arenaUnits, arenaPetUnits, identifyUnits = {}, {}, {}, {}, {}, {}, {}
local instanceType, currentBracket, SML

function SSAF:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			locked = true,
			growUp = false,
			barTexture = "Minimalist",
			healthType = "percent",
			manaBarHeight = 3,
			showTargets = true,
			showID = false,
			showIcon = false,
			showGuess = true,
			showMana = true,
			showCast = true,
			showTrinket = true,
			showAura = false,
			position = { x = 300, y = 600 },
			fontColor = { r = 1.0, g = 1.0, b = 1.0 },
			attributes = {
				-- Valid modifiers: shift, ctrl, alt
				-- LeftButton/RightButton/MiddleButton/Button4/Button5
				-- All numbered from left -> right as 1 -> 5
				{ name = "Target enemy", enabled = true, classes = { ["ALL"] = true }, modifier = "", button = "", text = "/target *name" },
				{ name = "Focus enemy", enabled = true, classes = { ["ALL"] = true }, modifier = "", button = "2", text = "/focus *name\n/script SSAF:Print(string.format(\"Set focus %s\", UnitName(\"focus\") or \"<no focus>\"));" },
			}
		}
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SSAFDB", self.defaults)
	self.revision = tonumber(string.match("$Revision$", "(%d+)") or 1)
	
	-- Setup attribute defaults for 3-10
	for i=3, 10 do
		table.insert(self.defaults.profile.attributes, {name = string.format(L["Action #%d"], i), enabled = false, classes = {["ALL"] = true}, modifier = "", button = "", text = "/target *name"})
	end
	
	-- Check if we entered an arena
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	
	-- SML
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
		
	-- TalentGuess
	self.talents = LibStub:GetLibrary("TalentGuess-1.1"):Register()
	self.talents:RegisterCallback(SSAF, "OnTalentData")
	
	-- Default party units
	for i=1, MAX_PARTY_MEMBERS do
		partyUnits[i] = "party" .. i
		partyTargetUnits[i] = "party" .. i .. "target"
		partyTargets["party" .. i] = ""
	end

	-- Default arena units
	for i=1, 5 do
		arenaUnits[i] = "arena" .. i
		arenaUnits[arenaUnits[i]] = true
	end
	
	self.arenaUnits = arenaUnits
	self.rows = {}
	
	--[[
	self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
		SSAF:Reload()
	end)
	]]
end

function SSAF:JoinedArena()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")

	self:RegisterEvent("UNIT_MANA", "UNIT_POWER")
	self:RegisterEvent("UNIT_RAGE", "UNIT_POWER")
	self:RegisterEvent("UNIT_ENERGY", "UNIT_POWER")
	self:RegisterEvent("UNIT_FOCUS", "UNIT_POWER")
	self:RegisterEvent("UNIT_RUNIC_POWER", "UNIT_POWER")

	self:RegisterEvent("UNIT_MAXMANA", "UNIT_POWER")
	self:RegisterEvent("UNIT_MAXRAGE", "UNIT_POWER")
	self:RegisterEvent("UNIT_MAXENERGY", "UNIT_POWER")
	self:RegisterEvent("UNIT_MAXFOCUS", "UNIT_POWER")
	self:RegisterEvent("UNIT_MAXRUNIC_POWER", "UNIT_POWER")

	self:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_POWERTYPE")

	-- Enable talent guessing
	if( self.db.profile.showGuess ) then
		self.talents:EnableCollection()
	end
	
	-- Enable casting module
	if( self.db.profile.showCast ) then
		self.modules.Cast:Enable()
	end
	
	-- Enable aura module
	if( self.db.profile.showAura ) then
		self.modules.Aura:Enable()
	end
	
	-- Figure out arena bracket
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
		if( status == "active" and teamSize > 0 ) then
			currentBracket = teamSize
			break
		end
	end
	
	-- Update/show rows
	for i=1, currentBracket do
		-- Create it if needed
		local unit = arenaUnits[i]
		local row = self.rows[unit]
		if( not row ) then
			row = self.modules.Frame:CreateRow(i)
			self.rows[unit] = row
		end

		-- Reset current tots
		for i=1, 4 do
			row.targets[i]:Hide()
		end
				
		row.isDead = nil
		row.isSetup = nil
		row.classSet = nil
		row.nameExtra = ""
		row:SetAlpha(1.0)
		row:Show()
		
		-- Add this unit to the list to search for
		table.insert(identifyUnits, unit)
	end
	
	-- Enable trinket module
	if( self.db.profile.showTrinket ) then
		self.modules.Trinket:Enable()
	end

	-- Update bindings
	self:UPDATE_BINDINGS()
	
	-- Show base frame + scanning
	self.frame:Show()
	self.scanFrame:Show()
	
	-- Update positioning + who we know
	self:UpdatePositioning()
	self:UpdateRows()
end

function SSAF:LeftArena()
	self:UnregisterAllEvents()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	
	-- Disable modules
	self.modules.Cast:Disable()
	self.modules.Aura:Disable()
	self.modules.Trinket:Disable()
	
	-- Disable guessing
	self.talents:DisableCollection()
	
	-- Stop scanning
	self.scanFrame:Hide()
	
	-- Reset
	for k in pairs(partyTargets) do partyTargets[k] = "" end
	for i=#(identifyUnits), 1, -1 do table.remove(identifyUnits, i) end
	
	-- If we're in combat, wait until we leave it to hide the frame, otherwise do so now
	if( InCombatLockdown() ) then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self.frame:Hide()
		for _, row in pairs(self.rows) do
			row:Hide()
		end
	end
end

-- Hide the frame
function SSAF:PLAYER_REGEN_ENABLED()
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")

	self.frame:Hide()
	for _, row in pairs(self.rows) do
		row:Hide()
	end
end

-- HEALTH UPDATES
local healthFormats = {
	["percent"] = function(text, current, max) text:SetFormattedText("%d%%", math.floor((current / max) * 100 + 0.5)) end,
	["current"] = function(text, current, max) text:SetFormattedText("%d", current) end,
	["currentmax"] = function(text, current, max) text:SetFormattedText("%d/%d", current, max) end,
}

function SSAF:UNIT_HEALTH(event, unit)
	if( not arenaUnits[unit] or self.rows[unit].isDead ) then
		return
	end
	
	local row = self.rows[unit]
	local health = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)
	
	healthFormats[self.db.profile.healthType](row.healthText, health, maxHealth)
	row.health:SetMinMaxValues(0, maxHealth)
	row.health:SetValue(health)
end

-- POWER UPDATE
function SSAF:UNIT_POWER(event, unit)
	if( not arenaUnits[unit] or self.rows[unit].isDead ) then
		return
	end
	
	local row = self.rows[unit]
	row.mana:SetMinMaxValues(0, UnitPowerMax(unit, row.powerType))
	row.mana:SetValue(UnitPower(unit, row.powerType))
end

-- POWER TYPE CHANGED
function SSAF:UNIT_POWERTYPE(event, unit)
	if( not arenaUnits[unit] or self.rows[unit].isDead ) then
		return
	end

	local row = self.rows[unit]
	row.powerType = UnitPowerType(unit)
	row.mana:SetStatusBarColor(PowerBarColor[row.powerType].r, PowerBarColor[row.powerType].g, PowerBarColor[row.powerType].b)
	row.mana:SetMinMaxValues(0, UnitPowerMax(unit, row.powerType))
	row.mana:SetValue(UnitPower(unit, row.powerType))
end

-- ENEMY DIED
function SSAF:EnemyDied(guid)
	for i=1, 5 do
		local unit = arenaUnits[i]
		if( UnitGUID(unit) == guid ) then
			local row = self.rows[unit]
			
			-- Reset current tots
			for i=1, 4 do
				row.targets[i]:Hide()
			end

			healthFormats[self.db.profile.healthType](row.healthText, 0, UnitHealthMax(unit))
			row.mana:SetValue(0)
			row.health:SetValue(0)
			
			row:SetAlpha(0.70)
			row.isDead = true
			break
		end
	end
end

-- ENEMY DEATH
-- We use this still for accuracy reasons, slain will always be 100% accurate, if they add arenas above 5 players we're fucked however
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
function SSAF:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags)
	if( eventType == "PARTY_KILL" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		self:EnemyDied(destGUID)
	end
end

-- TARGET OF TARGET
function SSAF:UpdateToT()
	if( not self.db.profile.showTargets ) then
		return
	end
	
	for unit, row in pairs(self.rows) do
		if( UnitExists(unit) ) then
			-- Reset currents
			for i=1, 4 do
				row.targets[i]:Hide()
			end
			
			-- Set the actual textures + set how many icons are being used
			row.usedIcons = 0
			for partyUnit, guid in pairs(partyTargets) do
				if( guid ~= "" and UnitGUID(unit) == guid ) then
					row.usedIcons = row.usedIcons + 1

					local texture = row.targets[row.usedIcons]
					local class = select(2, UnitClass(partyUnit))
					
					texture:SetVertexColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)
					texture:Show()
				end
			end
			
			-- Update positioning
			self.modules.Frame:UpdateToTTextures(row, row.usedIcons)
		end
	end
end

-- New talent data found, do a quick update of the persons talents
function SSAF:OnTalentData(guid)
	if( not self.db.profile.showGuess ) then
		return
	end
	
	for unit, row in pairs(self.rows) do
		if( UnitGUID(unit) == guid ) then
			row.talentGuess = ""
			local firstPoints, secondPoints, thirdPoints = self.talents:GetTalents(guid)
			if( firstPoints and secondPoints and thirdPoints ) then
				row.talentGuess = string.format("[%d/%d/%d] ", firstPoints, secondPoints, thirdPoints)
			end
			row.text:SetFormattedText("%s%s%s%s", row.nameID, row.talentGuess, row.nameExtra, UnitName(unit))
		end
	end
end

function SSAF:UpdatePositioning()
	local barHeight = 3
	if( self.db.profile.showMana ) then
		barHeight = self.db.profile.manaBarHeight + 3
	end
	
	for i=1, currentBracket do
		local row = self.rows[arenaUnits[i]]
		row:ClearAllPoints()
		
		if( i > 1 ) then
			if( not self.db.profile.growUp ) then
				row:SetPoint("TOPLEFT", self.rows[arenaUnits[i - 1]], "BOTTOMLEFT", 0, -2 - barHeight)
			else
				row:SetPoint("BOTTOMLEFT", self.rows[arenaUnits[i - 1]], "TOPLEFT", 0, 2 + barHeight)
			end
		elseif( self.db.profile.growUp ) then
			row:SetPoint("BOTTOMLEFT", self.frame, "TOPLEFT", 0, 0)
		else
			row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
		end
	end

	-- Update size
	self.borderFrame:ClearAllPoints()
	self.borderFrame:SetPoint("TOPLEFT", self.rows[arenaUnits[(self.db.profile.growUp and currentBracket or 1)]], -1, 2)
	self.borderFrame:SetPoint("BOTTOMRIGHT", self.rows[arenaUnits[(self.db.profile.growUp and 1 or currentBracket)]], 1, -1 - barHeight)

	-- Position anchor
	self.anchor:ClearAllPoints()
	if( not self.db.profile.growUp ) then
		self.anchor:SetPoint("TOPLEFT", self.borderFrame, "TOPLEFT", 0, 20)
	else
		self.anchor:SetPoint("BOTTOMLEFT", self.borderFrame, "BOTTOMLEFT", 0, -16)
	end
end

-- Update an icon
function SSAF:SetCustomIcon(row, icon)
	if( icon ) then
		row.miscTexture:SetTexture(icon)
		row.miscTexture:Show()
		row.classTexture:Hide()	
	elseif( not row.classSet ) then
		row.miscTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		row.miscTexture:Show()
		row.classTexture:Hide()
	else
		row.miscTexture:Hide()
		row.classTexture:Show()
	end
end

-- Update frame
function SSAF:UpdateRow(unit, row)
	-- Set ID to make it easier to identify people if needed
	row.nameID = ""
	if( self.db.profile.showID ) then
		row.nameID = string.format("%d)", row.id)
	end
	
	row.classTexture:Hide()
	row.miscTexture:Hide()
	
	-- Unit doesn't exist yet, just show unknown
	if( not UnitExists(unit) ) then
		row.text:SetText(UNKNOWNOBJECT)
		healthFormats[self.db.profile.healthType](row.healthText, 0, 100)
		row.mana:SetStatusBarColor(0.50, 0.50, 0.50, 0.50)
		row.mana:SetMinMaxValues(0, 100)
		row.mana:SetValue(100)
		
		if( self.db.profile.showIcon ) then
			row.miscTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			row.miscTexture:Show()
		end
				
		row.health:SetStatusBarColor(0.75, 0.75, 0.75, 0.50)
		row.health:SetMinMaxValues(0, 100)
		row.health:SetValue(100)

		-- Setup what we know as being generic, things that run for all classes
		if( not InCombatLockdown() ) then
			for _, macro in pairs(self.db.profile.attributes) do
				if( macro.modifier and macro.button and macro.enabled and macro.classes.ALL ) then
					row:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
					row:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", unit))
				end
			end
		end
		return
	end
		
	-- Pull from talent guess if available
	row.talentGuess = ""
	if( self.db.profile.showGuess ) then
		local firstPoints, secondPoints, thirdPoints = self.talents:GetTalents(UnitGUID(unit))
		if( firstPoints and secondPoints and thirdPoints ) then
			row.talentGuess = string.format("[%d/%d/%d] ", firstPoints, secondPoints, thirdPoints)
		end
	end
	
	local class = select(2, UnitClass(unit))
	
	-- Finally update
	row.text:SetFormattedText("%s%s%s%s", row.nameID, row.talentGuess, row.nameExtra, UnitName(unit))
	row.health:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1.0)
	
	-- Class icon
	if( self.db.profile.showIcon and not row.classSet ) then
		local coords = CLASS_BUTTONS[class]
		row.classSet = true
		row.classTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		row.classTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		row.classTexture:Show()
	end
	
	-- Set up all the macro things to class specific if we can
	if( not InCombatLockdown() and not row.isSetup ) then
		for _, macro in pairs(self.db.profile.attributes) do
			if( macro.modifier and macro.button ) then
				if( macro.enabled and ( macro.classes.ALL or macro.classes[class] ) ) then
					row:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
					row:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", unit))
				end
			end
		end
		
		row.isSetup = true
	end
	
	-- Update health/mana/power
	self:UNIT_HEALTH(nil, unit)
	self:UNIT_POWER(nil, unit)
	self:UNIT_POWERTYPE(nil, unit)
end

function SSAF:UpdateRows()
	for unit, row in pairs(self.rows) do
		self:UpdateRow(unit, row)
	end

	self:UpdateToT()
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

-- Key bindings
function SSAF:UPDATE_BINDINGS()
	if( self.frame ) then
		for unit, row in pairs(self.rows) do
			local bindKey = GetBindingKey("ARENATAR" .. row.id)
			if( bindKey ) then
				SetOverrideBindingClick(row, false, bindKey, row:GetName())	
			else
				ClearOverrideBindings(row)
			end
		end
	end
end

-- Something in configuration changed
function SSAF:Reload()
	-- Example
	if( instanceType ~= "arena" and not self.db.profile.locked ) then
		currentBracket = 2
		for i=1, currentBracket do
			-- Create it if needed
			local unit = arenaUnits[i]
			local row = self.rows[unit]
			if( not row ) then
				row = self.modules.Frame:CreateRow(i)
				self.rows[unit] = row
			end

			row.isDead = nil
			row.isSetup = nil
			row:SetAlpha(1.0)
			row:Show()
		end

		self.frame:Show()
		self:UpdateRows()
		self:UpdatePositioning()
	elseif( self.frame and instanceType ~= "arena" ) then
		self.frame:Hide()
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
	
	local texture = SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture)
		
	-- Update all the rows to the current settings
	for unit, row in pairs(self.rows) do
		-- Textures
		row.health:SetStatusBarTexture(texture)
		row.cast:SetStatusBarTexture(texture)
		row.mana:SetStatusBarTexture(texture)
		
		-- Mana bar
		row.mana:ClearAllPoints()
		row.mana:SetPoint("BOTTOMLEFT", row.health, 0, -self.db.profile.manaBarHeight)
		row.mana:SetPoint("BOTTOMRIGHT", row.health, 0, -self.db.profile.manaBarHeight)
		row.mana:SetHeight(self.db.profile.manaBarHeight)
		
		if( not self.db.profile.showMana ) then
			row.mana:Hide()
		else
			row.mana:Show()
		end
		
		-- Update ToT textures
		for _, texture in pairs(row.targets) do
			texture:SetTexture(self.db.profile.barTexture)
			
			if( not self.db.profile.showTargets ) then
				texture:Hide()
			end
		end
		
		-- Cast bar
		local offset = -12
		if( self.db.profile.showMana ) then
			offset = -self.db.profile.manaBarHeight - 12
		end
	
		row.cast:ClearAllPoints()
		row.cast:SetPoint("BOTTOMLEFT", row.health, 0, offset)
		row.cast:SetPoint("BOTTOMRIGHT", row.health, 0, offset)

		if( self.db.profile.showCast ) then
			row:SetHeight(27)
		else
			row:SetHeight(16)
			row.cast:Hide()
		end
	
		-- Update text color
		row.text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
		row.healthText:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)

		row.castName:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
		row.castTime:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	end
	
	-- Update frame
	if( self.frame and self.frame:IsVisible() ) then
		self:UpdateRows()
		self:UpdatePositioning()
	end
end

function SSAF:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SSAF|r: " .. msg)
end

-- Handle scanning
local timeElapsed = 0
local frame = CreateFrame("Frame")
frame:Hide()

frame:SetScript("OnUpdate", function(self, elapsed)
	timeElapsed = timeElapsed + elapsed
	if( timeElapsed >= 0.50 ) then
		timeElapsed = 0
		
		-- Setup a new unit?
		for i=#(identifyUnits), 1, -1 do
			local unit = identifyUnits[i]
			if( UnitExists(unit) and UnitName(unit) ~= UNKNOWNOBJECT ) then
				SSAF:UpdateRow(unit, SSAF.rows[unit])
				table.remove(identifyUnits, i)
			end
		end
	
		-- Update ToT
		local updateToT
		for i=1, GetNumPartyMembers() do
			local guid = UnitGUID(partyTargetUnits[i])
			if( guid ~= partyTargets[partyUnits[i]] ) then
				partyTargets[partyUnits[i]] = guid
				updateToT = true
			end
		end
	
		if( updateToT ) then
			SSAF:UpdateToT()
		end
	end
end)

SSAF.scanFrame = frame