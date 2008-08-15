local Sync = SSAF:NewModule("Sync", "AceEvent-3.0")
local L = SSAFLocals
local playerName

function Sync:EnableModule()
	self:RegisterEvent("CHAT_MSG_ADDON")
	playerName = UnitName("player")
end

function Sync:DisableModule()
	self:UnregisterAllEvents()
end

-- Sync with other addons
function Sync:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( author == playerName ) then
		return
	end

	-- SSArena Frames
	if( prefix == "SSAF" ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( dataType == "ENEMY" ) then
			local name, server, race, classToken, guild, powerType, talents, guid = string.split(",", data)
			SSAF:AddEnemy(name, server, race, classToken, guild, powerType, talents, guid or name)
		elseif( dataType == "ENEMYPET" ) then
			SSAF:AddEnemyPet(string.split(",", data))
		elseif( dataType == "ENEMYDIED" ) then
			SSAF:EnemyDied(string.split(",", data))
		end

	-- Proximo2
	elseif( prefix == "Proximo" ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( dataType == "ReceiveSync" ) then
			local name, server, classToken, race = string.split(",", data)
			SSAF:AddEnemy(name, server, race, classToken, nil, nil, nil, name)
		end

	-- Arena Master
	elseif( prefix == "ArenaMaster" ) then
		local name, class = string.split(" ", msg)
		SSAF:AddEnemy(name, nil, nil, string.upper(class), nil, nil, name)
	
	-- Arena Unit Frames
	elseif( prefix == "ArenaUnitFrames" ) then
		local _, name, class = string.split(",", msg)
		SSAF:AddEnemy(name, nil, nil, class, nil, nil, name)
	end
end
