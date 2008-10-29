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
			self:UpdateCast(unit, spell, rank, (endTime / 1000) - GetTime(), event)
		end
	end
end

function Cast:EventStopCast(event, unit)
	if( arenaUnits[unit] ) then
		self:StopCast(unit)
	end
end

function Cast:UpdateCast(unit, spell, rank, secondsLeft, event)
	local row = SSAF.rows[unit]
	local cast = row.cast
	
	if( event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" ) then
		if( cast:IsVisible() ) then
			if( not cast.isChannelled ) then
				cast.endSeconds = cast.endSeconds + secondsLeft
				cast.pushbackSeconds = cast.pushbackSeconds + secondsLeft
				cast.pushback = "+" .. cast.pushbackSeconds
				cast:SetMinMaxValues(0, cast.endSeconds)
			else
				cast.elapsed = cast.elapsed - secondsLeft
				cast.pushbackSeconds = cast.pushbackSeconds - secondsLeft
				cast.pushback = cast.pushbackSeconds
			end

			cast.lastUpdate = GetTime()
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
	cast.isChannelled = (event == "UNIT_SPELLCAST_CHANNEL_START")
	SSAF.modules.Frame:SetOnUpdate(cast)

	cast.elapsed = cast.isChannelled and secondsLeft or 0
	cast.endSeconds = secondsLeft
	cast.spellName = spell
	cast.spellRank = rank
	cast.pushback = ""
	cast.pushbackSeconds = 0
	cast.lastUpdate = GetTime()
	cast:SetMinMaxValues(0, cast.endSeconds)
	cast:SetValue(cast.elapsed)
	cast:SetAlpha(1.0)
	cast:Show()
	
	if( cast.isChannelled ) then
		cast:SetStatusBarColor(0.25, 0.25, 1.0)
	else
		cast:SetStatusBarColor(1.0, 0.7, 0.30)
	end
end

function Cast:StopCast(unit)
	SSAF.rows[unit].cast:Hide()
end