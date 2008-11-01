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
		SSAF.modules.Frame:SetIconTimer(row, startSeconds, secondsLeft - GetTime())

		unitAuras[unit].icon = icon
		unitAuras[unit].endTime = secondsLeft
		unitAuras[unit].startSeconds = startSeconds
		
	elseif( not icon and unitAuras[unit].icon ) then
		SSAF:SetCustomIcon(row, nil)
		SSAF.modules.Frame:StopIconTimer(row)

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
