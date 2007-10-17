local major = "HousingAuthority-1.2"
local minor = tonumber(string.match("$Revision: 252 $", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))
local HAInstance, oldRevision = LibStub:NewLibrary(major, minor)
if( not HAInstance ) then return end

local L = {
	["BAD_ARGUMENT"] = "bad argument #%d for '%s' (%s expected, got %s)",
	["BAD_ARGUMENT_TABLE"] = "bad widget table argument '%s' for '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from a registered HouseAuthority object.",
	["SLIDER_NOTEXT"] = "You must either set text or format for sliders.",
	["OH_NOT_INITIALIZED"] = "OptionHouse has not been initialized yet, you cannot call HAObj:GetFrame() until then.",
	["INVALID_POSITION"] = "Invalid positioning passed, 'compact' or 'onebyone' required, got '%s'.",
	["INVALID_WIDGETTYPE"] = "Invalid type '%s' passed, %s expected'.",
	["WIDGETS_MISSINGGROUP"] = "When using groups, all widgets must be grouped. %d out of %d are missing a group.",
	["OPTIONHOUSE_REQUIRED"] = "Cannot find OptionHouse-1.1, make sure it loads before HousingAuthority.",
	["NO_CONFIGID"] = "No configuration id found, cannot find the HousingAuthority object.",
}

local OptionHouse = LibStub:GetLibrary("OptionHouse-1.1", true)
if( not OptionHouse ) then error(L["OPTIONHOUSE_REQUIRED"], 3) end

local function assert(level,condition,message)
	if( not condition ) then
		error(message,level)
	end
end

local function argcheck(value, field, ...)
	if( type(field) ~= "number" and type(field) ~= "string" ) then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number, string", type(field)), 1)
	end

	for i=1, select("#", ...) do
		if( type(value) == select(i, ...) ) then return end
	end

	local types = string.join(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	
	if( type(field) == "number" ) then
		error(L["BAD_ARGUMENT"]:format(field, name, types, type(value)), 3)
	else
		error(L["BAD_ARGUMENT_TABLE"]:format(field, name, types, type(value)), 3)
	end
end

-- Widgety fun
-- We only need one tooltip, pointless to make more
local tooltip
local function showInfoTooltip(self)
	if( not tooltip ) then
		tooltip = CreateFrame("GameTooltip", "HAInfoTooltip", nil, "GameTooltipTemplate")
	end

	tooltip:SetOwner(self, "ANCHOR_RIGHT" )
	tooltip:SetText(self.tooltip, nil, nil, nil, nil, 1)
	tooltip:Show()
end

local function hideTooltip(self)
	if( tooltip ) then
		tooltip:Hide()
	end
end

local function positionWidgets(columns, parent, widgets, positionGroup, isGroup)
	local heightUsed = 10
	if( positionGroup or columns > 1 ) then
		heightUsed = 8 + (widgets[1].yPos or 0)
	elseif( isGroup ) then
		heightUsed = 14
	end
	
	if( columns == 1 ) then
		local height = 0
		for i, widget in pairs(widgets) do
			widget:ClearAllPoints()
			
			if( i > 1 ) then
				heightUsed = heightUsed + height + 5 + ( widget.yPos or 0 )
			end

			local xPos = widget.xPos
			if( widget.infoButton and widget.infoButton.type ) then
				xPos = ( xPos or 0 ) + 15
				if( not positionGroup ) then
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -heightUsed)
				else
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -heightUsed)
				end
				
				widget.infoButton:Show()
			end

			widget:SetPoint("TOPLEFT", parent, "TOPLEFT", xPos or 5, -heightUsed)
			widget:Show()
			height = widget:GetHeight() + ( widget.yPos or 0 )
		end
				
		local checkPos = #(widgets)
		if( checkPos == 1 ) then
			heightUsed = 8
		end
		
		local widget = widgets[checkPos]
		if( widget.data and widget.data.type ~= "color" and widget.data.type ~= "check" ) then
			if( widget:GetHeight() >= 35 ) then
				heightUsed = heightUsed + widget:GetHeight()
			else
				heightUsed = heightUsed + (widget.yPos or 0) + 5
			end
		end
	else
		local height = 0
		local spacePerRow = math.ceil(300 / columns)
		local resetOn = -1
		local row = 0
		
		-- If we have an uneven number of widgets
		-- then we need to create an extra row for the last one
		if( mod(#(widgets), columns) == 1 ) then
			resetOn = #(widgets)
		end

		for i, widget in pairs(widgets) do
			if( row == columns or row == resetOn ) then
				heightUsed = heightUsed + height
				height = 0
				row = 0
			end
			
			-- How far away it is from the next row
			local spacing = 0
			if( row > 0 ) then
				spacing = ( spacePerRow * ( row + 1 ) )
			end

			local xPos = widget.xPos or 0
			if( widget.infoButton and widget.infoButton.type ) then
				xPos = ( xPos or 0 ) + 15
				
				if( not positionGroup ) then
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing, -heightUsed)
				else
					widget.infoButton:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing + 6, -heightUsed)
				end
				
				widget.infoButton:Show()
			end
			
			local extraPad = 0
			if( widget.data.type == "slider" and i > columns ) then
				extraPad = 10
			end

			-- Position
			widget:ClearAllPoints()
			widget:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing + xPos, -heightUsed - extraPad)			
			widget:Show()
			
			-- Find the heightest widget out of this group and use that
			local widgetHeight = widget:GetHeight() + ( widget.yPos or 0 ) + 5
			if( widgetHeight > height ) then
				height = widgetHeight
			end
			
			-- Add the extra padding so we don't get overlap
			if( i == resetOn ) then
				heightUsed = heightUsed + ( widget.yPos or 0 )
			end

			row = row + 1
		end
	end
	
	return heightUsed
