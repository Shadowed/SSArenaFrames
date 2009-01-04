local Trinket = SSAF:NewModule("Trinket", "AceEvent-3.0")
local trinketIcon

function Trinket:OnInitialize()
	-- Use the appropiate icon for there level/faction of the player, NOT the enemy
	if( UnitFactionGroup("player") == "Horde" ) then
		trinketIcon = UnitLevel("player") == 80 and "Interface\\Icons\\INV_Jewelry_Necklace_38" or "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
	else
		trinketIcon = UnitLevel("player") == 80 and "Interface\\Icons\\INV_Jewelry_Necklace_37" or "Interface\\Icons\\INV_Jewelry_TrinketPVP_01"
	end
		
	trinketIcon = string.format("|T%s:26:26:0:0|t", trinketIcon)
end

--[[
function Trinket:Test()
	SSAF.modules.Trinket:Enable()
	local row = SSAF.rows["arena1"]
	row.trinket.readyTime = GetTime() + 5
	row.trinket.timeElapsed = 0
	row.nameID = ""
	row.unitid = "player"
	row.talentGuess = ""

	SSAF.modules.Trinket:UpdateIcon(row, nil)
end
]]

local function onUpdate(self, elapsed)
	if( self.readyTime ) then
		self.timeElapsed = self.timeElapsed + elapsed
		
		if( self.timeElapsed >= 1 ) then
			self.timeElapsed = 0
			
			if( self.readyTime <= GetTime() ) then
				self.timeElapsed = 0
				self.readyTime = nil
				Trinket:UpdateIcon(self:GetParent(), true)
			end
		end
	end
end

function Trinket:Enable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	-- Set the icons to visible for everyone
	for _, row in pairs(SSAF.rows) do
		row.nameExtra = trinketIcon
		row.trinket = row.trinket or CreateFrame("Frame", nil, row)
		row.trinket.timeElapsed = 0
		row.trinket:SetScript("OnUpdate", onUpdate)
	end
end

function Trinket:Disable()
	for _, row in pairs(SSAF.rows) do
		if( row.trinket ) then
			row.trinket.readyTime = nil
		end
	end
	
	self:UnregisterAllEvents()
end

-- Update trinket icon (If any)
function Trinket:UpdateIcon(row, trinketUp)
	row.nameExtra = trinketUp and trinketIcon or ""
	row.text:SetFormattedText("%s%s%s%s", row.nameID, row.talentGuess, row.nameExtra, UnitName(row.unitid))
end


-- Check for PvP trinkets being used
local COMBATLOG_OBJECT_REACTION_HOSTILE	= COMBATLOG_OBJECT_REACTION_HOSTILE
function Trinket:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool)
	if( eventType ~= "SPELL_CAST_SUCCESS" or (bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= COMBATLOG_OBJECT_REACTION_HOSTILE) ) then
		return
	end
	
	-- Human Racial / PvP Trinket
	if( spellID ~= 59752 and spellID ~= 42292 ) then
		return
	end
	
	-- Find valid row + hide trinket icon
	for unit, row in pairs(SSAF.rows) do
		if( UnitGUID(unit) == sourceGUID ) then
			row.trinket.readyTime = GetTime() + 120
			self:UpdateIcon(row, nil)
			break
		end
	end
end