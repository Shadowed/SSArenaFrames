local Cast = SSAF:NewModule("Cast", "AceEvent-3.0")
local L = SSAFLocals
local arenaUnits
local castFuncs = {["UNIT_SPELLCAST_START"] = UnitCastingInfo, ["UNIT_SPELLCAST_DELAYED"] = UnitCastingInfo, ["UNIT_SPELLCAST_CHANNEL_START"] = UnitChannelInfo, ["UNIT_SPELLCAST_CHANNEL_UPDATE"] = UnitChannelInfo}

function Cast:Enable()
	arenaUnits = SSAF.arenaUnits
	
	self:RegisterEvent("UNIT_SPELLCAST_START", "EventUpdateCast")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "EventUpdateCast")

	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "EventUpdateCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_INTERRUPTED", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "EventUpdateCast")
end

function Cast:Disable()
	self:UnregisterAllEvents()
end

function Cast:EventUpdateCast(event, unit)
	if( arenaUnits[unit] ) then
		local spell, rank, _, _, startTime, endTime = castFuncs[event](unit)
		if( endTime ) then
			self:UpdateCast(unit, spell, rank, (endTime / 1000) - GetTime(), event == "UNIT_SPELLCAST_DELAYED" and true or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" and true or nil)
		end
	end
end

function Cast:EventStopCast(event, unit)
	if( arenaUnits[unit] ) then
		self:StopCast(unit)
	end
end

function Cast:UpdateCast(unit, spell, rank, secondsLeft, isDelayed)
	local row = SSAF.rows[unit]
	if( isDelayed ) then
		if( row.cast:IsVisible() ) then
			row.cast.endSeconds = row.cast.endSeconds - secondsLeft
			row.cast.lastUpdate = GetTime()
		end
		return
	end
	
	-- Set casted spell
	if( rank ~= "" ) then
		row.castName:SetFormattedText("%s (%s)", spell, rank)
	else
		row.castName:SetText(spell)
	end

	-- Setup cast info
	row.cast.elapsed = 0
	row.cast.endSeconds = secondsLeft
	row.cast.spellName = spell
	row.cast.spellRank = rank
	row.cast.lastUpdate = GetTime()
	row.cast:SetMinMaxValues(0, secondsLeft)
	row.cast:SetValue(0)
	row.cast:Show()
end

function Cast:StopCast(unit)
	local row = SSAF.rows[unit]
	row.cast:Hide()
end