end

local function setupWidgetInfo(widget, config, type, msg, skipCall)
	-- No button made, no type, exit silently
	if( not widget.infoButton and not type ) then
		return
	
	-- Removing the display
	elseif( widget.infoButton and widget.infoButton.type and not type ) then
		widget.infoButton.type = nil
		widget.infoButton:Hide()
		return
	end
	
	-- Create (Obviously!) the button
	if( not widget.infoButton ) then
		widget.infoButton = CreateFrame("Button", nil, widget)
		widget.infoButton:SetScript("OnEnter", showInfoTooltip)
		widget.infoButton:SetScript("OnLeave", hideTooltip)
		widget.infoButton:SetTextFontObject(GameFontNormalSmall)
		widget.infoButton:SetHeight(18)
		widget.infoButton:SetWidth(18)
	end

	-- Change the message, nothing else needed
	if( widget.infoButton.type == type ) then
		widget.infoButton.tooltip = msg
		return
	end
	
	if( type == "help" ) then
		widget.infoButton:SetPushedTextOffset(0,0)
		widget.infoButton:SetText(GREEN_FONT_COLOR_CODE .. "[?]" .. FONT_COLOR_CODE_CLOSE)
	elseif( type == "validate" ) then
		widget.infoButton:SetText(RED_FONT_COLOR_CODE .. "[!]" .. FONT_COLOR_CODE_CLOSE)
	end

	widget.infoButton.type = type
	widget.infoButton.tooltip = msg
end

-- SET/GET CONFIGURATION VALUES
-- Validates the set/get/onSet/handler/validate
local function validateFunctions(config, data)
	local type = "function"
	if( config.handler or data.handler ) then
		type = "string"
	end
		
	argcheck(data.handler or config.handler, "handler", "table", "nil")
	argcheck(data.set or config.set, "set", type)
	argcheck(data.get or config.get, "get", type)
	argcheck(data.validate, "validate", type, "nil")
	argcheck(data.onSet or config.onSet, "onSet", type, "nil")
end

-- If the set we call errors, the onSet will not be called
-- so don't error damnits
local function setValue(config, data, value)
	local handler = data.handler or config.handler
	local set = data.set or config.set
	local onSet = data.onSet or config.onSet
		
	if( set and handler ) then
		handler[set](handler, data.var, value)
		
	elseif( set ) then
		set(data.var, value)
	end

	if( onSet and handler ) then
		handler[onSet](handler, data.var, value)
	elseif( onSet ) then
		onSet(data.var, value)
	end
end

local function getValue(config, data)
	local handler = data.handler or config.handler
	local get = data.get or config.get
	local val
	
	if( get and handler ) then
		val = handler[get](handler, data.var)
	elseif( get ) then
		val = get(data.var)
	end
	
	if( val == nil and data.default ~= nil ) then
		setValue(config, data, data.default)
		return data.default
	end
	
	return val
end

-- CHECK BOXES
local function checkShown(self)
	self:SetChecked(getValue(self.parent, self.data))
end

local function checkClicked(self)
	if( self:GetChecked() ) then
		setValue(self.parent, self.data, true)
	else
		setValue(self.parent, self.data, false)
	end
end

-- SLIDERS
local sliderBackdrop = {bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
			edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
			edgeSize = 8, tile = true, tileSize = 8,
			insets = { left = 3, right = 3, top = 6, bottom = 6 }}

