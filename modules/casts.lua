local Cast = SSAF:NewModule("Cast", "AceEvent-3.0")
local L = SSAFLocals
local arenaUnits
local castFuncs = {["UNIT_SPELLCAST_START"] = UnitCastingInfo, ["UNIT_SPELLCAST_DELAYED"] = UnitCastingInfo, ["UNIT_SPELLCAST_CHANNEL_START"] = UnitChannelInfo, ["UNIT_SPELLCAST_CHANNEL_UPDATE"] = UnitChannelInfo}
local FADE_TIME = 0.20

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

-- Cast OnUpdates
local function fadeOnUpdate(self, elapsed)
	self.fadeElapsed = self.fadeElapsed - elapsed
	self:SetAlpha(self.fadeElapsed / FADE_TIME)
	
	if( self.fadeElapsed <= 0 ) then
		self:Hide()
	end
end

local function castOnUpdate(self, elapsed)
	local time = GetTime()
	self.elapsed = self.elapsed + (time - self.lastUpdate)
	self.lastUpdate = time
	self:SetValue(self.elapsed)
	
	if( self.elapsed <= 0 ) then
		self.elapsed = 0
	end
	
	if( self.pushback == 0 ) then
		self.castTime:SetFormattedText("%.1f", self.endSeconds - self.elapsed)
	else
		self.castTime:SetFormattedText("|cffff0000%.1f|r %.1f", self.pushback, self.endSeconds - self.elapsed)
	end

	-- Cast finished, do a quick fade
	if( self.elapsed >= self.endSeconds ) then
		self.fadeElapsed = FADE_TIME
		self:SetScript("OnUpdate", fadeOnUpdate)
	end
end

local function channelOnUpdate(self, elapsed)
	local time = GetTime()
	self.elapsed = self.elapsed - (time - self.lastUpdate)
	self.lastUpdate = time
	self:SetValue(self.elapsed)

	if( self.elapsed <= 0 ) then
		self.elapsed = 0
	end

	if( self.pushback == 0 ) then
		self.castTime:SetFormattedText("%.1f", self.elapsed)
	else
		self.castTime:SetFormattedText("|cffff0000%.1f|r %.1f", self.pushback, self.elapsed)
	end

	-- Channel finished, do a quick fade
	if( self.elapsed <= 0 ) then
		self.fadeElapsed = FADE_TIME
		self:SetScript("OnUpdate", fadeOnUpdate)
	end
end

-- Cast started, or it was delayed
function Cast:EventUpdateCast(event, unit)
	if( arenaUnits[unit] ) then
		local spell, rank, _, _, startTime, endTime = castFuncs[event](unit)
		if( endTime ) then
			self:UpdateCast(unit, spell, rank, startTime, endTime, event)
		end
	end
end

-- Cast finished
function Cast:EventStopCast(event, unit)
	if( arenaUnits[unit] ) then
		local cast = SSAF.rows[unit].cast
		cast.fadeElapsed = FADE_TIME
		cast:SetStatusBarColor(1.0, 0.0, 0.0)
		cast:SetScript("OnUpdate", fadeOnUpdate)
		cast:SetMinMaxValues(0, 1)
		cast:SetValue(1)
	end
end

-- Cast interrupted
function Cast:EventInterruptCast(event, unit)
	if( arenaUnits[unit] ) then
		local cast = SSAF.rows[unit].cast
		cast.fadeElapsed = FADE_TIME + 0.10
		cast:SetStatusBarColor(1.0, 0.0, 0.0)
		cast:SetScript("OnUpdate", fadeOnUpdate)
		cast:SetMinMaxValues(0, 1)
		cast:SetValue(1)
	end
end

-- Update the actual bar
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
	cast:SetMinMaxValues(0, cast.endSeconds)
	cast:SetValue(cast.elapsed)
	cast:SetAlpha(1.0)
	
	if( cast.isChannelled ) then
		cast:SetStatusBarColor(0.25, 0.25, 1.0)
		cast:SetScript("OnUpdate", channelOnUpdate)
	else
		cast:SetStatusBarColor(1.0, 0.7, 0.30)
		cast:SetScript("OnUpdate", castOnUpdate)
	end
	
	cast:Show()
end