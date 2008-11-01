local Trinket = SSAF:NewModule("Trinket", "AceEvent-3.0")
local trinketStatus = {}
local arenaUnits, frame, trinketIcon

function Trinket:OnInitialize()
	arenaUnits = SSAF.arenaUnits
	
	-- Use the appropiate icon fro there level/faction of the player, NOT the enemy
	if( UnitFactionGroup("player") == "Horde" ) then
		trinketIcon = UnitLevel("player") == 80 and "Interface\\Icons\\INV_Jewelry_Necklace_38" or "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
	else
		trinketIcon = UnitLevel("player") == 80 and "Interface\\Icons\\INV_Jewelry_Necklace_37" or "Interface\\Icons\\INV_Jewelry_TrinketPVP_01"
	end
	
	trinketIcon = string.format("|T%s:25:25:0:0|t", trinketIcon)
end

function Trinket:Enable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	-- Set the icons to visible for everyone
	for _, row in pairs(SSAF.rows) do
		row.nameExtra = trinketIcon
	end
	
	-- Monitor trinket time lefts
	if( not frame ) then
		frame = CreateFrame("Frame")
		frame.timeElapsed = 0
		frame:SetScript("OnUpdate", function(self, elapsed)
			frame.timeElapsed = frame.timeElapsed + elapsed
			
			if( frame.timeElapsed > 1 ) then
				frame.timeElapsed = 0

				local time = GetTime()
				for guid, endTime in pairs(trinketStatus) do
					if( time >= endTime ) then
						trinketStatus[guid] = nil
						Trinket:UpdateIcon(guid, true)
					end
				end
			end
		end)
	end
	
	frame:Show()
end

function Trinket:Disable()
	-- Reset data
	for k in pairs(trinketStatus) do
		trinketStatus[k] = nil
	end

	self:UnregisterAllEvents()

	frame:Hide()
end

-- Update trinket icon (If any)
function Trinket:UpdateIcon(guid, trinketUp)
	-- Find the GUID this is associated with
	for unit, row in pairs(SSAF.rows) do
		if( UnitGUID(unit) == guid ) then
			row.nameExtra = trinketUp and trinketIcon or ""
			row.text:SetFormattedText("%s%s%s%s", row.nameID, row.talentGuess, row.nameExtra, UnitName(unit))
			break
		end
	end
end

-- Check for PvP trinkets being used
local COMBATLOG_OBJECT_REACTION_HOSTILE	= COMBATLOG_OBJECT_REACTION_HOSTILE
function Trinket:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool)
	if( eventType ~= "SPELL_CAST_SUCCESS" or (bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= COMBATLOG_OBJECT_REACTION_HOSTILE) or spellID ~= 42292 ) then
		return
	end
	
	trinketStatus[sourceGUID] = GetTime() + 120
	self:UpdateIcon(sourceGUID, nil)
end