local function sliderShown(self)
	local value = getValue(self.parent, self.data)
	self:SetValue(value)
	
	if( self.data.format ) then
		self.text:SetText(string.format(self.data.format, value * 100))
	else
		self.text:SetText(self.data.text)
	end
	
	if( self.input ) then
		self.input:Show()
	end
end

local function manualSliderShown(self)
	self.dontSet = true
	self:SetNumber(getValue(self.parent, self.data) * 100)
end

local function updateSliderValue(self)
	if( self.dontSet ) then self.dontSet = nil return end
	
	self:GetParent().dontSet = true
	self:GetParent():SetValue((self:GetNumber()+1) / 100)
end

local function sliderValueChanged(self)
	setValue(self.parent, self.data, self:GetValue())

	if( self.data.format ) then
		self.text:SetText(string.format(self.data.format, self:GetValue() * 100))
	end
	
	if( self.data.manualInput and not self.dontSet ) then
		self.input.dontSet = true	
		self.input:SetNumber(math.floor(self:GetValue() * 100))
	else
		self.dontSet = nil
	end
end

-- INPUT BOX
local function inputShown(self)
	if( not self.data.numeric ) then
		self:SetText(getValue(self.parent, self.data))
	else
		self:SetNumber(getValue(self.parent, self.data))
	end
end

local function inputClearFocus(self)
	self:ClearFocus()
end

local function inputFocusGained(self)
	self:HighlightText()
end

local function inputChanged(self)
	local val
	if( not self.data.numeric ) then
		val = self:GetText()
	else
		val = self:GetNumber()
	end
	
	if( self.data.validate ) then
		local handler = self.parent.handler or self.data.handler
		if( handler ) then
			val = handler[self.data.validate](handler, self.data.var, val)
		else
			val = self.data.validate(self.data.var, val)
		end
		
		-- Validation error, show [!]
		if( not val ) then
			setupWidgetInfo(self, self.parent, "validate", string.format(self.data.error, self:GetText()))
			return
		
		-- Error cleared, no help, hide [!]
		elseif( not self.data.help ) then
			setupWidgetInfo(self, self.parent)
		
		-- Error cleared, help exists, switch [!] to [?]
		elseif( self.infoButton and self.infoButton.type == "validate" ) then
			setupWidgetInfo(self, self.parent, "help", self.data.help)
		end
	end
	
	setValue(self.parent, self.data, val)
end

local function inputClearAndChange(self)
	inputClearFocus(self)
	inputChanged(self)
end

-- COLOR PICKER
local activeButton
local function colorPickerShown(self)
	local value = getValue(self.parent, self.data)
	self:GetNormalTexture():SetVertexColor(value.r, value.g, value.b)
end

local function colorPickerEntered(self)
	self.border:SetVertexColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
end

local function colorPickerLeft(self)
	self.border:SetVertexColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
end

local rgb = { r = 0, g = 0, b = 0 }
local function setColorValue()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	
	rgb.r = r
	rgb.g = g
	rgb.b = b
	
	setValue(activeButton.parent, activeButton.data, rgb)
	activeButton:GetNormalTexture():SetVertexColor(r, g, b)
end

local function cancelColorValue(previous)
	local self = activeButton
	
	setValue(self.parent, self.data, previous)
	self:GetNormalTexture():SetVertexColor(previous.r, previous.g, previous.b)
end

local function resetStrata(self)
	self:SetFrameStrata(self.origStrata)
	self.origStrata = nil
end

local function openColorPicker(self)
	local value = getValue(self.parent, self.data)
	activeButton = self
	
	ColorPickerFrame.previousValues = value
	ColorPickerFrame.func = setColorValue
	ColorPickerFrame.cancelFunc = cancelColorValue
	ColorPickerFrame.origStrata = ColorPickerFrame:GetFrameStrata()
	
	ColorPickerFrame:SetFrameStrata("FULLSCREEN")
	ColorPickerFrame:HookScript("OnHide", resetStrata)
	ColorPickerFrame:SetColorRGB(value.r, value.g, value.b)
	ColorPickerFrame:Show()
end

-- DROPDOWNS
local function dropdownClicked()
	UIDropDownMenu_SetSelectedValue(this.owner, this.value)
	setValue(this.owner.parent, this.owner.data, this.value)
end

local buttonTbl = { func = dropdownClicked }
local function initDropdown(frame)
	if( this:GetName() and string.match(this:GetName(), "Button$") ) then
		frame = getglobal(string.gsub(this:GetName(), "Button$", ""))
	elseif( not frame ) then
		frame = this
	end
	
	buttonTbl.owner = frame
	for _, row in pairs(frame.data.list) do
		buttonTbl.value = row[1]
		buttonTbl.text = row[2]
		buttonTbl.checked = nil
		
		UIDropDownMenu_AddButton(buttonTbl)
	end
