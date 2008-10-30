local Frame = SSAF:NewModule("Frame", "AceEvent-3.0")
local L = SSAFLocals

local DOT_FIRSTROW = 11
local DOT_SECONDROW = 20
local FADE_TIME = 0.20
local SML

function Frame:OnInitialize()
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
end

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
	
	if( self.pushback == 0 ) then
		self.castTime:SetFormattedText("%.1f", self.endSeconds - self.elapsed)
	else
		self.castTime:SetFormattedText("|cffff0000%.1f|r %.1f", self.pushback, self.endSeconds - self.elapsed)
	end

	-- Cast finished, do a quick fade
	if( self.elapsed >= self.endSeconds ) then
		self.fadeElapsed = FADE_TIME
		self.castTime:SetFormattedText("|cffff0000%s|r %.1f", self.pushback, 0)
		self:SetScript("OnUpdate", fadeOnUpdate)
	end
end

local function channelOnUpdate(self, elapsed)
	local time = GetTime()
	self.elapsed = self.elapsed - (time - self.lastUpdate)
	self.lastUpdate = time
	self:SetValue(self.elapsed)

	if( self.pushback == 0 ) then
		self.castTime:SetFormattedText("%.1f", self.elapsed)
	else
		self.castTime:SetFormattedText("|cffff0000%.1f|r %.1f", self.pushback, self.elapsed)
	end

	-- Channel finished, do a quick fade
	if( self.elapsed <= 0 ) then
		self.fadeElapsed = FADE_TIME
		self.castTime:SetFormattedText("|cffff0000%s|r %.1f", self.pushback, 0)
		self:SetScript("OnUpdate", fadeOnUpdate)
	end
end

function Frame:SetCastType(cast)
	if( cast.isChannelled ) then
		cast:SetStatusBarColor(0.25, 0.25, 1.0)
		cast:SetScript("OnUpdate", channelOnUpdate)
	else
		cast:SetScript("OnUpdate", castOnUpdate)
		cast:SetStatusBarColor(1.0, 0.7, 0.30)
	end
end

function Frame:SetInterrupted(cast)
	cast.fadeElapsed = FADE_TIME + 0.10

	cast:SetScript("OnUpdate", fadeOnUpdate)
	cast:SetStatusBarColor(1.0, 0.0, 0.0)
	cast:SetMinMaxValues(0, 1)
	cast:SetValue(1)
end

-- Create the master frame to hold everything
local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeSize = 0.6,
		insets = {left = 1, right = 1, top = 1, bottom = 1}}
function Frame:CreateFrame()
	local self = SSAF
	if( self.frame ) then
		return
	end
	
	self.frame = CreateFrame("Frame", nil, UIParent)
	self.frame:SetScale(self.db.profile.scale)
	self.frame:SetWidth(180)
	self.frame:SetHeight(18)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(false)
	self.frame:SetClampedToScreen(true)
	self.frame:Hide()
	
	self.borderFrame = CreateFrame("Frame", nil, self.frame)
	self.borderFrame:SetClampedToScreen(true)
	self.borderFrame:SetBackdrop(backdrop)
	self.borderFrame:SetBackdropColor(0, 0, 0, 1.0)
	self.borderFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)

	-- Create our anchor for moving the frame
	self.anchor = CreateFrame("Frame", nil, UIParent)
	self.anchor:SetWidth(182)
	self.anchor:SetHeight(12)
	self.anchor:SetBackdrop(backdrop)
	self.anchor:SetBackdropColor(0, 0, 0, 1.0)
	self.anchor:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.anchor:SetClampedToScreen(true)
	self.anchor:SetScale(self.db.profile.scale)
	self.anchor:EnableMouse(true)
	self.anchor:ClearAllPoints()
	self.anchor:SetPoint("TOPLEFT", self.borderFrame, "TOPLEFT", 0, 20)
	self.anchor:SetScript("OnMouseDown", function(self)
		if( not SSAF.db.profile.locked and IsAltKeyDown() ) then
			self.isMoving = true
			SSAF.frame:StartMoving()
		end
	end)

	self.anchor:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			SSAF.frame:StopMovingOrSizing()
			
			local scale = SSAF.frame:GetEffectiveScale()
			SSAF.db.profile.position.x = SSAF.frame:GetLeft() * scale
			SSAF.db.profile.position.y = SSAF.frame:GetTop() * scale
		end
	end)	
	
	self.anchor:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:SetText(L["ALT + Drag to move the frame anchor."], nil, nil, nil, nil, 1)
	end)
	
	self.anchor:SetScript("OnLeave", function(self)
		GameTooltip:Hide()	
	end)
	
	self.anchor.text = self.anchor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.anchor.text:SetText(L["SSArena Frames"])
	self.anchor.text:SetPoint("CENTER", self.anchor, "CENTER")
	
	-- Hide anchor if locked
	if( self.db.profile.locked ) then
		self.anchor:Hide()
	end
	
	-- Health monitoring
	self.frame:SetScript("OnUpdate", updateFrame)
	
	-- Position to last saved area
	local x, y = self.db.profile.position.x, self.db.profile.position.y
	local scale = self.frame:GetEffectiveScale()
	
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
end

