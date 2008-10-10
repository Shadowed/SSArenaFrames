--[[ 
	SSArena Frames By Amarand (Horde) / Mayen (Horde) from Icecrown (US) PvE
]]

SSAF = LibStub("AceAddon-3.0"):NewAddon("SSAF", "AceEvent-3.0")

local L = SSAFLocals

local enemies = {}
local partyUnits, partyTargetUnits, partyTargets, arenaUnits, arenaPetUnits, identifyUnits = {}, {}, {}, {}, {}, {}
local instanceType, currentBracket

function SSAF:OnInitialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			locked = true,
			showTargets = true,
			barTexture = "Minimalist",
			showID = false,
			showIcon = false,
			showMinions = true,
			showPets = false,
			showGuess = true,
			showMana = true,
			manaBarHeight = 3,
			position = { x = 300, y = 600 },
			fontColor = { r = 1.0, g = 1.0, b = 1.0 },
			petBarColor = { r = 0.20, g = 1.0, b = 0.20 },
			minionBarColor = { r = 0.30, g = 1.0, b = 0.30 },
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
	
	-- Check if we entered an arena
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA")
	
	-- SML
	self.SML = LibStub:GetLibrary("LibSharedMedia-3.0")
	
	-- TalentGuess
	self.talents = LibStub:GetLibrary("TalentGuess-1.1"):Register()
	self.talents:RegisterCallback(SSAF, "OnTalentData")
	
	self.rows = {}
	
	-- Setup attribute defaults for 3-10
	for i=3, 10 do
		table.insert(self.defaults.profile.attributes, {name = string.format(L["Action #%d"], i), enabled = false, classes = {["ALL"] = true}, modifier = "", button = "", text = "/target *name"})
	end
	
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
end

function SSAF:JoinedArena()
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

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	-- Enable talent guessing
	if( self.db.profile.showGuess ) then
		self.talents:EnableCollection()
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
		
		-- Set the default attribute
		for _, macro in pairs(self.defaults.profile.attributes) do
			if( macro.enabled ) then
				row.button:SetAttribute("type" .. macro.button, "macro")
				row.button:SetAttribute("macrotext" .. macro.button, string.gsub(macro.text, "*name", unit))
			end
		end
		
		row.isDead = nil
		row:SetAlpha(1.0)
		row:Show()
		
		-- Add this unit to the list to search for
		table.insert(identifyUnits, unit)
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

	-- Disable guessing
	self.talents:DisableCollection()
	
	-- Stop scanning
	self.scanFrame:Hide()

	-- Reset
	for k in pairs(partyTargets) do partyTargets[k] = "" end
	for i=#(identifyUnits), 1, -1 do table.remove(identifyUnits, i) end
	
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
function SSAF:UNIT_HEALTH(event, unit)
	if( not arenaUnits[unit] or self.rows[unit].isDead ) then
		return
	end
	
	local row = self.rows[unit]
	local health = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)
	
	row.healthText:SetFormattedText("%d%%", math.floor((health / maxHealth) * 100 + 0.5))
	row:SetMinMaxValues(0, maxHealth)
	row:SetValue(health)
end

-- POWER UPDATE
function SSAF:UNIT_POWER(event, unit)
	if( not arenaUnits[unit] or self.rows[unit].isDead ) then
		return
	end
	
	local row = self.rows[unit]
	row.manaBar:SetMinMaxValues(0, UnitPowerMax(unit, row.powerType))
	row.manaBar:SetValue(UnitPower(unit, row.powerType))
end

-- POWER TYPE CHANGED
function SSAF:UNIT_POWERTYPE(event, unit)
	if( not arenaUnits[unit] or self.rows[unit].isDead ) then
		return
	end

	local row = self.rows[unit]
	row.powerType = UnitPowerType(unit)
	row.manaBar:SetStatusBarColor(PowerBarColor[row.powerType].r, PowerBarColor[row.powerType].g, PowerBarColor[row.powerType].b)
	self:UNIT_POWER(nil, unit)
end

-- ENEMY DIED
function SSAF:EnemyDied(guid)
	for i=1, 5 do
		local unit = arenaUnits[i]
		if( UnitGUID(unit) == guid ) then
			local row = self.rows[unit]
			
			row.healthText:SetText("0%")
			row.manaBar:SetValue(0)
			
			row:SetValue(0)
			row:SetAlpha(0.70)
			row.isDead = true
			break
		end
	end
