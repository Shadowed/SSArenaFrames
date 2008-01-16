local Sync = SSAF:NewModule("Sync", "AceEvent-3.0")
local L = SSAFLocals
local playerName

function Sync:EnableModule()
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("CHAT_MSG_ADDON")

	-- Check if it was loaded already
	self:ADDON_LOADED()
	
	playerName = UnitName("player")
end

function Sync:DisableModule()
	self:UnregisterAllEvents()
end

-- Deal with the fact that a few arena mods doesn't send class tokens
function Sync:TranslateClass(class)
	for classToken, className in pairs(L["CLASSES"]) do
		if( className == class ) then
			return classToken
		end
	end
	
	return nil
end

-- Deal with the stupid people using memo
function Sync:ADDON_LOADED(event, addon)
	if( not AceComm and AceLibrary and LibStub:GetLibrary("AceComm-2.0", true) ) then
		AceComm = AceLibrary("AceAddon-2.0"):new("AceComm-2.0")
		AceComm.OnCommReceive = {}
		AceComm:SetCommPrefix("SSAF")
		AceComm:RegisterComm("Gladiator", "BATTLEGROUND")
		AceComm:RegisterComm("Proximo", "GROUP")
		AceComm:RegisterComm("ControlArena", "GROUP")
		AceComm:RegisterMemoizations("Add", "Discover",
		"Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior",
		"DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "SHAMAN", "ROGUE", "WARLOCK", "WARRIOR")
		
		-- Arena mod #19634871
		function AceComm.OnCommReceive:Discover(prefix, sender, distribution, name, class, health)
			SSAF:AddEnemy(name, nil, nil, class)
		end
		
		-- Gladiator
		function AceComm.OnCommReceive:Add(prefix, sender, distribution, name, class, health, talents)
			SSAF:AddEnemy(name, nil, nil, class, nil, nil, talents)
		end

		-- Proximo
		function AceComm.OnCommReceive:ReceiveSync(prefix, sender, distribution, name, class, health, mana, talents)
			SSAF:AddEnemy(name, nil, nil, string.upper(class), nil, nil, talents)
		end
	end
end

-- Sync with other addons
function Sync:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	-- SSArena Frames
	if( prefix == "SSAF" ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( dataType == "ENEMY" ) then
			SSAF:AddEnemy(string.split(",", data))			
		elseif( dataType == "ENEMYPET" ) then
			SSAF:AddEnemyPet(string.split(",", data))
		elseif( dataType == "ENEMYDIED" ) then
			SSAF:EnemyDied(string.split(",", data))
		end
	
	-- Arena Master
	elseif( prefix == "ArenaMaster" ) then
		local name, class = string.split(" ", msg)
		SSAF:AddEnemy(name, nil, nil, string.upper(class))
	
	-- Arena Live Frames
	elseif( prefix == "ALF_T" ) then
		local name, class = string.split( ",", msg )
		SSAF:AddEnemy(name, nil, nil, self:TranslateClass(class))
	
	-- Arena Unit Frames
	elseif( prefix == "ArenaUnitFrames" ) then
		local _, name, class = string.split(",", msg)
		SSAF:AddEnemy(name, nil, nil, class)
	end
end
