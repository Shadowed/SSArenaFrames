local Frame = SSAF:NewModule("Frame", "AceEvent-3.0")
local L = SSAFLocals

local DOT_FIRSTROW = 11
local DOT_SECONDROW = 20
local SML

function Frame:OnInitialize()
	SML = SSAF.SML
end

function Frame:UpdateToTTextures(row, totalTargets)
	if( row.currentStyle == totalTargets ) then
		return
	end
	
	-- 1 dot
	if( totalTargets == 1 ) then
		row.targets[1]:SetHeight(16)
		row.targets[1]:SetWidth(16)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", 15, 0)

	-- 2 dots
	elseif( totalTargets == 2 ) then
		row.targets[1]:SetHeight(8)
		row.targets[1]:SetWidth(16)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", 15, 4)

		row.targets[2]:SetHeight(8)
		row.targets[2]:SetWidth(16)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", 15, -4)
	
	-- 3 dots
	elseif( totalTargets == 3 ) then
		row.targets[1]:SetWidth(8)
		row.targets[1]:SetHeight(8)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 4)

		row.targets[2]:SetWidth(8)
		row.targets[2]:SetHeight(8)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, -4)

		row.targets[3]:SetWidth(8)
		row.targets[3]:SetHeight(16)
		row.targets[3]:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, 0)
	
	-- 4 dots
	else
		row.targets[1]:SetWidth(8)
		row.targets[1]:SetHeight(8)
		row.targets[1]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 4)

		row.targets[2]:SetWidth(8)
		row.targets[2]:SetHeight(8)
		row.targets[2]:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, -4)

		row.targets[3]:SetWidth(8)
		row.targets[3]:SetHeight(8)
		row.targets[3]:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, -4)
	end

	row.currentStyle = totalTargets
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
	
	self.frame = CreateFrame("Frame")
	self.frame:SetBackdrop(backdrop)
	self.frame:SetBackdropColor(0, 0, 0, 1.0)
	self.frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.frame:SetScale(self.db.profile.scale)
	self.frame:SetWidth(180)
	self.frame:SetHeight(18)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(false)
	self.frame:SetClampedToScreen(true)
	self.frame:Hide()

	-- Create our anchor for moving the frame
	self.anchor = CreateFrame("Frame")
	self.anchor:SetWidth(180)
	self.anchor:SetHeight(12)
	self.anchor:SetBackdrop(backdrop)
	self.anchor:SetBackdropColor(0, 0, 0, 1.0)
	self.anchor:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
	self.anchor:SetClampedToScreen(true)
	self.anchor:SetScale(self.db.profile.scale)
	self.anchor:EnableMouse(true)
	self.anchor:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 14)
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
	
	self.anchor.text = self.anchor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.anchor.text:SetText(L["SSArena Frames"])
	self.anchor.text:SetPoint("CENTER", self.anchor, "CENTER")
	
	-- Hide anchor if locked
	if( self.db.profile.locked ) then
		self.anchor:Hide()
	end
	
	-- Health monitoring
	self.frame:SetScript("OnUpdate", SSAF.ScanPartyTargets)
	
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
		
	-- Health bar
	local row = CreateFrame("StatusBar", nil, self.frame)
	row:SetHeight(16)
	row:SetWidth(178)
	row:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	row:Hide()
	
	-- Mana bar
	local mana = CreateFrame("StatusBar", nil, row)
	mana:SetWidth(178)
	mana:SetHeight(self.db.profile.manaBarHeight)
	mana:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	mana:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, -self.db.profile.manaBarHeight)
	
	if( not self.db.profile.manaBar ) then
		mana:Hide()
	end

	local path, size = GameFontNormalSmall:GetFont()

	-- Player name text
	local text = mana:CreateFontString(nil, "OVERLAY")
	text:SetPoint("LEFT", row, "LEFT", 1, 0)
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
	local healthText = mana:CreateFontString(nil, "OVERLAY")
	healthText:SetPoint("RIGHT", row, "RIGHT", -1, 0)
	healthText:SetJustifyH("RIGHT")
	
	healthText:SetTextColor(self.db.profile.fontColor.r, self.db.profile.fontColor.g, self.db.profile.fontColor.b)
	healthText:SetFont(path, size)
	
	healthText:SetShadowOffset(1, -1)
	healthText:SetShadowColor(0, 0, 0, 1)
	
	-- Reparent text so they'll show if mana bars are disabled
	if( not self.db.profile.manaBar ) then
		text:SetParent(row)
		healthText:SetParent(row)
	end

	-- Class icon
	local classTexture = row:CreateTexture(nil, "OVERLAY")
	classTexture:SetHeight(16)
	classTexture:SetWidth(16)
	classTexture:SetPoint("CENTER", row, "LEFT", -12, 0)

	-- Pet icon
	local petTexture = row:CreateTexture(nil, "OVERLAY")
	petTexture:SetHeight(16)
	petTexture:SetWidth(16)
	petTexture:SetPoint("CENTER", row, "LEFT", -12, 0)
	
	-- So we can actually run macro text
	local button = CreateFrame("Button", "SSArenaButton" .. id, row, "SecureActionButtonTemplate")
	button:SetHeight(16)
	button:SetWidth(179)
	button:SetPoint("LEFT", row, "LEFT", 1, 0)
	button:EnableMouse(true)
	button:RegisterForClicks("AnyUp")
		
	-- Add the "whos targeting us" buttons
	local targets = {}
	
	-- Top left
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, 4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()
	
	targets[1] = texture

	-- Top right
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, 4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()

	targets[4] = texture

	-- Bottom left
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_FIRSTROW, -4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()
	
	targets[2] = texture

	-- Bottom right
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(8)
	texture:SetWidth(8)
	texture:SetPoint("CENTER", row, "RIGHT", DOT_SECONDROW, -4)
	texture:SetTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile.barTexture))
	texture:Hide()
	
	targets[3] = texture
	
	-- So we can access it else where
	row.targets = targets
	row.text = text
	row.manaBar = mana
	row.classTexture = classTexture
	row.petTexture = petTexture
	row.button = button
	row.healthText = healthText

	-- Add key bindings
	local bindKey = GetBindingKey("ARENATAR" .. id)

	if( bindKey ) then
		SetOverrideBindingClick(row.button, false, bindKey, row.button:GetName())	
	else
		ClearOverrideBindings(row.button)
	end
	
	return row
end