end

local function updateDropdown(frame, noInit)
	if( not noInit ) then
		initDropdown(frame)
	end
	
	-- Select da row
	local selected = getValue(frame.parent, frame.data)
	for _, row in pairs(frame.data.list) do
		if( row[1] == selected ) then
			UIDropDownMenu_SetSelectedValue(frame, row[1])
			return
		end
	end
		
	-- No entry found, use first one
	UIDropDownMenu_SetSelectedValue(frame, frame.data.list[1][1])
end

local function dropdownShown(self)
	UIDropDownMenu_Initialize(self, initDropdown)
	
	updateDropdown(self, true)
end

-- GROUP FRAME
local groupBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 5, right = 5, top = 5, bottom = 5 }
}

local function createGroup(config, data)
	local group = CreateFrame("Frame", nil, config.frame)
	group:SetWidth(300)
	group:SetBackdrop(groupBackdrop)
	
	if( data and data.background ) then
		group:SetBackdropColor(data.background.r, data.background.g, data.background.b)
	else
		group:SetBackdropColor(0.094117, 0.094117, 0.094117)	
	end
	
	if( data and data.border ) then
		group:SetBackdropBorderColor(data.border.r, data.border.g, data.border.b)
	else
		group:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end
	
	group:SetFrameStrata("DIALOG")
	group.title = group:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
	group.title:SetPoint("BOTTOMLEFT", group, "TOPLEFT", 9, 0)
	--group.title:SetText(data.text)
	
	return group
end

-- So everything shows up in front of the group
local function updateFrameLevels(...)
	for i=1,select("#", ...) do
		local frame = select(i,...)
		if( frame.SetFrameLevel ) then
			frame:SetFrameLevel(frame:GetParent():GetFrameLevel() + 1)
		end
		
		if( frame.GetChildren ) then
			updateFrameLevels(frame:GetChildren())
		end
	end
end

-- BUTTONS
local function buttonClicked(self)
	local handler = self.data.handler or self.parent.handler
	if( handler ) then
		if( self.data.set ) then
			handler[self.data.set](handler, self.data.var)
		end
		
		if( self.data.onSet ) then
			handler[self.data.onSet](handler, self.data.var)
		end
	else
		if( self.data.set ) then
			self.data.set(self.data.var)
		end
		
		if( self.data.onSet ) then
			self.data.onSet(self.data.var)
		end
	end
end


-- Housing Authority library
local HouseAuthority = {}
local configs = {}
local id = 0

local methods = { "GetFrame", "InjectUIObject", "UpdateDropdown", "CreateConfiguration", "CreateButton", "CreateGroup", "CreateLabel", "CreateDropdown", "CreateColorPicker", "CreateInput", "CreateSlider", "CreateCheckBox" }
local widgetList = {["label"] = "CreateLabel", ["check"] = "CreateCheckBox", ["input"] = "CreateInput", ["dropdown"] = "CreateDropdown", ["color"] = "CreateColorPicker", ["slider"] = "CreateSlider", ["group"] = "CreateGroup", ["button"] = "CreateButton",}

-- Extract the configuration obj from a frame
function HouseAuthority:GetObject(frame)
	argcheck(frame, 1, "table")
	assert(3, frame.configID, L["NO_CONFIGID"])
	
	for id, config in pairs(configs) do
		if( frame.configID == id ) then
			return config.obj
		end
	end
		
	return nil
end

function HouseAuthority:RegisterFrame(data)
	data = data or {}
	
	argcheck(data, 1, "table")
	argcheck(data.columns, "columns", "number", "nil")
	
	if( not data.columns ) then
		data.columns = 1
	end
	
	local type = "function"
	if( data.handler ) then
		type = "string"	
	end
	
	argcheck(data.handler, "handler", "table", "nil")
	argcheck(data.set, "set", type, "nil")
	argcheck(data.get, "get", type, "nil")
	argcheck(data.onSet, "onSet", type, "nil")
	
	if( not data.frame ) then
		data.frame = CreateFrame("Frame", nil, OptionHouse:GetFrame("addon"))	
	end
	
	id = id + 1
	
	local config = { id = id, columns = data.columns, widgets = {}, handler = data.handler, get = data.get, frame = data.frame, set = data.set, onSet = data.onSet }
	config.obj = { id = id }
	
	for _, method in pairs(methods) do
		config.obj[method] = HouseAuthority[method]
	end
		
	configs[id] = config

	return configs[id].obj
end

