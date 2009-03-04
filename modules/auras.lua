local Aura = SSAF:NewModule("Aura", "AceEvent-3.0")
local L = SSAFLocals
local arenaUnits
local unitAuras = {}

function Aura:Enable()
	self:RegisterEvent("UNIT_AURA")

	arenaUnits = SSAF.arenaUnits
	
	-- Reset data
	for _, data in pairs(unitAuras) do
		for k in pairs(data) do
			data[k] = nil
		end
	end
end

function Aura:Disable()
	self:UnregisterAllEvents()
end

-- Monitor time left on an aura before hiding it
local function onUpdate(self, elapsed)
	local time = GetTime()
	self.secondsLeft = self.secondsLeft - (time - self.lastUpdate)
	self.lastUpdate = time
	
	if( self.secondsLeft <= 9.9 ) then
		self.auraTime:SetFormattedText("%.1f", self.secondsLeft)
	else
		self.auraTime:SetFormattedText("%d", self.secondsLeft)
	end
	
	-- Aura ran out, reset icon
	if( self.secondsLeft <= 0 ) then
		self.auraTime:Hide()
		self:SetScript("OnUpdate", nil)
		
		SSAF:SetCustomIcon(self, nil)
	end
end

-- Arena unit aura updated
function Aura:UNIT_AURA(event, unit)
	if( not arenaUnits[unit] ) then
		return
	end
		
	unitAuras[unit] = unitAuras[unit] or {}

	local icon, secondsLeft, startSeconds
	local priority = -1
	local row = SSAF.rows[unit]
	
	-- Scan debuffs
	local id = 1
	while( true ) do
		local name, rank, texture, count, debuffType, duration, endTime, isMine, isStealable = UnitDebuff(unit, id)
		if( not name ) then break end
				
		-- If priorities are equal, show the one thats going to break first, if a priority is higher show it regardless
		if( self.spells[name] and ( ( self.spells[name] == priority and endTime < secondsLeft ) or self.spells[name] > priority ) ) then
			icon = texture
			secondsLeft = endTime
			startSeconds = duration
			priority = self.spells[name]
		end
		
		id = id + 1
	end
	
	-- Do we have a new timer?
	if( icon and ( unitAuras[unit].icon ~= icon or unitAuras[unit].endTime ~= secondsLeft ) ) then
		SSAF:SetCustomIcon(row, icon)

		unitAuras[unit].icon = icon
		unitAuras[unit].endTime = secondsLeft
		unitAuras[unit].startSeconds = startSeconds

		-- Start the OnUpdate to monitor debuff
		local time = GetTime()
		row.lastUpdate = time
		row.secondsLeft = secondsLeft - GetTime()
		row.auraTime:Show()
		row:SetScript("OnUpdate", onUpdate)
		
	elseif( not icon and unitAuras[unit].icon ) then
		-- Hide the timer
		row.auraTime:Hide()
		row:SetScript("OnUpdate", nil)

		SSAF:SetCustomIcon(row, nil)
		unitAuras[unit].icon = nil
		unitAuras[unit].endTime = nil
	end
end

-- Spells to track
-- The number is the priority, higher priority spells are shown over lower priority
Aura.spells = {
	-- Psychic Scream
	[(GetSpellInfo(8122))] = 10,
	-- Fear
	[(GetSpellInfo(5782))] = 10,
	-- Howl of Terror
	[(GetSpellInfo(5484))] = 10,
	-- Scare Beast
	[(GetSpellInfo(1513))] = 10,

	-- Polymorph
	[(GetSpellInfo(118))] = 5,
	-- Hex
	[(GetSpellInfo(51514))] = 5,

	-- Freezing Trap
	[(GetSpellInfo(1499))] = 10,

	-- Sap
	[(GetSpellInfo(6770))] = 5,
	-- Cyclone
	[(GetSpellInfo(33786))] = 10,
	-- Hibernate
	[(GetSpellInfo(2637))] = 5,
	-- Blind
	[(GetSpellInfo(2094))] = 10,
}