end

-- ENEMY DEATH
-- We use this still for accuracy reasons
local COMBATLOG_OBJECT_REACTION_HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE
function SSAF:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags)
	-- Slain will always be accurate, and we sync it just to be safe
	if( eventType == "PARTY_KILL" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE ) then
		self:EnemyDied(destGUID)
	
	-- Don't accept UNIT_DIED except for elementals, because Hunters can throw things off
	--elseif( eventType == "UNIT_DIED" and bit.band(destFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE and destName == L["Water Elemental"] ) then
	--	self:EnemyDied(destGUID)
	end
end

-- TARGET OF TARGET
function SSAF:UpdateToT()
	if( not self.db.profile.showTargets ) then
		return
	end
	
	for unit, row in pairs(self.rows) do
		if( UnitExists(unit) ) then
			-- Reset
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

-- New talent data found, do a quick update of everyones talents
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
			row.text:SetFormattedText("%s%s%s", row.nameID, row.talentGuess, UnitName(unit))
		end
	end
end

function SSAF:UpdatePositioning()
	-- Sort out how much space is between each row + mana bar if included
	local heightUsed = 0
	local manaBar = 0
	if( self.db.profile.showMana ) then
		manaBar = self.db.profile.manaBarHeight
	end
	
	for i=1, currentBracket do
		local row = self.rows[arenaUnits[i]]
		
		heightUsed = heightUsed + 18 + manaBar
		
		if( i > 1 ) then
			row:SetPoint("TOPLEFT", self.rows[arenaUnits[i - 1]], "BOTTOMLEFT", 0, -2 - manaBar)
		else
			row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
		end
	end
	
	-- Update size
	self.frame:SetHeight(heightUsed)
end

-- Update frame
function SSAF:UpdateRow(unit, row)
	-- Set ID to make it easier to identify people if needed
	row.nameID = ""
	if( self.db.profile.showID ) then
		row.nameID = string.format("%d)", row.id)
	end
	
	row.classTexture:Hide()
	row.petTexture:Hide()
	
	-- Unit doesn't exist yet, just show unknown
	if( not UnitExists(unit) ) then
		row.text:SetText(UNKNOWNOBJECT)
		row.healthText:SetText("")
		row.manaBar:SetValue(0)
		
		if( self.db.profile.showIcon ) then
			row.petTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			row.petTexture:Show()
		end
		
		row:SetMinMaxValues(0, 100)
		row:SetValue(100)
		row:SetStatusBarColor(0.50, 0.50, 0.50, 0.50)
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
	row.text:SetFormattedText("%s%s%s", row.nameID, row.talentGuess, UnitName(unit))
	row:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1.0)
	
	-- Class icon
	if( self.db.profile.showIcon ) then
		local coords = CLASS_BUTTONS[class]
		row.classTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		row.classTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		row.classTexture:Show()
	end
	
	-- Set up all the macro things to class specific if we can
	--[[
	if( not InCombatLockdown() ) then
		for _, macro in pairs(self.db.profile.attributes) do
			if( macro.modifier and macro.button ) then
				if( macro.enabled and ( macro.classes.ALL or macro.classes[class] ) ) then
					row.button:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
					row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", unit))
				else
					row.button:SetAttribute(macro.modifier .. "type" .. macro.button, nil)
					row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, nil)
				end
			end
		end
	end
	]]
	
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
				SetOverrideBindingClick(row.button, false, bindKey, row.button:GetName())	
			else
				ClearOverrideBindings(row.button)
			end
		end
	end
end

-- Something in configuration changed
function SSAF:Reload()
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
	for unit, row in pairs(self.rows) do
		-- Texture/mana bar height
		row:SetStatusBarTexture(self.db.profile.barTexture)
		row.manaBar:SetStatusBarTexture(self.db.profile.barTexture)
		row.manaBar:SetHeight(self.db.profile.manaBarHeight)
		
		-- Update ToT textures
		for _, texture in pairs(row.targets) do
			texture:SetTexture(self.db.profile.barTexture)
			
			if( not self.db.profile.showTargets ) then
				texture:Hide()
			end
		end
	
		-- Update text color
		row.text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
		row.healthText:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	end
	
	-- Update frame
	if( self.frame and self.frame:IsVisible() ) then
		self:UpdateRows()
	end
end

function SSAF:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SSAF|r: " .. msg)
end

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