function HouseAuthority.CreateButton(config, data)
	argcheck(data, 2, "table")
	argcheck(data.var, "var", "string", "number", "table", "nil")
	argcheck(data.template, "template", "string", "nil")
	argcheck(data.width, "width", "number", "nil")
	argcheck(data.text, "text", "string", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateButton"))

	-- Make sure the function stuff passed is good
	local config = configs[config.id]
	local type = "function"
	if( config.handler or data.handler ) then
		type = "string"
	end
		
	argcheck(data.handler or config.handler, "handler", "table", "nil")
	argcheck(data.set, "set", type, "nil")
	argcheck(data.onSet, "onSet", type, "nil")
	
	local button = CreateFrame("Button", nil, config.frame, data.template or "GameMenuButtonTemplate")
	button.parent = config
	button.data = data
	button:SetScript("OnClick", buttonClicked)
	button:SetText(data.text)
	button:SetHeight(18)
	button:SetWidth(button:GetFontString():GetStringWidth() + 18)
	
	table.insert(config.widgets, button)
	return button
end

-- In order to allow even people who call HAObj:CreateGroup manually to use them
-- we have to create all of the groups when GetFrame is called
function HouseAuthority.CreateGroup(config, data)
	argcheck(data, 2, "table")
	argcheck(data.background, "background", "table", "nil")
	argcheck(data.border, "border", "table", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateGroup"))
	
	configs[config.id].groupData = data
end

function HouseAuthority.CreateLabel(config, data)
	argcheck(data, 2, "table")
	argcheck(data.text, "text", "string")
	argcheck(data.color, "color", "table", "nil")
	argcheck(data.fontPath, "fontPath", "string", "nil")
	argcheck(data.fontSize, "fontSize", "number", "nil")
	argcheck(data.fontFlag, "fontFlag", "string", "nil")
	argcheck(data.font, "font", "table", "nil")
	argcheck(data.xPos, "xPos", "number", "nil")
	argcheck(data.yPos, "yPos", "number", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateLabel"))
	
	data.type = "label"
		
	local label = configs[config.id].frame:CreateFontString(nil, "ARTWORK")
	label.parent = config
	label.data = data
	label.xPos = data.xPos or 8
	label.yPos = data.yPos or 5
	
	if( data.font ) then
		label:SetFontObject(data.font)	
	elseif( data.fontPath and data.fontSize ) then
		label:SetFont(data.fontPath, data.fontSize, data.fontFlag)
	else
		label:SetFontObject(GameFontNormal)
	end
	
	if( data.color ) then
		label:SetTextColor(data.color.r, data.color.g, data.color.b)
	end
	
	label:SetText(data.text)
	label:SetHeight(20)
	
	table.insert(configs[config.id].widgets, label)
	return label
end

function HouseAuthority.CreateColorPicker(config, data)
	argcheck(data, 2, "table")
	argcheck(data.text, "text", "string", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "number", "table")
	argcheck(data.default, "default", "table", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateColorPicker"))
	
	validateFunctions(configs[config.id], data)	

	config = configs[config.id]
	
	data.type = "color"
	
	local button = CreateFrame("Button", nil, config.frame)
	button.parent = config
	button.data = data
	button.xPos = 10
	button.yPos = 2
	
	button:SetHeight(18)
	button:SetWidth(18)
	button:SetScript("OnShow", colorPickerShown)
	button:SetScript("OnClick", openColorPicker)
	button:SetScript("OnEnter", colorPickerEntered)
	button:SetScript("OnLeave", colorPickerLeft)
	button:SetNormalTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
	
	button.border = button:CreateTexture(nil, "BACKGROUND")
	button.border:SetHeight(16)
	button.border:SetWidth(16)
	button.border:SetPoint("CENTER", 0, 0)
	button.border:SetTexture(1, 1, 1)
	button:Hide()
	
	if( data.text ) then
		local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", button, "RIGHT", 5, 0)
		text:SetText(data.text)	
	end
	
	if( data.help ) then
		setupWidgetInfo(button, config, "help", data.help)
	end
	
	table.insert(config.widgets, button)
	return button
end

function HouseAuthority.CreateInput(config, data)
	argcheck(data, 2, "table")
	argcheck(data.text, "text", "string", "nil")
	argcheck(data.var, "var", "string", "number", "table")
	argcheck(data.default, "default", "number", "string", "nil")
	argcheck(data.realTime, "realTime", "boolean", "nil")
	argcheck(data.numeric, "numeric", "boolean", "nil")
	argcheck(data.maxChars, "maxChars", "number", "nil")
	argcheck(data.error, "error", "string", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.width, "width", "number", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateInput"))
	
	validateFunctions(configs[config.id], data)	

	config = configs[config.id]
	data.type = "input"
	
	local input = CreateFrame("EditBox", nil, config.frame)
	input.parent = config
	input.data = data
	input.xPos = 15
	
	input:SetScript("OnShow", inputShown)
	input:SetScript("OnEscapePressed", inputClearFocus)
	input:SetScript("OnEditFocusGained", inputFocusGained)
	
	if( data.numeric ) then
		input:SetNumeric(true)
	end
	
	if( data.maxChars ) then
		input:SetMaxLetters(data.maxChars)
	end
	
	if( not data.realTime ) then
		input:SetScript("OnEditFocusLost", inputChanged)
		input:SetScript("OnEnterPressed", inputClearAndChange)
	else
		input:SetScript("OnTextChanged", inputChanged)
		input:SetScript("OnEnterPressed", inputClearFocus)
	end
	
	input:SetAutoFocus(false)
	input:EnableMouse(true)
	
	input:SetHeight(20)
	input:SetWidth(data.width or 120)
	input:SetFontObject(ChatFontNormal)
	input:Hide()
	
	local left = input:CreateTexture(nil, "BACKGROUND")
	left:SetTexture("Interface\\Common\\Common-Input-Border")
	left:SetWidth(8)
	left:SetHeight(20)
	left:SetPoint("LEFT", -5, 0)
	left:SetTexCoord(0, 0.0625, 0, 0.625)
	
	local right = input:CreateTexture(nil, "BACKGROUND")
	right:SetTexture("Interface\\Common\\Common-Input-Border")
	right:SetWidth(8)
	right:SetHeight(20)
	right:SetPoint("RIGHT", 0, 0)
	right:SetTexCoord(0.9375, 1.0, 0, 0.625)
	
	local middle = input:CreateTexture(nil, "BACKGROUND")
	middle:SetTexture("Interface\\Common\\Common-Input-Border")
	middle:SetWidth(10)
	middle:SetHeight(20)
	middle:SetPoint("LEFT", left, "RIGHT")
	middle:SetPoint("RIGHT", right, "LEFT")
	middle:SetTexCoord(0.0625, 0.9375, 0, 0.625)
	
	if( data.text ) then
		local text = input:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", input, "RIGHT", 5, 0)
		text:SetText(data.text)
	end

	if( data.help ) then
		setupWidgetInfo(input, config, "help", data.help)
	end

	table.insert(config.widgets, input)
	return input
end

function HouseAuthority.CreateSlider(config, data)
	argcheck(data, 2, "table")
	argcheck(data.default, "default", "number", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "number", "table")
	argcheck(data.text, "text", "string", "nil")
	argcheck(data.format, "format", "string", "nil")
	argcheck(data.min, "min", "number", "nil")
	argcheck(data.minText, "minText", "string", "nil")
	argcheck(data.max, "max", "number", "nil")
	argcheck(data.maxText, "minText", "string", "nil")
	argcheck(data.step, "step", "number", "nil")
	argcheck(data.manualInput, "manualInput", "boolean", "nil")
	assert(3, ( data.text or data.format ), L["SLIDER_NOTEXT"])
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateSlider"))
	
	validateFunctions(configs[config.id], data)	
	
	config = configs[config.id]
	
	data.type = "slider"
	
	local slider = CreateFrame("Slider", nil, config.frame)
	slider.parent = config
	slider.data = data
	slider.xPos = 10
	slider.yPos = 10

	slider:SetScript("OnShow", sliderShown)
	slider:SetScript("OnValueChanged", sliderValueChanged)
	slider:SetWidth(128)
	slider:SetHeight(17)
	slider:SetMinMaxValues(data.min or 0.0, data.max or 1.0)
	slider:SetValueStep(data.step or 0.01)	
	slider:SetOrientation("HORIZONTAL")
	slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	slider:SetBackdrop(sliderBackdrop)
	slider:Hide()
	
	slider.text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	slider.text:SetPoint("BOTTOM", slider, "TOP", 0, 0)
	
	if( not data.text and not data.format ) then
		slider.text:Hide()
	end
	
	local min = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	min:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 2, 3)
	
	if( not data.minText ) then
		min:SetText((data.min or 0.0) * 100 .. "%")
	else
		min:SetText(data.minText)
	end
	
	local max = slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	max:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -2, 3)		
	
	if( not data.maxText ) then
		max:SetText((data.max or 1.0) * 100 .. "%" )
	else
		max:SetText(data.maxText)
	end
	
	if( data.manualInput ) then
		slider.input = HouseAuthority.CreateInput(config, { width = 35, maxChars = string.len((data.max or 1.0) * 100), var = data.var, set = data.set, onSet = data.onSet, get = data.get, handler = data.handler, numeric = true, realTime = true })
		slider.input:SetScript("OnShow", manualSliderShown)
		slider.input:SetScript("OnTextChanged", updateSliderValue)
		slider.input:SetPoint("LEFT", slider, "RIGHT", 15, -2)
		slider.input:SetParent(slider)
		slider.input.xPos = nil
		
		table.remove(config.widgets, #(config.widgets))
	end
	
	if( data.help ) then
		setupWidgetInfo(slider, config, "help", data.help)
	end

	table.insert(config.widgets, slider)
	return slider
end

function HouseAuthority.CreateCheckBox(config, data)
	argcheck(data, 2, "table")
	argcheck(data.default, "default", "boolean", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "number", "table")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateCheckBox"))
	
	validateFunctions(configs[config.id], data)

	config = configs[config.id]
	
	data.type = "check"

	local check = CreateFrame("CheckButton", nil, config.frame)
	check.parent = config
	check.data = data
	check.xPos = 5
	
	check:SetScript("OnShow", checkShown)
	check:SetScript("OnClick", checkClicked)
	check:SetWidth(26)
	check:SetHeight(26)
	check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
	check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:Hide()
	
	if( data.text ) then
		local text = check:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", check, "RIGHT", 5, 0)
		text:SetText(data.text)
	end
	
	if( data.help ) then
		setupWidgetInfo(check, config, "help", data.help)
	end

	table.insert(config.widgets, check)
	return check
end

function HouseAuthority.UpdateDropdown(config, data)
	argcheck(data, 2, "table")
	argcheck(data.list, "list", "table")
	argcheck(data.var, "var", "string", "number", "table")
	argcheck(data.default, "default", "string", "number", "nil")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "UpdateDropdown"))
	
	config = configs[config.id]
	
	for _, widget in pairs(config.widgets) do
		if( widget.data.type == "dropdown" and type(data.var) == type(widget.data.var) ) then
			if( type(data.var) == "table" ) then
				local matches = 0
				local rows = 0

				for k, v in pairs(data.var) do
					if( widget.data.var[k] == v ) then
						matches = matches + 1
					end
					
					rows = rows + 1
				end
			
				-- Everything matches?
				if( matches >= rows ) then
					widget.data.list = data.list
					widget.data.default = widget.data.default or data.default
					updateDropdown(widget)
					break
				end
				
			elseif( data.var == widget.data.var ) then
				widget.data.list = data.list
				widget.data.default = widget.data.default or data.default

				updateDropdown(widget)
				break
			end
		end
	end
end

function HouseAuthority.CreateDropdown(config, data)
	argcheck(data, 2, "table")
	argcheck(data.list, "list", "table")
	argcheck(data.text, "text", "string", "nil")
	argcheck(data.default, "default", "string", "number", "nil")
	argcheck(data.help, "help", "string", "nil")
	argcheck(data.var, "var", "string", "number", "table")
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	
	validateFunctions(configs[config.id], data)
	
	config = configs[config.id]
	config.dropNum = ( config.dropNum or 0 ) + 1
	
	data.type = "dropdown"

	local button = CreateFrame("Frame", "HADropdownID" .. config.id .. "Num" .. config.dropNum, config.frame, "UIDropDownMenuTemplate")
	button.parent = config
	button.data = data
	button.xPos = -10
	button:SetScript("OnShow", dropdownShown)
	button:Hide()
	
	if( data.text ) then
		local text = button:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		text:SetPoint("LEFT", "HADropdownID" .. config.id .. "Num" .. config.dropNum .. "Button", "RIGHT", 10, 0)
		text:SetText(data.text)
	end
	
	if( data.help ) then
		setupWidgetInfo(button, config, "help", data.help)
	end

	table.insert(config.widgets, button)
	return button
end

-- Lets you inject a custom UI object so you can use HA along side
-- some custom configuration widgets
function HouseAuthority.InjectUIObject(config, UIObj, data)
	argcheck(UIObj, 2, "table")
	argcheck(data, 3, "table")
	argcheck(data.xPos, "xPos", "number", "nil")
	argcheck(data.yPos, "yPos", "number", "nil")
	argcheck(data.group, "group", "string", "nil");
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "CreateDropdown"))
	
	config = configs[config.id]
	
	data.type = "inject"
	
	UIObj.parent = config
	UIObj.data = data
	UIObj.xPos = data.xPos
	UIObj.yPos = data.yPos
	UIObj:Hide()
	
	table.insert(config.widgets, UIObj)
