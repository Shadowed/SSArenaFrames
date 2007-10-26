--[[ 
	SSArena Frames By Amarand / Mayen (Horde) from Icecrown (US) PvE
]]

SSAF = DongleStub("Dongle-1.1"):New("SSAF")

local L = SSAFLocals
local CREATED_ROWS = 0
local TOTAL_CLICKIES = 10

local activeBF = -1
local maxPlayers = 0
local queuedUpdates = {}

local enemies = {}
local enemyPets = {}

local PartySlain
local SelfSlain

local AEIEnabled
local TattleEnabled
local RemembranceEnabled

local AceComm
local OptionHouse
local HouseAuthority
local SML

local petClassIcons = {
	["Voidwalker"] = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
	["Felhunter"] = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
	["Felguard"] = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
	["Succubus"] = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
	["Imp"] = "Interface\\Icons\\Spell_Shadow_SummonImp",
	["Cat"] = "Interface\\Icons\\Ability_Hunter_Pet_Cat",
	["Bat"] = "Interface\\Icons\\Ability_Hunter_Pet_Bat",
	["Bear"] = "Interface\\Icons\\Ability_Hunter_Pet_Bear",
	["Boar"] = "Interface\\Icons\\Ability_Hunter_Pet_Boar",
	["Crab"] = "Interface\\Icons\\Ability_Hunter_Pet_Crab",
	["Crocolisk"] = "Interface\\Icons\\Ability_Hunter_Pet_Crocolisk",
	["Dragonhawk"] = "Interface\\Icons\\Ability_Hunter_Pet_DragonHawk",
	["Gorilla"] = "Interface\\Icons\\Ability_Hunter_Pet_Gorilla",
	["Hyena"] = "Interface\\Icons\\Ability_Hunter_Pet_Hyena",
	["Netherray"] = "Interface\\Icons\\Ability_Hunter_Pet_NetherRay",
	["Owl"] = "Interface\\Icons\\Ability_Hunter_Pet_Owl",
	["Raptor"] = "Interface\\Icons\\Ability_Hunter_Pet_Raptor",
	["Ravager"] = "Interface\\Icons\\Ability_Hunter_Pet_Ravager",
	["Scorpid"] = "Interface\\Icons\\Ability_Hunter_Pet_Scorpid",
	["Spider"] = "Interface\\Icons\\Ability_Hunter_Pet_Spider",
	["Sporebat"] = "Interface\\Icons\\Ability_Hunter_Pet_Sporebat",
	["Tallstrider"] = "Interface\\Icons\\Ability_Hunter_Pet_TallStrider",
	["Turtle"] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
	["Vulture"] = "Interface\\Icons\\Ability_Hunter_Pet_Vulture",
	["Warp Stalker"] = "Interface\\Icons\\Ability_Hunter_Pet_WarpStalker",
	["Windserpent"] = "Interface\\Icons\\Ability_Hunter_Pet_WindSerpent",
	["Wolf"] = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
	[L["Water Elemental"]] = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2",
}

