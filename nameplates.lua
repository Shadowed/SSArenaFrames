local NP = SSAF:NewModule("NP", "AceEvent-3.0")

local frame = CreateFrame("Frame")
local enemies, nameGUIDMap, isEnabled

function NP:OnEnable()
	enemies = SSAF.enemies
	nameGUIDMap = SSAF.nameGUIDMap
end

function NP:EnableModule()
	isEnabled = true
	frame:Show()
end

function NP:DisableModule()
	isEnabled = false
	frame:Hide()
end

-- TARGET OF TARGET + HEALTH SCANS
-- Health value updated, rescan our saved enemies
local function healthValueChanged(...)
	if( this.SSAFValueChanged ) then
		this.SSAFValueChanged(...)
	end

	if( not isEnabled or not this:IsVisible() ) then
		return
	end	
	
	local name = select(5, this:GetParent():GetRegions()):GetText()	
	if( not nameGUIDMap[name] ) then
		return
	end
	
	local enemy = enemies[nameGUIDMap[name]]
	if( enemy ) then
		enemy.health = this:GetValue()
		enemy.maxHealth = select(2, this:GetMinMaxValues())
	end
end

-- Scan WorldFrame children
local function scanFrames(...)
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		local region = frame:GetRegions()
		if( not frame.SSAFHooked and not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			frame.SSAFHooked = true
			
			local health = frame:GetChildren()
			health.SSAFValueChanged = health:GetScript("OnValueChanged")
			health:SetScript("OnValueChanged", healthValueChanged)
		end
	end
end

local numChildren = -1
frame:SetScript("OnUpdate", function(self, elapsed)
	-- When number of children changes, 99% of the time it's due to a new nameplate being added
	if( WorldFrame:GetNumChildren() ~= numChildren ) then
		numChildren = WorldFrame:GetNumChildren()
		scanFrames(WorldFrame:GetChildren())
	end
end)