end

function HouseAuthority.GetFrame(config)
	assert(3, config and configs[config.id], string.format(L["MUST_CALL"], "GetFrame"))
	assert(3, OptionHouse:GetFrame("addon"), L["OH_NOT_INITIALIZED"])
	
	local config = configs[config.id]
	
	-- If no new widgets have been added, then return the current one
	if( config.totalWidgets and config.totalWidgets == #(config.widgets) ) then
		return config.scroll or config.frame
	end
	
	-- Now figure out how many groups we have/need
	if( not config.groupFrames ) then
		config.groupFrames = {}
	end
	
	config.groups = {}
		
	local totalGroups = 0
	local groupedWidgets = 0

	for _, widget in pairs(config.widgets) do
		-- Yup it's a group
		if( widget.data.group ) then
			if( not config.groups[widget.data.group] ) then
				config.groups[widget.data.group] = {}
				totalGroups = totalGroups + 1
			end
			
			table.insert(config.groups[widget.data.group], widget)
			groupedWidgets = groupedWidgets + 1
		end
		
		-- Need to account for the fact that the height is for the bar itself
		-- not bar + top and below text
		if( config.columns > 1 and widget.data.type == "slider" ) then
			widget.yPos = widget.yPos + 5
		end
	end
	
	-- Grouping is "disabled" so postion it directly to the frame
	local totalHeight = 0
	if( totalGroups == 0 ) then
		totalHeight = positionWidgets(config.columns, config.frame, config.widgets)
	else
		assert(3, groupedWidgets == #(config.widgets), string.format(L["WIDGETS_MISSINGGROUP"], groupedWidgets, #(config.widgets)))
		
		-- Create all the groups, then position the objects to the widget
		local frames = {}
		local num = 0
		for text, widgets in pairs(config.groups) do
			-- Check if we have an old frame to grab from
			num = num + 1
			if( config.groupFrames[num] ) then
				frame = config.groupFrames[num]
			else
				frame = createGroup(config, config.groupData)
			end
			
			-- Reparent/framelevel/position/blah the widgets
			for i, widget in pairs(widgets) do
				widget:SetParent(frame)
				widget.xPos = ( widget.xPos or 0 ) + 5
				
				updateFrameLevels(widget, frame)
			end

			-- Now reposition them
			local height = positionWidgets(config.columns, frame, widgets, true)
			
			-- Give some frame info
			frame.yPos = 5
			frame.title:SetText(text)
			frame:SetWidth(600)
			frame:SetHeight(height + 30)
			table.insert(frames, frame)
			
			totalHeight = totalHeight + height + 35
		end
		
		-- Now position all of the groups
		positionWidgets(1, config.frame, frames, nil, true)
	end
	
	-- Do we even need a scroll frame, and does it not exist yet?
	if( totalHeight >= 250 and not config.scroll ) then
		local scroll = CreateFrame("ScrollFrame", "HAScroll" .. config.id, OptionHouse:GetFrame("addon"), "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", OptionHouse:GetFrame("addon"), "TOPLEFT", 190, -105)
		scroll:SetPoint("BOTTOMRIGHT", OptionHouse:GetFrame("addon"), "BOTTOMRIGHT", -35, 40)

		config.frame:SetParent(scroll)
		config.frame:SetWidth(10)
		config.frame:SetHeight(10)
		
		scroll:SetScrollChild(config.frame)
		config.scroll = scroll
		config.scroll.configID = config.id
	end	
	
	config.totalWidgets = #(config.widgets)
	config.frame.configID = config.id
	return config.scroll or config.frame
end

function HouseAuthority:CreateConfiguration(data, frameData)
	argcheck(data, 1, "table")
	argcheck(frameData, 2, "table", "nil")
	
	local handler = HouseAuthority:RegisterFrame(frameData)
	for id, widget in pairs(data) do
		if( widget.type == "inject" ) then
			handler["InjectUIObject"](handler, widget.widget, widget)
		elseif( widget.type and widgetList[widget.type] ) then
			handler[widgetList[widget.type]](handler, widget)
		else
			error(string.format(L["INVALID_WIDGETTYPE"], widget.type or "nil", "inject, label, check, input, dropdown, color, slider, group, button"), 3)
		end
	end
	
	return handler.GetFrame(handler)
end

function HouseAuthority:GetVersion() return major, minor end

local function checkVersion()
	if( oldRevision ) then
		id = HAInstance.id or id
		configs = HAInstance.configs or configs
	end

	for id, config in pairs(configs) do
		for _, method in pairs(methods) do
			configs[id].obj[method] = HouseAuthority[method]
		end
	end
	
	HouseAuthority.id = id
	HouseAuthority.configs = configs
	
	for k, v in pairs(HouseAuthority) do
		HAInstance[k] = v
	end
end

checkVersion()