-- Create a single row
function Frame:CreateRow(id)
	local self = SSAF
	if( not self.frame ) then
		Frame:CreateFrame()
	end
		
	-- So we can actually run macro text
	local row = CreateFrame("Button", "SSArenaButton" .. id, self.frame, "SecureActionButtonTemplate")
	row:SetHeight(16) --16
	row:SetWidth(180)
	row:EnableMouse(true)
	row:RegisterForClicks("AnyUp")
	row:Hide()

	-- Health bar
	local health = CreateFrame("StatusBar", nil, row)
	health:SetHeight(18)
	health:SetWidth(1)
	health:SetPoint("TOPLEFT", row)
	health:SetPoint("TOPRIGHT", row)
	health:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	health:SetMinMaxValues(0, 100)
	
	-- Mana bar
	local mana = CreateFrame("StatusBar", nil, row)
	mana:SetWidth(1)
	mana:SetHeight(self.db.profile.manaBarHeight)
	mana:SetPoint("BOTTOMLEFT", health, 0, -self.db.profile.manaBarHeight)
	mana:SetPoint("BOTTOMRIGHT", health, 0, -self.db.profile.manaBarHeight)
	mana:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	mana:SetMinMaxValues(0, 100)
	
	if( not self.db.profile.showMana ) then
		mana:Hide()
	end

	-- Cast bar
	local offset = -12
	if( self.db.profile.showMana ) then
		offset = -self.db.profile.manaBarHeight - 12
	end
	
	local cast = CreateFrame("StatusBar", nil, row)
	cast:SetWidth(1)
	cast:SetHeight(12)
	cast:SetPoint("BOTTOMLEFT", health, 0, offset)
	cast:SetPoint("BOTTOMRIGHT", health, 0, offset)
	cast:SetScript("OnUpdate", castOnUpdate)
	cast:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	cast:SetStatusBarColor(1.0, 0.7, 0.0)
	cast:Hide()
	
	if( self.db.profile.showCast ) then
		row:SetHeight(27)
	end
	
	local path, size = GameFontNormalSmall:GetFont()

	-- Spell name text
	local castName = cast:CreateFontString(nil, "OVERLAY")
	castName:SetPoint("LEFT", cast, "LEFT", 1, 0)
	castName:SetJustifyH("LEFT")
	castName:SetFont(path, 10)
	castName:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	castName:SetShadowOffset(1, -1)
	castName:SetShadowColor(0, 0, 0, 1)
	castName:SetText("*")
	castName:SetWidth(145)
	castName:SetHeight(castName:GetStringHeight())
	
	-- Cast time
	local castTime = cast:CreateFontString(nil, "OVERLAY")
	castTime:SetPoint("RIGHT", cast, "RIGHT", -1, 0)
	castTime:SetJustifyH("RIGHT")
	castTime:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	castTime:SetFont(path, 10)
	castTime:SetShadowOffset(1, -1)
	castTime:SetShadowColor(0, 0, 0, 1)
	
	-- So we can access it from the OnUpdate easier
	cast.castName = castName
	cast.castTime = castTime

	-- Player name text
	local text = health:CreateFontString(nil, "OVERLAY")
	text:SetPoint("LEFT", health, "LEFT", 1, 0)
	text:SetJustifyH("LEFT")
	
	text:SetFont(path, size)
	text:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	
	text:SetShadowOffset(1, -1)
	text:SetShadowColor(0, 0, 0, 1)
	
	-- We have to do this for GetStringHeight() to actually return a useful value
	text:SetText("*")
	text:SetWidth(145)
	text:SetHeight(text:GetStringHeight())
	
	-- Health percent text
	local healthText = health:CreateFontString(nil, "OVERLAY")
	healthText:SetPoint("RIGHT", health, "RIGHT", -1, 0)
	healthText:SetJustifyH("RIGHT")
	
	healthText:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	healthText:SetFont(path, size)
	
	healthText:SetShadowOffset(1, -1)
	healthText:SetShadowColor(0, 0, 0, 1)

	-- Class icon
	local classTexture = row:CreateTexture(nil, "OVERLAY")
	classTexture:SetHeight(16)
	classTexture:SetWidth(16)
	classTexture:SetPoint("CENTER", health, "LEFT", -14, (id > 1 and -1 or 0))

	-- Pet icon
	local petTexture = row:CreateTexture(nil, "OVERLAY")
	petTexture:SetHeight(16)
	petTexture:SetWidth(16)
	petTexture:SetPoint("CENTER", health, "LEFT", -14, (id > 1 and -1 or 0))
		
	-- Add the "whos targeting us" buttons
	local targets = {}
	
	-- Top left
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", health, "RIGHT", DOT_FIRSTROW, 4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()
	
	targets[1] = texture

	-- Top right
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", health, "RIGHT", DOT_SECONDROW, 4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()

	targets[4] = texture

	-- Bottom left
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", health, "RIGHT", DOT_FIRSTROW, -4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()
	
	targets[2] = texture

	-- Bottom right
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", health, "RIGHT", DOT_SECONDROW, -4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()
	
	targets[3] = texture
	
	-- So we can access it else where
	row.targets = targets
	row.text = text
	row.mana = mana
	row.classTexture = classTexture
	row.petTexture = petTexture
	row.health = health
	row.healthText = healthText
	row.id = id
	row.cast = cast
	row.castName = castName
	row.castTime = castTime
	
	return row
