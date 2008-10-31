local Cast = SSAF:NewModule("Cast", "AceEvent-3.0")
local L = SSAFLocals
local arenaUnits
local castFuncs = {["UNIT_SPELLCAST_START"] = UnitCastingInfo, ["UNIT_SPELLCAST_DELAYED"] = UnitCastingInfo, ["UNIT_SPELLCAST_CHANNEL_START"] = UnitChannelInfo, ["UNIT_SPELLCAST_CHANNEL_UPDATE"] = UnitChannelInfo}

function Cast:Enable()
	arenaUnits = SSAF.arenaUnits
	
	self:RegisterEvent("UNIT_SPELLCAST_START", "EventUpdateCast")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "EventInterruptCast")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "EventUpdateCast")

	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "EventUpdateCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "EventStopCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_INTERRUPTED", "EventInterruptCast")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "EventUpdateCast")
end

function Cast:Disable()
	self:UnregisterAllEvents()
end

function Cast:EventUpdateCast(event, unit)
	if( arenaUnits[unit] ) then
		local spell, rank, _, _, startTime, endTime = castFuncs[event](unit)
		if( endTime ) then
			self:UpdateCast(unit, spell, rank, startTime, endTime, event)
		end
	end
end

function Cast:EventStopCast(event, unit)
	if( arenaUnits[unit] ) then
		SSAF.modules.Frame:SetCastFinished(SSAF.rows[unit].cast)
	end
end

function Cast:EventInterruptCast(event, unit)
	if( arenaUnits[unit] ) then
		SSAF.modules.Frame:SetCastFinished(SSAF.rows[unit].cast, true)
	end
end

function Cast:UpdateCast(unit, spell, rank, startTime, endTime, event)
	local row = SSAF.rows[unit]
	local cast = row.cast
	
	if( event == "UNIT_SPELLCAST_DELAYED" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" ) then
		if( cast:IsVisible() ) then
			-- For a channel, delay is a negative value so using plus is fine here
			local delay = ( startTime - cast.startTime ) / 1000
			if( not cast.isChannelled ) then
				cast.endSeconds = cast.endSeconds + delay
				cast:SetMinMaxValues(0, cast.endSeconds)
			else
				cast.elapsed = cast.elapsed + delay
			end

			cast.pushback = cast.pushback + delay
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
	
	local secondsLeft = (endTime / 1000) - GetTime()
	
	-- Setup cast info
	cast.isChannelled = (event == "UNIT_SPELLCAST_CHANNEL_START")
	cast.startTime = startTime
	cast.elapsed = cast.isChannelled and secondsLeft or 0
	cast.endSeconds = secondsLeft
	cast.spellName = spell
	cast.spellRank = rank
	cast.pushback = 0
	cast.lastUpdate = GetTime()
	
	SSAF.modules.Frame:SetCastType(cast)
	cast:SetMinMaxValues(0, cast.endSeconds)
	cast:SetValue(cast.elapsed)
	cast:SetAlpha(1.0)
	cast:Show()
end