function SSAF:Initialize()
	self.defaults = {
		profile = {
			scale = 1.0,
			locked = true,
			showID = false,
			showIcon = false,
			showMinions = true,
			showPets = false,
			showTalents = true,
			reportEnemies = true,
			fontShadow = true,
			fontOutline = "NONE",
			healthTexture = "Interface\\TargetingFrame\\UI-StatusBar",
			fontColor = { r = 1.0, g = 1.0, b = 1.0 },
			petBarColor = { r = 0.20, g = 1.0, b = 0.20 },
			minionBarColor = { r = 0.30, g = 1.0, b = 0.30 },
			position = { x = 300, y = 600 },
			attributes = {
				-- Valid modifiers: shift, ctrl, alt
				-- LeftButton/RightButton/MiddleButton/Button4/Button5
				-- All numbered from left -> right as 1 -> 5
				{ enabled = true, classes = { ["ALL"] = true }, modifier = "", button = "", text = "/target *name" },
			}
		}
	}
	
	self.db = self:InitializeDB("SSAFDB", self.defaults)

	self.cmd = self:InitializeSlashCommand(L["SSArena Frames Slash Commands"], "SSAF", "ssaf", "arenaframes")
	self.cmd:InjectDBCommands(self.db, "delete", "copy", "list", "set")
	self.cmd:RegisterSlashHandler(L["ui - Pulls up the configuration page"], "ui", function() OptionHouse:Open("Arena Frames") end)

	-- Events we want active all the time
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	self:RegisterEvent("ADDON_LOADED")

	-- Party/We killed someone
	PartySlain = string.gsub(PARTYKILLOTHER, "%%s", "(.+)")
	SelfSlain = string.gsub(SELFKILLOTHER, "%%s", "(.+)")
		
	-- Register with OptionHouse
	OptionHouse = LibStub("OptionHouse-1.1")
	HouseAuthority = LibStub("HousingAuthority-1.2")
	
	local OHObj = OptionHouse:RegisterAddOn("Arena Frames", nil, "Amarand", "r" .. tonumber(string.match("$Revision: 252 $", "(%d+)") or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
	
	-- Yes, this is hackish because we're creating new widgets everytime you click the frame
	-- it'll require a change to HA which I need to get around to.
	OHObj:RegisterCategory(L["Click Actions"], self, "CreateClickListUI", true, 2)
	
	for i=1, TOTAL_CLICKIES do
		OHObj:RegisterSubCategory(L["Click Actions"], string.format(L["Action #%d"], i), self, "CreateAttributeUI", nil, i)
	end
	
	-- Register our default list of textures with SML
	SML = LibStub:GetLibrary("LibSharedMedia-2.0")
	SML:Register(SML.MediaType.STATUSBAR, "BantoBar", "Interface\\Addons\\SSArenaFrames\\images\\banto")
	SML:Register(SML.MediaType.STATUSBAR, "Smooth",   "Interface\\Addons\\SSArenaFrames\\images\\smooth")
	SML:Register(SML.MediaType.STATUSBAR, "Perl",     "Interface\\Addons\\SSArenaFrames\\images\\perl")
	SML:Register(SML.MediaType.STATUSBAR, "Glaze",    "Interface\\Addons\\SSArenaFrames\\images\\glaze")
	SML:Register(SML.MediaType.STATUSBAR, "Charcoal", "Interface\\Addons\\SSArenaFrames\\images\\Charcoal")
	SML:Register(SML.MediaType.STATUSBAR, "Otravi",   "Interface\\Addons\\SSArenaFrames\\images\\otravi")
	SML:Register(SML.MediaType.STATUSBAR, "Striped",  "Interface\\Addons\\SSArenaFrames\\images\\striped")
	SML:Register(SML.MediaType.STATUSBAR, "LiteStep", "Interface\\Addons\\SSArenaFrames\\images\\LiteStep")
end

function SSAF:JoinedArena()
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
	
	self:RegisterMessage("SS_ENEMY_DATA", "EnemyData")
	self:RegisterMessage("SS_ENEMYPET_DATA", "PetData")
	self:RegisterMessage("SS_ENEMYDIED_DATA", "EnemyDied")
		
	for i=CREATED_ROWS, 5 do
		self:CreateRow()
	end
	
	if( IsAddOnLoaded("ArenaEnemyInfo") ) then
		AEIEnabled = true
	elseif( IsAddOnLoaded("Tattle") ) then
		TattleEnabled = true
	end
	
	if( IsAddOnLoaded("Remembrance") ) then
		RemembranceEnabled = true
	end
end

function SSAF:LeftArena()
	self:UnregisterOOCUpdate("UpdateEnemies")

	if( InCombatLockdown() ) then
		self:RegisterOOCUpdate("ClearEnemies")
	else
		self:ClearEnemies()
	end
	
	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	self:RegisterEvent("ADDON_LOADED")
end

-- It's possible to mouseover an "enemy" when they're zoning in, so clear it just to be safe
function SSAF:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, message)
	if( message == L["The Arena battle has begun!"] ) then
		self:ClearEnemies()
	end
end

-- Set up bindings
function SSAF:UpdateBindings()
	if( not self.frame ) then
		return
	end
	
	for i=1, CREATED_ROWS do
		local bindKey = GetBindingKey("ARENATAR" .. i)
				
		if( bindKey ) then
			SetOverrideBindingClick(self.rows[i].button, false, bindKey, self.rows[i].button:GetName())	
		else
			ClearOverrideBindings(self.rows[i].button)
		end
	end
end


-- Grabs the data from the name
function SSAF:GetDataFromName(name)
	for _, enemy in pairs(enemies) do
		if( enemy.name == name ) then
			return enemy
		end
	end
	
	return nil
end

-- Check if an enemy died
function SSAF:CHAT_MSG_COMBAT_HOSTILE_DEATH(event, msg)
	-- Check if someone in our party killed them
	if( string.match(msg, PartySlain) ) then
		local died = string.match(msg, PartySlain)

		self:EnemyDied(event, died)		
		self:SendMessage("ENEMYDIED:" .. died)

	-- Check if we killed them
	elseif( string.match(msg, SelfSlain) ) then
		local died = string.match(msg, SelfSlain)

		self:EnemyDied(event, died)
		self:SendMessage("ENEMYDIED:" .. died)
	end
end

-- Updates all the health info!
function SSAF:UpdateHealth(enemy, health, maxHealth)
	-- No data passed (Bad) return quickly
	if( not enemy ) then
		return
	end
	
	local row, id
	for i=1, CREATED_ROWS do
		if( self.rows[i].ownerName == enemy.name ) then
			row = self.rows[i]
			id = i
			break
		end
	end
	
	-- Unable to find them on the frame, so don't update
	if( not id ) then
		return
	end
	
	-- Max health changed (Never really should happen)
	if( enemy.maxHealth ~= maxHealth ) then
		row:SetMinMaxValues(0, maxHealth)
		enemy.maxHealth = maxHealth
	end
	
	enemy.health = health or enemy.health
	if( enemy.health == 0 ) then
		enemy.isDead = true
	end

	self:UpdateRow(enemy, id)
end

-- Health update, check if it's one of our guys
function SSAF:UNIT_HEALTH(event, unit)
	if( unit == "focus" or unit == "target" ) then
		self:UpdateHealth(self:GetDataFromName(UnitName(unit)), UnitHealth(unit), UnitHealthMax(unit))
	end
end

-- Basically this handles things that change mid combat
-- like health or dying
function SSAF:UpdateRow(enemy, id)
	self.rows[id]:SetValue(enemy.health)
	self.rows[id].healthText:SetText(math.floor((enemy.health / enemy.maxHealth) * 100 + 0.5) .. "%")
	
	if( enemy.isDead ) then
		self.rows[id]:SetAlpha(0.75)
	else
		self.rows[id]:SetAlpha(1.0)
	end
end

-- Update the entire frame and everything in it
function SSAF:UpdateEnemies()
	if( not self.frame ) then
		self:CreateFrame()
	end
	
	-- Can't update in combat of course
	if( InCombatLockdown() ) then
		self:RegisterOOCUpdate("UpdateEnemies")
		return
	end
		
	local id = 0

	-- Update enemy players
	for _, enemy in pairs(enemies) do
		id = id + 1
		if( not self.rows[id] ) then
			self:CreateRow()
		end

		local row = self.rows[id]
		
		-- Players name
		local name = enemy.name
		
		-- Enemy talents
		if( self.db.profile.showTalents ) then
			local found
			if( AEIEnabled ) then
				local data = AEI:GetSpec(enemy.name, enemy.server)
				if( data ~= "" ) then
					found = true
					name = "|cffffffff" .. data .. "|r " .. name
				end
				
			elseif( TattleEnabled ) then
				local data = Tattle:GetPlayerData(enemy.name, enemy.server)
				if( data ) then
					found = true
					name = "|cffffffff[" .. data.tree1 .. "/" .. data.tree2 .. "/" .. data.tree3 .. "]|r " .. name
				end
			end
			
			if( RemembranceEnabled and not found ) then
				local tree1, tree2, tree3 = Remembrance:GetTalents(enemy.name, enemy.server)
				if( tree1 and tree2 and tree3 ) then
					name = "|cffffffff[" .. tree1 .. "/" .. tree2 .. "/" .. tree3 .. "]|r " .. name
				end
			end
		end
		
		-- Enemy ID
		if( self.db.profile.showID ) then
			name = "|cffffffff" .. id .. "|r " .. name
		end
			
		row.text:SetText(name)
		row.ownerName = enemy.name
				
		-- Word wrap
		if( row.text:GetStringWidth() >= 145 ) then
			row.text:SetWidth(145)
		else
			row.text:SetWidth(row.text:GetStringWidth())
		end
				
		-- Show class icon to the left of the players name
		if( self.db.profile.showIcon ) then
			local coords = CLASS_BUTTONS[enemy.classToken]

			row.classTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			row.classTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			row.classTexture:Show()
		else
			row.classTexture:Hide()
		end
		
		row:SetMinMaxValues(0, enemy.maxHealth)
		row:SetStatusBarColor(RAID_CLASS_COLORS[enemy.classToken].r, RAID_CLASS_COLORS[enemy.classToken].g, RAID_CLASS_COLORS[enemy.classToken].b, 1.0)
		
		-- Now do a quick basic update of other info
		self:UpdateRow(enemy, id)
		
		-- Set up all the macro things
		local foundMacro
		for _, macro in pairs(self.db.profile.attributes) do
			if( macro.enabled and ( macro.classes.ALL or macro.classes[enemy.classToken] ) ) then
				foundMacro = true
				row.button:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
				row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", enemy.name))
			end
		end
		
		-- Make sure we always have at least one macro to target
		if( not foundMacro ) then
			row.button:SetAttribute("type", "macro")
			row.button:SetAttribute("macrotext", "/target " .. enemy.name)
		end
		
		row:Show()
	end
	
	-- Update enemy pets
	for _, enemy in pairs(enemyPets) do
		if( ( enemy.petType == "MINION" and self.db.profile.showMinions ) or ( enemy.petType == "PET" and self.db.profile.showPets ) ) then
			id = id + 1
			if( not self.rows[id] ) then
				self:CreateRow()
			end

			local row = self.rows[id]

			local name = string.format(L["%s's %s"], enemy.owner, (enemy.family or enemy.name))
			if( self.db.profile.showID ) then
				name = "|cffffffff" .. id .. "|r " .. name
			end

			row.text:SetText(name)
			row.ownerName = nil

			row.classTexture:Hide()

			row:SetMinMaxValues(0, enemy.maxHealth)
			
			if( enemy.petType == "PET" ) then
				row:SetStatusBarColor(self.db.profile.petBarColor.r, self.db.profile.petBarColor.g, self.db.profile.petBarColor.b, 1.0)
			elseif( enemy.petType == "MINION" ) then
				row:SetStatusBarColor(self.db.profile.minionBarColor.r, self.db.profile.minionBarColor.g, self.db.profile.minionBarColor.b, 1.0)
			end

			-- Quick update
			self:UpdateRow(enemy, id)

			-- Show pet type
			if( self.db.profile.showIcon ) then
				local path = petClassIcons[enemy.family or enemy.name]
				if( path ) then
					row.classTexture:SetTexture(path)
				else
					row.classTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
					row.classTexture:SetTexCoord(0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0)
				end

				row.classTexture:Show()
			else
				row.classTexture:Hide()
			end

			-- Set up all the macro things
			local foundMacro
			for _, macro in pairs(self.db.profile.attributes) do
				if( macro.enabled and ( macro.classes.ALL or macro.classes[enemy.petType] ) ) then
					row.button:SetAttribute(macro.modifier .. "type" .. macro.button, "macro")
					row.button:SetAttribute(macro.modifier .. "macrotext" .. macro.button, string.gsub(macro.text, "*name", enemy.name))

					foundMacro = true
				end
			end
			
			-- Make sure we always have at least one macro to target
			if( not foundMacro ) then
				row.button:SetAttribute("type", "macro")
				row.button:SetAttribute("macrotext", "/target " .. enemy.name)
			end

			row:Show()
		end
	end
	
	-- Nothing displayed, hide frame
	if( id == 0 ) then
		self.frame:Hide()
		return
	end
	
	self.frame:SetHeight(18 * id)
	self.frame:Show()
end

-- Quick redirects!
function SSAF:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function SSAF:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function SSAF:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

-- Sort the enemies by the sortID thing
local function sortEnemies(a, b)
	if( not b ) then
		return false
	end
	
	return ( a.sortID < b.sortID )
end

-- Scan unit, see if they're valid as an enemy or enemy pet
function SSAF:ScanUnit(unit)
	-- 1) Roll a Priest with the name Unknown
	-- 2) Join an arena team
	-- 3) ????
	-- 4) Profit! Because all arena mods check for the name "Unknown" before exiting
	local name, server = UnitName(unit)
	if( name == UNKNOWNOBJECT or not UnitIsEnemy("player", unit) ) then
		return
	end

	if( UnitIsPlayer(unit) ) then
		server = server or GetRealmName()
		
		for _, player in pairs(enemies) do
			if( player.name == name and player.server == server ) then
				return
			end
		end
		
		local race = UnitRace(unit)
		local class, classToken = UnitClass(unit)
		local guild = GetGuildInfo(unit)
		
		table.insert(enemies, {sortID = name .. "-" .. server, name = name, server = server, race = race, class = class, classToken = classToken, guild = guild, health = UnitHealth(unit), maxHealth = UnitHealthMax(unit) or 100})
		
		if( guild ) then
			if( self.db.profile.reportEnemies ) then
				self:ChannelMessage(string.format(L["[%d/%d] %s / %s / %s / %s / %s"], #(enemies), maxPlayers, name, server, race, class, guild))
			end
			
			self:SendMessage("ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken .. "," .. guild)
		else
			if( self.db.profile.reportEnemies ) then
				self:ChannelMessage(string.format(L["[%d/%d] %s / %s / %s / %s"], #(enemies), maxPlayers, name, server, race, class))
			end
			
			self:SendMessage("ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken)
		end
		
		table.sort(enemies, sortEnemies)
		self:UpdateEnemies()
		
	-- Hunter pet, or Warlock/Mage minion
	elseif( UnitCreatureFamily(unit) or name == L["Water Elemental"] ) then
		-- Need to find the pets owner
		if( not self.tooltip ) then
			self.tooltip = CreateFrame("GameTooltip", "SSArenaTooltip", UIParent, "GameTooltipTemplate")
			self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		end
		
		self.tooltip:SetUnit(unit)
		
		-- Exit quickly, no data found
		if( self.tooltip:NumLines() == 0 ) then
			return
		end
		
		-- Warlock/Mage
		local type = "MINION"
		local owner = string.match(SSArenaTooltipTextLeft2:GetText(), L["([a-zA-Z]+)%'s Minion"])
		
		-- Hunters
		if( not owner ) then
			owner = string.match(SSArenaTooltipTextLeft2:GetText(), L["([a-zA-Z]+)%'s Pet"])
			type = "PET"
		end
		
		-- Found the pet owner
		if( owner and owner ~= L["Unknown"] ) then
			local family = UnitCreatureFamily(unit)
			for i=#(enemyPets), 1, -1 do
				if( enemyPets[i].owner == owner ) then
					-- Check to see if the pet changed
					if( enemyPets[i].name ~= name ) then
						table.remove(enemyPets, i)
						break
					else
						return
					end
				end
			end
			
			
			table.insert(enemyPets, {sortID = name .. "-" .. owner, name = name, owner = owner, family = family, petType = type, health = UnitHealth(unit), maxHealth = UnitHealthMax(unit) or 100})
			
			if( family ) then
				if( self.db.profile.reportEnemies ) then
					SSPVP:ChannelMessage(string.format( L["[%d/%d] %s's pet, %s %s"], #(enemyPets), SSPVP:MaxBattlefieldPlayers(), owner, name, family))
				end
				
				self:SendMessage("ENEMYPET:" .. name .. "," .. owner .. "," .. family .. "," .. type)
			else
				if( self.db.profile.reportEnemies ) then
					SSPVP:ChannelMessage(string.format(L["[%d/%d] %s's pet, %s"], #(enemyPets), SSPVP:MaxBattlefieldPlayers(), owner, name))
				end
				
				self:SendMessage("ENEMYPET:" .. name .. "," .. owner)
			end
			
			table.sort(enemyPets, sortEnemies)
			self:UpdateEnemies()
		end
	end
end

-- Health value updated, rescan our saved enemies
local function healthValueChanged(...)
	if( activeBF == -1 ) then
		return
	end
	
	local ownerName = select(5, this:GetParent():GetRegions()):GetText()

	SSAF:UpdateHealth(SSAF:GetDataFromName(ownerName), value, select(2, this:GetMinMaxValues()))

	if( this.SSValueChanged ) then
		this.SSValueChanged(...)
	end
end

-- Find unhooked anonymous frames
local function findUnhookedNameplates(...)
	for i=1, select("#", ...) do
		local health = select(i, ...)
		if( health and not health.SSAFHooked and not health:GetName() and health:IsVisible() and health.GetFrameType and health:GetFrameType() == "StatusBar" ) then
			return health
		end
	end
end

-- Scan WorldFrame children
local function scanFrames(...)
	for i=1, select("#", ...) do
		local health = findUnhookedNameplates(select( i, ...):GetChildren())
		if( health ) then
			health.SSAFHooked = true
			health.SSValueChanged = health:GetScript("OnValueChanged")
			health:SetScript("OnValueChanged", healthValueChanged)
		end
	end
end

-- Syncing
function SSAF:EnemyData(event, name, server, race, classToken, guild)
	for _, enemy in pairs(enemies) do
		if( not enemy.owner and enemy.name == name ) then
			return
		end
	end
	
	server = server or ""

	table.insert(enemies, {sortID = name .. "-" .. server, name = name, health = 100, maxHealth = 100, server = server, race = race, classToken = classToken, guild = guild})
	self:UpdateEnemies()
end

-- New pet found
function SSAF:PetData(event, name, owner, family)
	if( not self.db.profile.showPets ) then
		return
	end
	
	for _, enemy in pairs(enemyPets) do
		if( enemy.owner == owner and enemy.name == name ) then
			return
		end
	end
	
	-- These is mainly for backwards compatability

	-- Water Elementals have no family
	-- We don't pass pet type for Water Elementals, because then we have issues
	-- with family being "" not nil, too many sanity issues.
	if( name == L["Water Elemental"] ) then
		type = "MINION"

	-- Warlock pets
	elseif( not type and ( family == "Felguard" or family == "Felhunter" or family == "Imp" or family == "Felguard" or family == "Succubus" ) ) then
		type = "MINION"
	
	-- Hunter pets
	elseif( not type ) then
		type = "PET"
	end

	table.insert(enemyPets, {sortID = name .. "-" .. owner, name = name, owner = owner, petType = type, family = family, health = 100, maxHealth = 100})
	self:UpdateEnemies()
end

-- Someone died, update them to actually be dead
function SSAF:EnemyDied(event, name)
	for id, enemy in pairs(enemies) do
		if( not enemy.isDead and enemy.name == name ) then
			enemy.isDead = true
			enemy.health = 0
			self:UpdateRow(enemy, id)
			break
		end
	end
end


-- Create the master frame to hold everything
function SSAF:CreateFrame()
	if( self.frame ) then
		return
	end
	
	if( InCombatLockdown() ) then
		self:RegisterOOCUpdate("CreateFrame")
		return
	end
	
	self.frame = CreateFrame("Frame")
	self.frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.6,
		insets = {left = 1, right = 1, top = 1, bottom = 1}})

	self.frame:SetBackdropColor(0, 0, 0, 1.0)
	self.frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.frame:SetScale(self.db.profile.scale)
	self.frame:SetWidth(180)
	self.frame:SetMovable(true)
	--self.frame:SetMovable(not self.db.profile.locked)
	self.frame:EnableMouse(not self.db.profile.locked)
	self.frame:SetClampedToScreen(true)

	-- Moving the frame
	self.frame:SetScript("OnMouseDown", function(self)
		if( not SSAF.db.profile.locked ) then
			self.isMoving = true
			self:StartMoving()
		end
	end)

	self.frame:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			self:StopMovingOrSizing()

			SSAF.db.profile.position.x = self:GetLeft()
			SSAF.db.profile.position.y = self:GetTop()
		end
	end)	
	
	-- Health monitoring
	local timeElapsed = 0
	local numChildren = -1;
	self.frame:SetScript("OnUpdate", function(self, elapsed)
		-- When number of children changes, 99% of the time it's
		-- due to a new nameplate being added
		if( WorldFrame:GetNumChildren() ~= numChildren ) then
			numChildren = WorldFrame:GetNumChildren()
			scanFrames(WorldFrame:GetChildren())
		end
		
		-- Scan party targets every 1 second
		-- Really, nameplate scanning should get the info 99% of the time
		-- so we don't need to be so aggressive with this
		timeElapsed = timeElapsed + elapsed
		if( timeElapsed >= 1 ) then
			for i=1, GetNumPartyMembers() do
				if( UnitExists("party" .. i .. "target" ) ) then
					SSAF:UpdateHealth(SSAF:GetDataFromName(UnitName("party" .. i .. "target")), UnitHealth("party" .. i .. "target"), UnitHealthMax("party" .. i .. "target"))
				end
			end
		end
	end)
	
	-- Position to last saved area
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.position.x, self.db.profile.position.y)

	self.rows = {}
end

-- Create a single row
function SSAF:CreateRow()
	if( InCombatLockdown() ) then
		return
	end

	if( not self.frame ) then
		self:CreateFrame()
	end
	
	CREATED_ROWS = CREATED_ROWS + 1
	local id = CREATED_ROWS
	
	-- Health bar
	local row = CreateFrame("StatusBar", nil, self.frame)
	row:SetHeight(16)
	row:SetWidth(178)
	row:SetStatusBarTexture(self.db.profile.healthTexture)
	row:Hide()
	
	local path, size = GameFontNormalSmall:GetFont()

	-- Player name text
	local text = row:CreateFontString(nil, "OVERLAY")
	text:SetPoint("LEFT", row, "LEFT", 1, 0)
	text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)

	if( self.db.profile.fontOutline == "NONE" ) then
		text:SetFont(path, size)
	else
		text:SetFont(path, size, self.db.profile.fontOutline)
	end
	
	if( self.db.profile.fontShadow ) then
		text:SetShadowOffset(1, -1)
		text:SetShadowColor(0, 0, 0, 1)
	else
		text:SetShadowOffset(0, 0)
		text:SetShadowColor(0, 0, 0, 0)
	end
	
	-- Health percent text
	local healthText = row:CreateFontString(nil, "OVERLAY")
	healthText:SetPoint("RIGHT", row, "RIGHT", -1, 0)
	healthText:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	
	if( self.db.profile.fontOutline == "NONE" ) then
		healthText:SetFont(path, size)
	else
		healthText:SetFont(path, size, self.db.profile.fontOutline)
	end
	
	if( self.db.profile.fontShadow ) then
		healthText:SetShadowOffset(1, -1)
		healthText:SetShadowColor(0, 0, 0, 1)
	else
		healthText:SetShadowOffset(0, 0)
		healthText:SetShadowColor(0, 0, 0, 0)
	end

	-- Class icon
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(16)
	texture:SetWidth(16)
	texture:SetPoint("CENTER", row, "LEFT", -12, 0)
	
	-- So we can actually run macro text
	local button = CreateFrame("Button", "SSArenaButton" .. id, row, "SecureActionButtonTemplate")
	button:SetHeight(16)
	button:SetWidth(179)
	button:SetPoint("LEFT", row, "LEFT", 1, 0)
	button:EnableMouse(self.db.profile.locked)
	
	-- Position
	if( id > 1 ) then
		row:SetPoint("TOPLEFT", self.rows[id - 1], "BOTTOMLEFT", 0, -2)
	else
		row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
	end

	self.rows[id] = row
	self.rows[id].text = text
	self.rows[id].classTexture = texture
	self.rows[id].button = button
	self.rows[id].healthText = healthText
	
	-- Add key bindings
	local bindKey = GetBindingKey("ARENATAR" .. id)

	if( bindKey ) then
		SetOverrideBindingClick(self.rows[id].button, false, bindKey, self.rows[id].button:GetName())	
	else
		ClearOverrideBindings(self.rows[id].button)
	end
end

-- Deal with the fact that a few arena mods doesn't send class tokens
function SSAF:TranslateClass(class)
	for classToken, className in pairs(L["CLASSES"]) do
		if( className == class ) then
			return classToken
		end
	end
	
	return nil
end

-- Deal with the stupid people using memo
function SSAF:ADDON_LOADED(event, addon)
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
			SSAF:EnemyData(event, name, nil, nil, class)
		end
		
		-- Gladiator
		function AceComm.OnCommReceive:Add(prefix, sender, distribution, name, class, health, talents)
			SSAF:EnemyData(event, name, nil, nil, class)
		end

		-- Proximo
		function AceComm.OnCommReceive:ReceiveSync(prefix, sender, distribution, name, class, health, mana)
			SSAF:EnemyData(event, name, nil, nil, SSAF:TranslateClass(class))
		end
	end
end

-- Sync with other addons
function SSAF:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( author == UnitName("player") ) then
		return
	end

	-- SSPVP/SSArena Frames
	if( prefix == "SSAF" or prefix == "SSPVP" ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( dataType ) then
			self:TriggerMessage("SS_" .. dataType .. "_DATA", string.split(",", data))
		end
	
	-- Arena Master
	elseif( prefix == "ArenaMaster" ) then
		local name, class = string.split(" ", msg)
		self:EnemyData(event, name, nil, nil, string.upper(class))
	
	-- Arena Live Frames
	elseif( prefix == "ALF_T" ) then
		local name, class = string.split( ",", msg )
		self:EnemyData(event, name, nil, nil, self:TranslateClass(class))
	
	-- Arena Unit Frames
	elseif( prefix == "ArenaUnitFrames" ) then
		local _, name, class = string.split(",", msg)
		self:EnemyData(event, name, nil, nil, class)
	end
end

-- Are we inside an arena?
function SSAF:UPDATE_BATTLEFIELD_STATUS()
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, id, _, _, teamSize, registeredMatch = GetBattlefieldStatus(i)
		if( teamSize > 0 and status == "active" and i ~= activeBF ) then
			activeBF = i
			maxPlayers = teamSize
			self:JoinedArena()

		elseif( teamSize > 0 and status ~= "active" and i == activeBF ) then
			activeBF = -1
			maxPlayers = 0
			self:LeftArena()
		end
	end
end

-- Update queued frames
function SSAF:PLAYER_REGEN_ENABLED()
	for func in pairs(queuedUpdates) do
		self[func](self)
		queuedUpdates[func] = nil
	end
end

function SSAF:ChannelMessage(msg)
	SendChatMessage("[SS] " .. msg, "BATTLEGROUND")
end

-- So we can update secure things once we're OOC
function SSAF:UnregisterOOCUpdate(func)
	queuedUpdates[func] = nil
end

function SSAF:RegisterOOCUpdate(func)
	queuedUpdates[func] = true
end

-- Quick code for syncing
function SSAF:SendMessage(msg, type)
	SendAddonMessage("SSAF", msg, "BATTLEGROUND")
end

-- Something in configuration changed
function SSAF:Reload()
	if( not self.db.profile.locked ) then
		if( #(enemies) == 0 and #(enemyPets) == 0 ) then
			table.insert(enemies, {sortID = "", name = UnitName("player"), server = GetRealmName(), race = UnitRace("player"), class = UnitClass("player"), classToken = select(2, UnitClass("player")), health = UnitHealth("player"), maxHealth = UnitHealthMax("player")})
			table.insert(enemyPets, {sortID = "", name = L["Pet"], owner = UnitName("player"), health = UnitHealth("player"), petType = "PET", family = "Cat", maxHealth = UnitHealthMax("player")})
			table.insert(enemyPets, {sortID = "", name = L["Minion"], owner = UnitName("player"), health = UnitHealth("player"), petType = "MINION", family = "Felhunter", maxHealth = UnitHealthMax("player")})

			self:UpdateEnemies()
		end
	elseif( #(enemies) == 1 and #(enemyPets) == 1 ) then
		self:ClearEnemies()
	end
	
	if( self.frame ) then
		self.frame:SetMovable(not self.db.profile.locked)
		self.frame:EnableMouse(not self.db.profile.locked)
		self.frame:SetScale(self.db.profile.scale)
	end
	
	local path, size = GameFontNormalSmall:GetFont()
	-- Update all the rows to the current settings
	for i=1, CREATED_ROWS do
		local row = self.rows[i]
		row.button:EnableMouse(self.db.profile.locked)
		row:Hide()
	
		-- Player name text
		local text = row.text
		text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)

		if( self.db.profile.fontOutline == "NONE" ) then
			text:SetFont(path, size)
		else
			text:SetFont(path, size, self.db.profile.fontOutline)
		end

		if( self.db.profile.fontShadow ) then
			text:SetShadowOffset(1, 0)
			text:SetShadowColor(0, 0, 0, 1)
		else
			text:SetShadowColor(0, 0, 0, 0)
		end

		local text = row.healthText
		text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)

		if( self.db.profile.fontOutline == "NONE" ) then
			text:SetFont(path, size)
		else
			text:SetFont(path, size, self.db.profile.fontOutline)
		end

		if( self.db.profile.fontShadow ) then
			text:SetShadowOffset(1, 0)
			text:SetShadowColor(0, 0, 0, 1)
		else
			text:SetShadowColor(0, 0, 0, 0)
		end
	end
	
	if( ( #(enemies) > 0 or #(enemyPets) > 0 ) ) then
		self:UpdateEnemies()
	end
end

function SSAF:ClearEnemies()
	for i=#(enemies), 1, -1 do
		table.remove(enemies, i)
	end
	for i=#(enemyPets), 1, -1 do
		table.remove(enemyPets, i)
	end
	
	if( self.rows ) then
		for i=1, CREATED_ROWS do
			self.rows[i].ownerName = nil
			self.rows[i]:Hide()
		end
	end
	
	if( self.frame ) then
		self.frame:Hide()
	end
end

-- GUI
function SSAF:Set(var, value)
	self.db.profile[var] = value
end

function SSAF:Get(var)
	return self.db.profile[var]
end

function SSAF:CreateUI()
	local textures = {}
	for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
		table.insert(textures, {SML:Fetch(SML.MediaType.STATUSBAR, name), name})
	end

	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Frame"], type = "groupOrder", order = 2 },
		{ group = L["Display"], type = "groupOrder", order = 3 },
		{ group = L["Color"], type = "groupOrder", order = 4 },
		
		{ group = L["General"], order = 1, text = L["Report enemies to battleground chat"], help = L["Sends name, server, class, race and guild to battleground chat when you mouse over or target an enemy."], type = "check", var = "reportEnemies"},
		{ group = L["General"], order = 2, text = L["Show row number"], help = L["Shows the row number next to the name, can be used in place of names for other SSAF/SSPVP users to identify enemies."], type = "check", var = "showID"},
		{ group = L["General"], order = 3, text = L["Show class icon"], help = L["Displays the players class icon to the left of the arena frame on their row."], type = "check", var = "showIcon"},
		{ group = L["General"], order = 4, text = L["Show enemy mage/warlock minions"], help = L["Will display Warlock and Mage minions in the arena frames below all the players."], type = "check", var = "showMinions"},
		{ group = L["General"], order = 5, text = L["Show enemy hunter pets"], help = L["Will display Hunter pets in the arena frames below all the players."], type = "check", var = "showPets"},
		{ group = L["General"], order = 6, text = L["Show talents when available"], help = L["Requires Remembrance, ArenaEnemyInfo or Tattle."], type = "check", var = "showTalents"},

		{ group = L["Display"], order = 1, text = L["Health bar texture"], type = "dropdown", list = textures, var = "healthTexture"},
		{ group = L["Display"], order = 2, text = L["Font outline"], type = "dropdown", list = {{"NONE", L["None"]}, {"OUTLINE", L["Outline"]}, {"THICKOUTLINE", L["Thick outline"]}}, var = "fontOutline"},
		{ group = L["Display"], order = 3, text = L["Show shadow under name/health text"], type = "check", var = "fontShadow"},

		{ group = L["Color"], order = 1, text = L["Pet health bar color"], type = "color", var = "petBarColor"},
		{ group = L["Color"], order = 2, text = L["Minion health bar color"], type = "color", var = "minionBarColor"},
		{ group = L["Color"], order = 3, text = L["Name/health font color"], type = "color", var = "fontColor"},
				
		{ group = L["Frame"], order = 1, text = L["Lock arena frame"], type = "check", var = "locked"},
		{ group = L["Frame"], order = 2, format = L["Frame Scale: %d%%"], min = 0.0, max = 2.0, type = "slider", var = "scale"}
	}

	-- Update the dropdown incase any new textures were added
	local frame = HouseAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = self})
	frame:Hide()
	frame:SetScript("OnShow", function(self)
		local textures = {}
		for _, name in pairs(SML:List(SML.MediaType.STATUSBAR)) do
			table.insert(textures, {SML:Fetch(SML.MediaType.STATUSBAR, name), name})
		end

		HouseAuthority:GetObject(self):UpdateDropdown({var = "healthTexture", list = textures})
	end)
	return frame
end

-- Listing click actions by class/binding/ect
local cachedFrame
function SSAF:OpenAttributeUI(var)
	OptionHouse:Open("Arena Frames", L["Click Actions"], string.format(L["Action #%d"], var))
end

function SSAF:CreateClickListUI()
	-- This lets us implement at least a basic level of caching
	if( cachedFrame ) then
		return
	end
	
	local config = {}
	
	for i=1, TOTAL_CLICKIES do
		local row = self.db.profile.attributes[i]
		if( row ) then
			local enabled = GREEN_FONT_COLOR_CODE .. L["Enabled"] .. FONT_COLOR_CODE_CLOSE
			if( not row.enabled ) then
				enabled = RED_FONT_COLOR_CODE .. L["Disabled"] .. FONT_COLOR_CODE_CLOSE
			end
			
			local key = row.modifier
			if( key == "" ) then
				key = L["All"]
			elseif( key == "ctrl-" ) then
				key = L["CTRL"]			
			elseif( key == "shift-" ) then
				key = L["SHIFT"]			
			elseif( key == "alt-" ) then
				key = L["ALT"]			
			end
			
			local mouse = row.button
			if( mouse == "" ) then
				mouse = L["Any button"]
			elseif( mouse == "1" ) then
				mouse = L["Left button"]
			elseif( mouse == "2" ) then
				mouse = L["Right button"]
			elseif( mouse == "3" ) then
				mouse = L["Middle button"]
			elseif( mouse == "4" ) then
				mouse = L["Button 4"]
			elseif( mouse == "5" ) then
				mouse = L["Button 5"]
			end
			
			-- Grab total classes enabled for this
			local total = 0
			for _, _ in pairs(row.classes) do
				total = total + 1
			end
			
			table.insert(config, { group = "#" .. i, text = enabled, type = "label", xPos = 5, yPos = 0, font = GameFontHighlightSmall })
			table.insert(config, { group = "#" .. i, text = L["Edit"], type = "button", onSet = "OpenAttributeUI", var = i})
			table.insert(config, { group = "#" .. i, text = string.format(L["Classes: %s"], total), type = "label", xPos = 50, yPos = 0, font = GameFontHighlightSmall })
			table.insert(config, { group = "#" .. i, text = string.format(L["Modifier: %s"], key), type = "label", xPos = 75, yPos = 0, font = GameFontHighlightSmall })
			table.insert(config, { group = "#" .. i, text = string.format(L["Mouse: %s"], mouse), type = "label", xPos = 100, yPos = 0, font = GameFontHighlightSmall })
		end
	end

	-- Update the dropdown incase any new textures were added
	cachedFrame = HouseAuthority:CreateConfiguration(config, {handler = self, columns = 5})
	
	return cachedFrame
end

-- Modifying click actions
function SSAF:AttribSet(var, value)
	cachedFrame = nil
	
	-- Not created yet, set to default
	if( not self.db.profile[var[1]][var[2]] ) then
		self.db.profile[var[1]][var[2]] = { enabled = false, classes = { ["ALL"] = true }, text = "/target *name", modifier = "", button = "" }
	end
	
	self.db.profile[var[1]][var[2]][var[3]] = value
end

function SSAF:AttribGet(var)
	-- Not created yet, set to default
	if( not self.db.profile[var[1]][var[2]] ) then
		cachedFrame = nil
		self.db.profile[var[1]][var[2]] = { enabled = false, classes = { ["ALL"] = true }, text = "/target *name", modifier = "", button = "" }
	end
	
	return self.db.profile[var[1]][var[2]][var[3]]
end

function SSAF:CreateAttributeUI(category, attributeID)
	attributeID = tonumber(string.match(attributeID, "(%d+)"))
	if( not attributeID ) then
		return
	end

	local classes = {}
	table.insert(classes, {"ALL", L["All"]})
	table.insert(classes, {"PET", L["Pet"]})
	table.insert(classes, {"MINION", L["Minion"]})
	
	for k, v in pairs(L["CLASSES"]) do
		table.insert(classes, {k, v})
	end
		
	local config = {
		{ group = L["Enable"], text = L["Enable macro case"], help = L["Enables the macro text entered to be ran on the specified modifier key and mouse button combo."], default = false, type = "check", var = {"attributes", attributeID, "enabled"}},
		{ group = L["Enable"], text = L["Enable for class"], help = L["Enables the macro for a specific class, or for pets only."], default = "ALL", list = classes, multi = true, type = "dropdown", var = {"attributes", attributeID, "classes"}},
		{ group = L["Modifiers"], text = L["Modifier key"], type = "dropdown", list = {{"", L["All"]}, {"ctrl-", L["CTRL"]}, {"shift-", L["SHIFT"]}, {"alt-", L["ALT"]}}, default = "", var = {"attributes", attributeID, "modifier"}},
		{ group = L["Modifiers"], text = L["Mouse button"], type = "dropdown", list = {{"", L["Any button"]}, {"1", L["Left button"]}, {"2", L["Right button"]}, {"3", L["Middle button"]}, {"4", L["Button 4"]}, {"5", L["Button 5"]}}, default = "", var = {"attributes", attributeID, "button"}},
		{ group = L["Macro Text"], text = L["Command to execute when clicking the frame using the above modifier/mouse button"], type = "editbox", default = "/target *name", var = {"attributes", attributeID, "text"}},
	}
	
	return HouseAuthority:CreateConfiguration(config, {set = "AttribSet", get = "AttribGet", onSet = "Reload", handler = self})
end