end

function Frame:UpdateToTTextures(row, totalTargets)
	if( row.currentStyle == totalTargets ) then
		return
	end
	
	-- 1 dot
	if( totalTargets == 1 ) then
		row.targets[1]:SetHeight(16)
		row.targets[1]:SetWidth(16)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", 15, 4)

	-- 2 dots
	elseif( totalTargets == 2 ) then
		row.targets[1]:SetHeight(8)
		row.targets[1]:SetWidth(16)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", 15, 8)

		row.targets[2]:SetHeight(8)
		row.targets[2]:SetWidth(16)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", 15, 0)
	
	-- 3 dots
	elseif( totalTargets == 3 ) then
		row.targets[1]:SetWidth(8)
		row.targets[1]:SetHeight(8)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 8)

		row.targets[2]:SetWidth(8)
		row.targets[2]:SetHeight(8)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 0)

		row.targets[3]:SetWidth(8)
		row.targets[3]:SetHeight(16)
		row.targets[3]:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, 4)
	
	-- 4 dots
	else
		row.targets[1]:SetWidth(8)
		row.targets[1]:SetHeight(8)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 8)

		row.targets[2]:SetWidth(8)
		row.targets[2]:SetHeight(8)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 0)

		row.targets[3]:SetWidth(8)
		row.targets[3]:SetHeight(8)
		row.targets[3]:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, 0)
	end

	row.currentStyle = totalTargets
end
